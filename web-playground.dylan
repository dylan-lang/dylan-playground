Module: web-playground
Synopsis: Web app backing play.opendylan.org

/*
TODO

* The TODOs in the code below are the more urgent ones. These are longer term
  reminders.

* Don't run the previously built exe if the current build fails. 

* Prevent maliciousness or accidents like `while (#t) format-out("blah") end`
  and `while (#t) end`.

* Permalinks for sharing examples.

* Provide a bunch of code examples to select from and then modify.

* Allow the user to create their own library and module definition rather than
  using the canned ones. Probably just search for "define library" and "define
  module" and omit the canned ones if present. Need to ensure they don't use
  file-system, network, operating-system. Others?

* For now I compile all code in the same _build directory. Is this safe if
  multiple compilations are running at the same time? At least I think the file
  sets are disjoint as long as none of the used libraries need to be
  recompiled.  Could instead copy a _build dir that has core libs precompiled.

* Optionally show DFM and/or assembly output.

* Make it pretty.

*/

// Root of the playground. Directory where user project subdirectories live and
// directory in which to run dylan-compiler, i.e. where the shared _build
// directory lives.
define variable *play-root-dir* :: false-or(<directory-locator>) = #f;

define variable *template-directory* :: false-or(<directory-locator>) = #f;

define variable *dylan-compiler-location* :: false-or(<file-locator>) = #f;

