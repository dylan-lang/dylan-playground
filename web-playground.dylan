Module: web-playground
Synopsis: Web app backing play.opendylan.org

/*
TODO

* Prevent maliciousness or accidents like `while (#t) format-out("blah") end`
  and `while (#t) end`.

* Permalinks for sharing examples.

* The TODOs in the code below are the more urgent ones. These are longer term
  reminders.

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

*/

// Directory in which to run dylan-compiler, i.e. where the shared _build
// directory and the project subdirectories live.  Plan is to use "dev" for
// development use.
//
// TODO: make this a command line flag
define constant $workdir = as(<directory-locator>, "/home/cgay/dylan/workspaces/playground/dev");

// Make #:string:|...| syntax work.
define function string-parser (s) => (s) s end;

define class <playground-page> (<dylan-server-page>)
end;

define constant $playground-page = make(<playground-page>, source: "playground.dsp");

define constant $default-code = #:string:|
// Edit this code, then hit Run!

format-out("Hello, %s!\n", direct-subclasses(<object>));

|;

define constant $library-code-attr = "library-code";
define constant $main-code-attr = "main-code";
define constant $warnings-attr = "warnings";
define constant $exe-output-attr = "exe-output";
define constant $debug-output-attr = "debug-output";

define taglib playground ()
  tag main-code (page :: <playground-page>) ()
    output("%s", get-query-value($main-code-attr) | $default-code);
  tag library-code (page :: <playground-page>) ()
    begin
      let text = get-query-value($library-code-attr);
      if (~text)
        text := format-to-string($library-file-template, "play", "play");
      end;
      output("%s", text);
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
    block ()
      let project-name = generate-project-name();
      let (warnings, exe-output) = build-and-run-code(project-name, main-code);
      log-debug("warnings = %=", warnings);
      log-debug("exe-output = %=", exe-output);
      set-attribute(ctx, $warnings-attr, warnings);
      set-attribute(ctx, $exe-output-attr, exe-output);
    exception (ex :: <error>)
      set-attribute(ctx, $warnings-attr, format-to-string("Error: %s", ex));
    end;
  else
    set-attribute(ctx, $warnings-attr, "Please enter some code above.");
  end;
  process-template(page);
end;

define function generate-project-name () => (project-name :: <string>)
  // Good enough for now...
  concatenate("play-", current-request().request-client-address.md5.hexdigest)
end function;

define function build-and-run-code
    (project-name :: <string>, main-code :: <string>)
 => (warnings :: <string>, exe-output :: <string>)
  let project-dir = ensure-project-directory(project-name);
  let lid-path = generate-project-files(project-name, project-dir, main-code);
  let (exe-path, warnings) = build-project(project-name, project-dir, lid-path);
  if (exe-path)
    values(warnings, run-executable($workdir, exe-path))
  else
    values(warnings, "No executable was created")
  end
end function;

define function run-executable
    (workdir :: <directory-locator>, exe-path :: <file-locator>) => (output :: <string>)
  let exe-output
    = with-output-to-string (stream)
        os/run-application(as(<string>, exe-path),
                           working-directory: workdir,
                           input: #"null",
                           outputter: method (output :: <byte-string>, #key end: _end :: <integer>)
                                        log-debug("program output: %s", copy-sequence(output, end: _end));
                                        write(stream, output, end: _end);
                                      end);
      end;
  if (exe-output = "")
    "(no output)"
  else
    exe-output
  end
end function;

define function ensure-project-directory
    (project-name :: <string>) => (pathname :: <directory-locator>)
  let project-dir = subdirectory-locator($workdir, project-name);
  fs/ensure-directories-exist(project-dir);
  project-dir
end function;

define function generate-project-files
    (project-name :: <string>, workdir :: <directory-locator>, main-code :: <string>)
 => (lid :: <file-locator>)
  let (lid-path, lib-path, code-path) = project-locators(project-name, workdir);
  fs/with-open-file (stream = lib-path, direction: #"output", if-exists: #"truncate")
    format(stream, $library-file-template, project-name, project-name);
  end;
  fs/with-open-file (stream = code-path,  direction: #"output", if-exists: #"truncate")
    format(stream, $code-file-template, project-name, main-code);
  end;
  fs/with-open-file (stream = lid-path,  direction: #"output", if-exists: #"truncate")
    format(stream, $lid-file-template, project-name, project-name);
  end;
  lid-path
end function;

define function project-locators
    (project-name :: <string>, workdir :: <directory-locator>)
  values(merge-locators(as(<file-locator>, "play.lid"), workdir),
         merge-locators(as(<file-locator>, "play-library.dylan"), workdir),
         merge-locators(as(<file-locator>, "play.dylan"), workdir))
end function;

define constant $lid-file-template
  = "library: %s\nexecutable: %s\nfiles: library\n       code\n";

define constant $library-file-template = #:string:|Module: dylan-user

// If a library has no 'import:' clause here it imports a module with the same
// name as the library.
define library %s
  use common-dylan;
  use io, import: { format-out };
  use system, import: { date };
end library;

define module %s
  use common-dylan;             // from common-dylan library
  use date;                     // from system library
  use format-out;               // from io library
end module;
|;

define constant $code-file-template = "module: %s\n\n%s\n";

define function build-project
    (project-name :: <string>, project-dir :: <directory-locator>, lid-path :: <file-locator>)
 => (exe :: false-or(<file-locator>), warnings :: <string>)
  let command = format-to-string("dylan-compiler -build %s", lid-path);
  let builder-output
    = with-output-to-string (stream)
        os/run-application(command,
                           working-directory: $workdir,
                           input: #"null",
                           outputter: method (output :: <byte-string>, #key end: _end :: <integer>)
                                        log-debug("compiler output: %s", copy-sequence(output, end: _end));
                                        write(stream, output, end: _end);
                                      end);
      end;
  let exe-path = merge-locators(as(<file-locator>,
                                   format-to-string("_build/bin/%s", project-name)),
                                $workdir);
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
      "(This warning can be avoided"];

define function sanitize-build-output (output :: <string>) => (sanitized :: <string>)
  local method keep-line? (line)
          // Wouldn't mind having an option to dylan-compiler to turn off most
          // of the output other than "building library foo" and warnings.
          ~any?(starts-with?(line, _), $blacklist-prefixes)
        end;
  let lines = choose(keep-line?, split(output, "\n"));
  // Remove all warnings from the dylan library.
  // (Not technically necessary given the plan to install precompiled core libs.)
  let trimmed = make(<stretchy-vector>);
  let keep? = #t;
  for (line in lines)
    if (starts-with?(line, "/"))
      keep? := ~find-substring(line, "/sources/dylan/");
    end;
    if (keep?)
      add!(trimmed, line);
    end;
  end;
  join(trimmed, "\n")
end function;

define function main ()
  let server = make(<http-server>);
  add-resource(server, "/play", $playground-page);
  http-server-main(server: server);
end function;

main();
