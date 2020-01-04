<!DOCTYPE html>
<html lang="en">
  <title>Dylan Playground</title>

  <%dsp:taglib name="playground"/>

  <body>

    <h2>Dylan Playground</h2>

    Notes:
    <ul>
      <li>This playground is still a work in progress!
      <li>There is no way to define your own library or modules; your code
          should assume the modules in these libraries are available:<br/>
            <code>    common-dylan, io, system, collections</code>
      <li>The first build may be slow (minutes); subsequent builds should
          be much faster.
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
    <h3>Project output</h3>
    <pre><playground:exe-output/></pre>

    <h3>Build output</h3>
    <pre><playground:build-output/></pre>

    <h3>Debug output</h3>
    <dsp:show-query-values/>
  </body>
</html>
