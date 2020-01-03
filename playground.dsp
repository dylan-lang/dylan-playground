<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Dylan Playground</title>
  </head>
  <%dsp:taglib name="playground"/>
  <body>
    <h2>Enter some Dylan code:</h2>
    <form action="/play"
          method="post"
          enctype="application/x-www-form-urlencoded">
      <textarea name="dylan-code" value="" rows="20" cols="100"><playground:dylan-code/></textarea>
      <p/>
      <input name="submit" value="submit" type="submit"/>
    </form>
    <p/>
    <h3>Build output:</h3>
    <pre><playground:build-output/></pre>
    <h3>Debug output:</h3>
    <dsp:show-query-values/>
  </body>
</html>
