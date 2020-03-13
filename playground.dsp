<!DOCTYPE html>
<html lang="en">
  <title>Dylan Playground</title>

  <%dsp:taglib name="playground"/>

  <body>

    <h2>Dylan Playground (a work in progress!)</h2>

    <a href="https://opendylan.org/documentation/#cheat-sheets" target="_blank">Dylan Cheat Sheets</a>
    &mdash;
    <a href="https://opendylan.org/documentation/library-reference" target="_blank">Library Documentation</a>
    &mdash;
    <a href="https://opendylan.org/books/drm/Index">Language Reference</a>
    <p>
    <form action="/"
          method="post"
          enctype="application/x-www-form-urlencoded">
      <p>
      <code>
        // Code is compiled using the following library/module definition.
        <pre><playground:library-code/></pre>
      </code>
      <code>
        <textarea autofocus name="main-code" value="" rows="20" cols="90"><playground:main-code/></textarea>
      </code>
      <br>
      <input name="run" value="Run" type="submit"/>
    </form>

    <p>

    <pre><playground:warnings/></pre>
    <hr>
    <pre><playground:exe-output/></pre>
    <hr>
    <pre><playground:debug-output/></pre>

  </body>
</html>
