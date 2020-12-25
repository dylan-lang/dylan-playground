Module: web-playground
Synopsis: Sharing playground examples

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
  let main-code = get-attribute(page-context(), $main-code-attr)
                    | get-query-value($main-code-attr);
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

// Generate a key to use to find a playground share. The key is used in the
// share URL, for example.
define function generate-share-key (text :: <string>) => (key :: <string>)
  as-lowercase(copy-sequence(hexdigest(sha1(text)), end: 16))
end function;

// Find the share data associated with the given key.
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

