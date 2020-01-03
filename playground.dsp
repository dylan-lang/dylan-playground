<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Dylan Playground</title>
  </head>
  <%dsp:taglib name="playground"/>
  <body>
    <dsp:show-query-values/>
    <h2>Enter some Dylan code:</h2>
    <form action="/play"
          method="post"
          enctype="application/x-www-form-urlencoded">
      <textarea name="dylan-code" value="" rows="20" cols="100"><playground:dylan-code/></textarea>
      <p/>
      <input name="submit" value="submit" type="submit"/>
      <p/>
      <h3>Compiler output:</h3>
      <textarea name="output" value="" rows="20" cols="100"><playground:compiler-output/></textarea>
    </form>
  </body>
</html>
