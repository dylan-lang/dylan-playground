Module: web-playground
Synopsis: Web app backing play.opendylan.org

define class <playground-page> (<dylan-server-page>)
end;

define constant $playground-page = make(<playground-page>, source: "playground.dsp");

define taglib playground ()
  tag dylan-code (page :: <playground-page>) ()
    output("%s", get-query-value("dylan-code") | "");
  tag compiler-output (page :: <playground-page>) ()
    output("%s", get-attribute(page-context() | "", "compiler-output"));
end;

define method respond-to-post (page :: <playground-page>, #key) => ()
  // Seems like text/html should be the default...
  set-header(current-response(), "Content-Type", "text/html");
  let dylan-code = get-query-value("dylan-code");
  let compiler-output
    = if (dylan-code & dylan-code ~= "")
        build-code(dylan-code)
      else
        "Please enter some code above."
      end;
  set-attribute(page-context(), "compiler-output", compiler-output);
  process-template(page);
end;

define function build-code (dylan-code :: <string>) => (output :: <string>)
  concatenate("WARNING: unbound variable ", dylan-code)
end;

define function main ()
  let server = make(<http-server>);
  add-resource(server, "/play", $playground-page);
  http-server-main(server: server);
end function;

main();
