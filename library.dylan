Module: dylan-user

define library web-playground
  use common-dylan;
  use dsp;
  use http-common;
  use http-server;
  use io,
    import: { format,
              streams };
  use strings;
  use system,
    import: { file-system,
              locators,
              operating-system };
end library;

define module web-playground
  use common-dylan;
  use dsp;
  use file-system,
    prefix: "fs/";
  use format,
    import: { format,
              format-to-string };
  use http-common,
    import: { get-attribute,
              quote-html,
              set-attribute,
              set-header };
  use http-server;
  use locators,
    import: { <directory-locator>,
              <file-locator>,
              merge-locators };
  use operating-system,
    prefix: "os/";
  use streams,
    import: { <stream>,
              read-to-end,
              with-output-to-string,
              write };
  use strings,
    import: { starts-with? };
end module;
