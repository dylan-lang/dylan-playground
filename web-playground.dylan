Module: web-playground
Synopsis: Web app backing play.opendylan.org


define function main ()
  let server = make(<http-server>);
  add-resource(server, "/playground", $playground-page);
  http-server-main(server: server);
end function;


define taglib playground ()
  tag code (page :: <playground-page>) ()
    output(get-query-value("code"));
  tag output (page :: <playground-page>) ()
    output(get-query-value("output"));
end;  


define class <playground-page> (<dylan-server-page>)
end;

define constant $playground-page = make(<playground-page>, source: "playground.dsp");


define method respond (page :: <playground-page>, #key)
  // Seems like text/html should be the default...
  set-header(current-response(), "Content-Type", "text/html");
  let dylan-code = get-query-value("code");
  let output = if (dylan-code)
                 build-code(dylan-code)
               else
                 "No code found."
               end;
  process-template(page);
end;

define function build-code (code :: <string>) => (output :: <string>)
  "WARNING: this is a compiler warning"
end;

main();
