<!DOCTYPE html>
<html lang="en">
  <title>Dylan Playground</title>

  <%dsp:taglib name="playground"/>

  <body>

    <h2>Dylan Playground</h2>

    <ul>
      <li>This playground is still a work in progress!
      <li>See some <a href="https://opendylan.org/documentation/#cheat-sheets"
      target="_blank">Dylan Cheat Sheets</a>
      and <a href="https://opendylan.org/documentation/library-reference"
      target="_blank">library documentation</a>.
    </ul>

    <form action="/"
          method="post"
          enctype="application/x-www-form-urlencoded">
      <b>Your code uses the following library/module definition. </b>(In the future you
      will be able to define your own.)
      <p>
      <code>
        <pre><playground:library-code/></pre>
      </code>
      <code>
        <textarea autofocus name="main-code" value="" rows="20" cols="100"><playground:main-code/></textarea>
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