define sideways method process-config-element
    (server :: <http-server>, node :: xml/<element>, name == #"dylan-web-playground")
  let playdir = merge-locators(as(<directory-locator>,
                                  get-attr(node, #"root-directory") | server.server-root),
                               server.server-root);

  // TODO: simplify-locator doesn't do what I expected, i.e., remove ../
  *play-root-dir* := simplify-locator(playdir);
  log-debug("root-directory is %s", *play-root-dir*);

  let template-directory = get-attr(node, #"template-directory");
  *template-directory*
    := simplify-locator(if (template-directory)
                          merge-locators(as(<directory-locator>, template-directory),
                                         *play-root-dir*)
                        else
                          *play-root-dir*
                        end);
  log-debug("template-directory is %s", *template-directory*);

  let dylan-compiler = get-attr(node, #"dylan-compiler");
  let $DYLAN = os/environment-variable("DYLAN");
  let dc = if (dylan-compiler)
             as(<file-locator>, dylan-compiler)
           elseif ($DYLAN)
             merge-locators(as(<file-locator>, "opendylan/bin/dylan-compiler"),
                            as(<directory-locator>, $DYLAN))
           else
             error("no Dylan compiler configured and $DYLAN not set");
           end;
  *dylan-compiler-location* := simplify-locator(dc);
  if (~fs/file-exists?(*dylan-compiler-location*))
    error("Dylan compiler binary doesn't exist: %s",
          as(<string>, *dylan-compiler-location*));
  end;
  log-debug("dylan-compiler is %s", *dylan-compiler-location*);
end method;

define class <playground-page> (<dylan-server-page>)
end;

define constant $main-code-attr = "main-code";
define constant $warnings-attr = "warnings";
define constant $exe-output-attr = "exe-output";
define constant $debug-output-attr = "debug-output";

define taglib playground ()
  // TODO: do this via onload() in js
  tag main-code (page :: <playground-page>) ()
    output("%s", get-query-value($main-code-attr) | find-example-code($hello-world));
  tag library-code (page :: <playground-page>) ()
    begin
      let name = generate-project-name();
      output($library-file-template, name, name);
    end;
  tag examples-menu (page :: <playground-page>) ()
    for (v in $examples)
      let name = v[0];
      output("<option value=\"%s\">%s</option>\n", name, name);
    end;
  tag example (page :: <playground-page>) (name :: <string> = $hello-world)
    output(find-example-code(name) | "example not found");
end;

define class <build-and-run> (<resource>) end;

define method respond-to-post (resource :: <build-and-run>, #key) => ()
  set-header(current-response(), "Content-Type", "application/json");

  // debug
  do-query-values(method (key, val)
                    log-debug("key = %s, val = %s", key, val);
                  end);

  let result = make(<string-table>);
  let main-code = get-query-value($main-code-attr);
  log-debug("bbb main-code = %=", main-code);
  log-debug("bbb request-content = %=", request-content(current-request()));
  if (main-code & main-code ~= "")
    log-debug("program code: %s", main-code);
    block ()
      let project-name = generate-project-name();
      let (warnings, exe-output) = build-and-run-code(project-name, main-code);
      log-debug("warnings = %=", warnings);
      log-debug("exe-output = %s", exe-output);
      result[$warnings-attr] := warnings;
      result[$exe-output-attr] := exe-output;
    exception (ex :: <error>)
      result[$debug-output-attr] := format-to-string("Error: %s", ex);
    end;
  else
    result[$warnings-attr] := "Please enter some code.";
  end;
  encode-json(current-response(), result);
end method;

define function generate-project-name () => (project-name :: <string>)
  concatenate("play-", short-session-id())
end function;

define function short-session-id () => (id :: <string>)
  let key = "dylan-web-playground-id";
  let session = get-session(current-request());
  get-attribute(session, key)
    | begin
        let id = as(<string>, make-uuid4());
        let id = copy-sequence(id, start: id.size - 12);
        set-attribute(session, key, id);
        id
      end
end function;

define function build-and-run-code
    (project-name :: <string>, main-code :: <string>)
 => (warnings :: <string>, exe-output :: <string>)
  let project-dir = ensure-project-directory(project-name);
  let lid-path = generate-project-files(project-name, project-dir, main-code);
  let (exe-path, warnings) = build-project(project-name, project-dir, lid-path);
  if (exe-path)
    values(warnings, run-executable(*play-root-dir*, exe-path))
  else
    values(warnings, "No executable was created")
  end
end function;

define constant $max-output-chars :: <integer> = 10000;
define constant $max-memory-kbytes :: <integer> = 100000;
define constant $max-cpu-time-seconds :: <integer> = 1;

define function run-executable
    (playdir :: <directory-locator>, exe-path :: <file-locator>) => (output :: <string>)
  let output-bytes = 0;
  // ulimit -t doesn't seem to have any effect. Maybe just detach the process,
  // keep a timer and send SIGTERM instead.
  let command
    = format-to-string("/bin/sh -c 'ulimit -S -v %d && ulimit -S -c 0 && ulimit -S -t %d && exec %s'",
                       $max-memory-kbytes,
                       $max-cpu-time-seconds,
                       as(<string>, exe-path));
  log-debug("command = %s", command);
  let exe-output
    = with-output-to-string (stream)
        block (return)
          os/run-application(command,
                             working-directory: playdir,
                             input: #"null",
                             outputter: method (output :: <byte-string>, #key end: _end :: <integer>)
                                          write(stream, output, end: _end);
                                          output-bytes := output-bytes + _end;
                                          if (output-bytes > $max-output-chars)
                                            write(stream, "\n***execution terminated: too much output***\n");
                                            return();
                                          end;
                                        end);
        end block;
      end;
  if (exe-output = "")
    "(no output)"
  else
    exe-output
  end
end function;

define function ensure-project-directory
    (project-name :: <string>) => (pathname :: <directory-locator>)
  let project-dir = subdirectory-locator(*play-root-dir*, project-name);
  fs/ensure-directories-exist(project-dir);
  project-dir
end function;

define function generate-project-files
    (project-name :: <string>, playdir :: <directory-locator>, main-code :: <string>)
 => (lid :: <file-locator>)
  // playdir has the unique project name in it so the base file names can
  // always be the same..
  let lib-file = "library.dylan";
  let code-file = "main.dylan";
  // Except that apparently the _build/build/ subdirectory that gets created
  // uses the name of the LID file. I think this is an OD bug.
  let lid-path = merge-locators(as(<file-locator>, concatenate(project-name, ".lid")), playdir);
  let code-path = merge-locators(as(<file-locator>, code-file), playdir);
  let lib-path = merge-locators(as(<file-locator>, lib-file), playdir);
  fs/with-open-file (stream = lib-path, direction: #"output", if-exists: #"truncate")
    format(stream, $library-file-template, project-name, project-name);
  end;
  fs/with-open-file (stream = code-path,  direction: #"output", if-exists: #"truncate")
    format(stream, $code-file-template, project-name, main-code);
  end;
  fs/with-open-file (stream = lid-path,  direction: #"output", if-exists: #"truncate")
    format(stream, $lid-file-template, project-name, project-name, lib-file, code-file);
  end;
  lid-path
end function;

define constant $lid-file-template
  = "library: %s\nexecutable: %s\nfiles: %s\n       %s\n";

define constant $library-file-template = #:string:|Module: dylan-user

define library %s
  use common-dylan, import: { byte-vector, common-dylan, simple-random };
  use io, import: { format, format-out, streams };
  use strings;
  use system;
end library;

define module %s
  use byte-vector;  use common-dylan;  use simple-random;
  use date;
  use format;  use format-out;  use streams;
  use strings;
end module;
|;

define constant $code-file-template = "module: %s\n\n%s\n";


// TODO: generate assembly code with this command
//   clang-7 -O2 -fexceptions -S -o whatever.s _build/build/play/main.bc
// Add -emit-llvm to get LLVM generic assembly code rather than platform specific.
// The dylan-compiler -assemble flag only works for HARP.
define function build-project
    (project-name :: <string>, project-dir :: <directory-locator>, lid-path :: <file-locator>)
 => (exe :: false-or(<file-locator>), warnings :: <string>)
  let command = format-to-string("%s -build -dfm %s",
                                 as(<string>, *dylan-compiler-location*), lid-path);
  let timing-info = "";
  let build-output
    = with-output-to-string (stream)
        local method outputter (output :: <byte-string>, #key end: _end :: <integer>)
                log-debug("compiler output: %s",
                          strip-right(copy-sequence(output, end: _end)));
                write(stream, output, end: _end);
              end;
        let (sec, usec)
          = timing ()
              os/run-application(command,
                                 working-directory: *play-root-dir*,
                                 input: #"null",
                                 outputter: outputter);
            end;
        timing-info := format-to-string("in %d.%s seconds", sec, integer-to-string(usec, size: 6));
      end;
  let exe-path = merge-locators(as(<file-locator>,
                                   format-to-string("./_build/bin/%s", project-name)),
                                *play-root-dir*);
  let warnings = concatenate(sanitize-build-output(build-output), "\n", timing-info);
  if (fs/file-exists?(exe-path))
    values(exe-path, warnings)
  else
    values(#f, warnings)
  end
end function;

// Don't show compiler output lines with these prefixes.  Seemed safer than a
// whitelist.
define constant $blacklist-prefixes
  = #["Opened project",
      "Loading namespace",
      "Updating definitions",
      "Computing data models",
      "Computing code models",
      "Performing type analysis",
      "Optimizing",
      "Generating code",
      "Linking object files",
      "Saving database",
      "Checking bindings",
      "Linking",
      "Warning - Definition of {<c-statically-typed-function-pointer>",
      "(This warning can be avoided",
      "Building targets"];

// Remove blank lines, $blacklist-prefixes, and entire warnings that are in the
// dylan library.
define function sanitize-build-output (output :: <string>) => (sanitized :: <string>)
/* Example warning:
/.../sources/dylan/collection.dylan:346.1-349.31: Warning - blah blah
      ---------------------------------------------------
 346  define copy-down-method map-as-one (type == <list>,
 347                                      function :: <function>,
 348                                      collection ::  <explicit-key-collection>) =>
 349    (new-collection :: <vector>);
      ------------------------------
*/
  let keep = make(<stretchy-vector>);
  let in-dylan-warning? = #f;   // from leading slash until not leading space
  for (full-line in split(output, "\n"))
    let line = strip(full-line);
    if (in-dylan-warning?)
      if (empty?(line) | ~whitespace?(full-line[0]))
        in-dylan-warning? := #f;
      end;
    elseif (starts-with?(line, "/") & find-substring(line, "/sources/dylan/"))
      in-dylan-warning? := #t;
    elseif (~empty?(line) & ~any?(starts-with?(line, _), $blacklist-prefixes))
      add!(keep, line);
    end;
  end for;
  join(keep, "\n")
end function;

// A resource for retrieving individual examples.
define class <example-resource> (<resource>) end;

define method respond-to-get (page :: <example-resource>, #key name) => ()
  let stream = current-response();
  set-header(stream, "Content-type", "text/plain");
  if (name)
    let code = find-example-code(name);
    if (code)
      write(stream, code);
    else
      format(stream, "example %= not found", name);
    end;
  else
    write(stream, "name parameter not found");
  end;
end method;

define function main ()
  local method before-startup (server :: <http-server>)
          let source = merge-locators(as(<file-locator>, "playground.dsp"),
                                      *template-directory*);
          add-resource(server, "/",               make(<playground-page>, source: source));
          add-resource(server, "/example/{name}", make(<example-resource>));
          add-resource(server, "/run",            make(<build-and-run>));
        end;
  http-server-main(server: make(<http-server>),
                   before-startup: before-startup);
end function;

main();
