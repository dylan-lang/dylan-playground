<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Dylan Playground</title>
  </head>

  <%dsp:taglib name="playground"/>

  <body>

    <h2>Enter some Dylan code to run:</h2>

    <form action="/build"
          method="post"
          enctype="application/x-www-form-urlencoded">
      <textarea name="code" value="" rows="50" cols="100"><playground:code/></textarea>
      <p/>
      <input name="submit" value="submit" type="submit"/>
      <p/>
      <h3>Compiler output:</h3>
      <textarea name="output" value="" rows="20" cols="100"><playground:output/></textarea>
    </form>

  </body>
</html>
