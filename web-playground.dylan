Module: web-playground
Synopsis: Web app backing play.opendylan.org

// Bug list: https://github.com/cgay/web-playground/issues

// Root of the playground. Directory where user project subdirectories live and
// directory in which to run dylan-compiler, i.e. where the shared _build
// directory lives.
define variable *play-root-dir* :: false-or(<directory-locator>) = #f;

define variable *template-directory* :: false-or(<directory-locator>) = #f;

define variable *dylan-compiler-location* :: false-or(<file-locator>) = #f;

define variable *shares-directory* :: false-or(<directory-locator>) = #f;

define variable *base-url* :: <string> = "https://play.opendylan.org/";

// HTTP server calls this when loading the config.
define sideways method process-config-element
    (server :: <http-server>, node :: xml/<element>, name == #"dylan-web-playground")
  let playdir = merge-locators(as(<directory-locator>,
                                  get-attr(node, #"root-directory") | server.server-root),
                               server.server-root);
  *play-root-dir* := resolve-locator(playdir);
  log-debug("root-directory is %s", *play-root-dir*);

  local
    method process-dir-attr (attr-name, default-subdir-name)
      let path = get-attr(node, attr-name);
      let dir =
        simplify-locator(if (path)
                           merge-locators(as(<directory-locator>, path), *play-root-dir*)
                         elseif (default-subdir-name)
                           subdirectory-locator(*play-root-dir*, default-subdir-name)
                         else
                           *play-root-dir*
                         end);
      log-debug("%s is %s", attr-name, dir);
      dir
    end method;

  *template-directory* := process-dir-attr(#"template-directory", #f);
  *shares-directory* := process-dir-attr(#"shares-directory", "shares");
  fs/ensure-directories-exist(*shares-directory*);

  let base-url = get-attr(node, #"base-url");
  if (base-url)
    *base-url* := base-url;
  end;
  log-debug("base-url is %s", *base-url*);

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
  *dylan-compiler-location* := resolve-locator(dc);
  if (~fs/file-exists?(*dylan-compiler-location*))
    error("Dylan compiler binary doesn't exist: %s",
          as(<string>, *dylan-compiler-location*));
  end;
  log-debug("dylan-compiler is %s", *dylan-compiler-location*);
end method;

define class <playground-page> (<dylan-server-page>)
end;

define variable *playground-page* :: false-or(<playground-page>) = #f;

define constant $main-code-attr = "main-code";
define constant $compiler-output-attr = "compiler-output";
define constant $exe-output-attr = "exe-output";
define constant $debug-output-attr = "debug-output";

define taglib playground ()
  // TODO: do this via onload() in js
  tag main-code (page :: <playground-page>) ()
    begin
      output("%s",
             get-attribute(page-context(), $main-code-attr)
               | get-query-value($main-code-attr)
               | find-example-code($hello-world));
    end;
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
      let (compiler-output, exe-output) = build-and-run-code(project-name, main-code);
      log-debug("compiler-output = %=", compiler-output);
      log-debug("exe-output = %s", exe-output);
      result[$compiler-output-attr] := compiler-output;
      result[$exe-output-attr] := exe-output;
    exception (ex :: <error>)
      result[$debug-output-attr] := format-to-string("Error: %s", ex);
    end;
  else
    result[$compiler-output-attr] := "Please enter some code.";
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
 => (compiler-output :: <string>, exe-output :: <string>)
  let project-dir = ensure-project-directory(project-name);
  let lid-path = generate-project-files(project-name, project-dir, main-code);
  let (exe-path, compiler-output) = build-project(project-name, project-dir, lid-path);
  if (exe-path)
    values(compiler-output, run-executable(*play-root-dir*, exe-path))
  else
    values(compiler-output, "No executable was created")
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
  use common-dylan,
    import: {
      byte-vector, common-dylan, simple-random, simple-timers,
      simple-profiling, transcendentals
    };
  use hash-algorithms;
  use io,
    import: { format, format-out, print, pprint, streams };
  use logging;
  use regular-expressions;
  use strings;
  use system, import: { date, locators };
end library;

define module %s
  // from common-dylan
  use byte-vector;
  use common-dylan;
  use simple-random;
  use simple-timers;
  use simple-profiling;
  use transcendentals;
  // from system
  use date;
  // from io
  use format;
  use format-out;
  use print;
  use pprint;
  use streams;
  // from libraries with only one exported module
  use hash-algorithms;
  use logging;
  use regular-expressions;
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
 => (exe :: false-or(<file-locator>), compiler-output :: <string>)
  // NOTE: If -dfm is added to this command it dies outputting DFM for the
  // regular-expressions library, so either that has to be fixed or
  // regular-expressions needs to be removed from $library-file-template.
  let command = format-to-string("%s -build %s",
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
  let compiler-output = concatenate(sanitize-build-output(build-output), "\n", timing-info);
  if (fs/file-exists?(exe-path))
    values(exe-path, compiler-output)
  else
    values(#f, compiler-output)
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
// dylan library. Also elide parts of pathnames.
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
      add!(keep, full-line);
    end;
  end for;
  let dir-prefix = as(<string>, *play-root-dir*);
  join(map(method (line)
             replace-substrings(line, dir-prefix, "...")
           end,
           keep),
       "\n")
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

define class <create-share> (<resource>) end;
define class <lookup-share> (<resource>) end;

define constant $shared-playground-error-message =
  #:string:"
// This Dylan Playground URL is not associated with any saved code.
// It is possible the URL was copied incorrectly, or that it is too
// old and the code has been deleted.";

define method respond-to-get (resource :: <lookup-share>, #key key) => ()
  let code = (key & find-share(key)) | $shared-playground-error-message;
  set-attribute(page-context(), $main-code-attr, code);
  set-header(current-response(), "Content-type", "text/html");
  respond-to-get(*playground-page*);
end method;

define method respond-to-post (resource :: <create-share>, #key) => ()
  // Main code is either in the page context (see <shared-resource>) or in the
  // POST data.
  let main-code =
    get-attribute(page-context(), $main-code-attr) | get-query-value($main-code-attr);
  let result = make(<string-table>);
  if (main-code & strip(main-code) ~= "")
    let key = generate-share-key(main-code);
    find-share(key) | save-share(key, main-code);
    let url = url-for-share-key(key);
    result["URL"] := url;
  else
    result["error"] := "nothing to share!";
  end;
  encode-json(current-response(), result);
end method;

define function generate-share-key (text :: <string>) => (key :: <string>)
  as-lowercase(copy-sequence(hexdigest(sha1(text)), end: 16))
end function;

define function find-share (key :: <string>) => (text :: false-or(<string>))
  block ()
    fs/with-open-file (stream = locator-for-share-key(key),
                       direction: #"input",
                       // https://github.com/dylan-lang/opendylan/issues/1358
                       if-does-not-exist: #f)
      read-to-end(stream);
    end
  exception (<error>)
    #f
  end
end function;

// TODO: potential race between multiple server threads. Even though keys
// are based on the input code, people might try to share canned examples.
define function save-share (key :: <string>, text :: <string>) => ()
  let locator = locator-for-share-key(key);
  fs/ensure-directories-exist(locator);
  fs/with-open-file (stream = locator,
                    direction: #"output",
                    if-does-not-exist: #"create")
    write(stream, text);
  end;
end function;

define function url-for-share-key (key :: <string>) => (url :: <string>)
  concatenate(*base-url*, "shared/", key)
end function;

define function locator-for-share-key (key :: <string>) => (locator :: <file-locator>)
  merge-locators(as(<file-locator>, key),
                 subdirectory-locator(*shares-directory*, copy-sequence(key, end: 2)))
end function;

define function main ()
  local method before-startup (server :: <http-server>)
          let source = merge-locators(as(<file-locator>, "playground.dsp"),
                                      *template-directory*);
          *playground-page* := make(<playground-page>, source: source);

          add-resource(server, "/",               *playground-page*);
          add-resource(server, "/example/{name}", make(<example-resource>));
          add-resource(server, "/run",            make(<build-and-run>));
          add-resource(server, "/share",          make(<create-share>));
          add-resource(server, "/shared/{key}",   make(<lookup-share>));
          add-resource(server, "/static",
                       make(<directory-resource>,
                            directory: subdirectory-locator(*play-root-dir*, "static")));
          // temp, for testing server connection closing problem
          add-resource(server, "/error",
                       make(<function-resource>,
                            function: method (#rest args)
                                        error("my dog has fleas")
                                      end,
                            methods: list($http-get-method)));
        end;
  http-server-main(server: make(<http-server>),
                   before-startup: before-startup);
end function;

main();
