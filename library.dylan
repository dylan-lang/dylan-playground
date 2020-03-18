Module: dylan-user

define library web-playground
  use common-dylan;
  use dsp;
  use hash-algorithms;
  use http-common;
  use http-server;
  use io,
    import: { format, format-out, streams };
  use strings;
  use system,
    import: { date, file-system, locators, operating-system };
  use xml-parser;
  use uuid;
end library;

define module web-playground
  use common-dylan;
  use date,
    import: { <day/time-duration>, current-date, decode-duration };
  use dsp;
  use file-system,
    prefix: "fs/";
  use format,
    import: { format, format-to-string };
  use format-out;
  use hash-algorithms,
    import: { hexdigest, md5 };
  use http-common,
    import: { get-attribute, quote-html, set-attribute, set-header };
  use http-server,
    import: { <http-server>,
              <resource>,
              add-resource,
              current-request,
              current-response,
              get-attr,
              get-query-value,
              get-session,
              http-server-main,
              log-debug,
              output,
              page-context,
              process-config-element,
              quote-html,
              respond-to-get,
              respond-to-post,
              server-root };
  use locators,
    import: { <directory-locator>,
              <file-locator>,
              merge-locators,
              simplify-locator,
              subdirectory-locator };
  use operating-system,
    prefix: "os/";
  use simple-profiling,         // from common-dylan
    import: { timing };
  use streams,
    import: { <stream>, read-to-end, with-output-to-string, write };
  use strings,
    import: { decimal-digit?,
              ends-with?,
              find-substring,
              starts-with?,
              strip,
              strip-right,
              whitespace? };
  use xml-parser,
    rename: { <element> => xml/<element> };
  use uuid,
    import: { make-uuid4 };
end module;
