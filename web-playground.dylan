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

// Make #:string:|...| syntax work.
define function string-parser (s) => (s) s end;

define class <playground-page> (<dylan-server-page>)
end;

define constant $default-code = #:string:|
// Edit this code, then hit Run!

format-out("Hello, %s!\n", "World");

|;

//define constant $library-code-attr = "library-code";
define constant $main-code-attr = "main-code";
define constant $warnings-attr = "warnings";
define constant $exe-output-attr = "exe-output";
define constant $debug-output-attr = "debug-output";

define taglib playground ()
  tag main-code (page :: <playground-page>) ()
    output("%s", get-query-value($main-code-attr) | $default-code);
  tag library-code (page :: <playground-page>) ()
    begin
      let name = generate-project-name();
      output($library-file-template, name, name);
    end;
  tag warnings (page :: <playground-page>) ()
    quote-html(get-attribute(page-context(), $warnings-attr) | "",
               stream: current-response());
  tag exe-output (page :: <playground-page>) ()
    quote-html(get-attribute(page-context(), $exe-output-attr) | "",
               stream: current-response());
  tag debug-output (page :: <playground-page>) ()
    quote-html(get-attribute(page-context(), $debug-output-attr) | "",
               stream: current-response());
end;

define method respond-to-post (page :: <playground-page>, #key) => ()
  // Seems like text/html should be the default...
  set-header(current-response(), "Content-Type", "text/html");
  let main-code = get-query-value($main-code-attr);
  let ctx = page-context();
  if (main-code & main-code ~= "")
    log-debug("program code: %s", main-code);
    block ()
      let project-name = generate-project-name();
      let (warnings, exe-output) = build-and-run-code(project-name, main-code);
      log-debug("warnings = %=", warnings);
      log-debug("exe-output = %s", exe-output);
      set-attribute(ctx, $warnings-attr, warnings);
      set-attribute(ctx, $exe-output-attr, exe-output);
    exception (ex :: <error>)
      set-attribute(ctx, $debug-output-attr, format-to-string("Error: %s", ex));
    end;
  else
    set-attribute(ctx, $warnings-attr, "Please enter some code above.");
  end;
  process-template(page);
end;

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
  use common-dylan, import: { common-dylan };
  use io,           import: { format-out };
  use system,       import: { date };
end library;

define module %s
  use common-dylan;
  use date;
  use format-out;
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
  let builder-output
    = with-output-to-string (stream)
        os/run-application(command,
                           working-directory: *play-root-dir*,
                           input: #"null",
                           outputter: method (output :: <byte-string>, #key end: _end :: <integer>)
                                        log-debug("compiler output: %s",
                                                  strip-right(copy-sequence(output, end: _end)));
                                        write(stream, output, end: _end);
                                      end);
      end;
  let exe-path = merge-locators(as(<file-locator>,
                                   format-to-string("./_build/bin/%s", project-name)),
                                *play-root-dir*);
  let warnings = sanitize-build-output(builder-output);
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

define function main ()
  local method before-startup (server :: <http-server>)
          let source = merge-locators(as(<file-locator>, "playground.dsp"),
                                      *template-directory*);
          log-debug("source = %s", source);
          let page = make(<playground-page>, source: source);
          add-resource(server, "/", page);
        end;
  http-server-main(server: make(<http-server>), before-startup: before-startup);
end function;

main();
