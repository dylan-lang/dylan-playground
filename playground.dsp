<!DOCTYPE html>
<html lang="en">
  <title>Dylan Playground</title>

  <%dsp:taglib name="playground"/>

  <body>

    <h2>Dylan Playground</h2>

    Notes:
    <ul>
      <li>This playground is still a work in progress!
      <li>There is currently no way to define your own library or modules; you
        can assume the definitions in these libraries are available:
        <a href="https://opendylan.org/documentation/library-reference/common-dylan/index.html">common-dylan</a>,
        <a href="https://opendylan.org/documentation/library-reference/io/index.html">io</a>,
        <a href="https://opendylan.org/documentation/library-reference/system/index.html">system</a>,
        <a href="https://opendylan.org/documentation/library-reference/collections/index.html">collections</a>,
      <li>The first build may be slow (minutes) as it builds everything down to
          the dylan library. Subsequent builds are much faster since they don't
          need to build the dylan, system, and io libraries.
      <li>For now, if you want to see any output you must explicitly print
          result values. For example, instead of just <code>1 + 2</code> write
          <code>format-out("%=\n", 1 + 2);</code>
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

    <h3>Compiler warnings</h3>
    <pre><playground:warnings/></pre>

    <h3>Debug output</h3>
    <pre><playground:debug-output/></pre>

  </body>
</html>
