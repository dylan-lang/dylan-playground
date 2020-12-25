Module: dylan-playground

begin
  http-server-main(server: make(<http-server>),
                   before-startup: register-resources);
end;
