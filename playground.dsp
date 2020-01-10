<!DOCTYPE html>
<html lang="en">
  <title>Dylan Playground</title>

  <%dsp:taglib name="playground"/>

  <body>

    <h2>Dylan Playground</h2>

    Notes:
    <ul>
      <li>This playground is still a work in progress!
      <li>See the <a href="https://opendylan.org/books/drm/Contents" target="_blank">Dylan
      Reference Manual</a> for documentation of core language features.
      <li>See the <a href="https://opendylan.org/documentation/library-reference"
        target="_blank">Dylan Library Reference</a> for documentation on specific
        libraries.
    </ul>

    <form action="/play"
          method="post"
          enctype="application/x-www-form-urlencoded">
      <code>
        <textarea autofocus name="dylan-code" value="" rows="20" cols="100"><playground:dylan-code/></textarea>
      </code>
      <p/>
      <input name="run" value="Run" type="submit"/>
    </form>
    <p/>
    <h3>Program output</h3>

    <pre><playground:exe-output/></pre>

    <h3>Compiler output</h3>
    <pre><playground:warnings/></pre>

    <h3>Debug output</h3>
    <pre><playground:debug-output/></pre>

  </body>
</html>
