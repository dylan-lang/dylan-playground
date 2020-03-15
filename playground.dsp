<!DOCTYPE html>
<html lang="en">
  <head>
    <%dsp:taglib name="playground"/>

    <title>Dylan Playground</title>

    <style>
      body {
          font: Ariel, Helvetica, sans-serif;
      }
      .editor-row {
          display: flex;
      }
      .editor-row > div {
          background-color: #f1f1f1;
          padding: 20px;
      }
      .examples-and-docs {
          display: flex;
          flex-direction: column;
          justify-content: center;
      }
      .examples-and-docs > div {
          padding-bottom: 40px;
      }
    </style>
  </head>

  <body>

    <header>
      <h2>Dylan Playground (a work in progress!)</h2>
    </header>

    <div id="module-definition">
      Your code is compiled using the following library/module definition:
      <code>
        <pre><playground:library-code/></pre>
      </code>
    </div>
    <button id="module-button" onClick="toggleShowModule()">Hide module definition</button>
    <script>
      function toggleShowModule() {
          var mod = document.getElementById("module-definition");
          var but = document.getElementById("module-button");
          if (mod.style.display === "none") {
              mod.style.display = "block";
              but.textContent = "Hide module definition";
          } else {
              mod.style.display = "none";
              but.textContent = "Show module definition";
          }
      }
    </script>

    <form action="/"
          method="post"
          enctype="application/x-www-form-urlencoded">

      <div class="editor-row">
        <div>
          <textarea autofocus
                    style="background-color: #f5e8c4"
                    name="main-code"
                    value=""
                    rows="20"
                    cols="90"><playground:main-code/></textarea>
        </div>
        <div class="examples-and-docs">
          <div>
            <label for="examples-menu">Choose an example:</label><br>
            <select id="examples-menu">
              <playground:examples-menu/>
            </select>
          </div>
          <div style="display: flex; flex-direction: column; padding-bottom: 10px">
            <div>Need help?</div>
            <a href="https://opendylan.org/documentation/#cheat-sheets" target="_blank">Cheat Sheets</a>
            <a href="https://opendylan.org/documentation/library-reference" target="_blank">Library Docs</a>
            <a href="https://opendylan.org/books/drm/Contents" target="_blank">Language Reference</a>
          </div>
        </div>
      </div>
      <br>
      <input name="run" value="Run" type="submit"/>
    </form>

    <p/>

    <pre><playground:warnings/></pre>
    <hr>
    <pre><playground:exe-output/></pre>
    <hr>
    <pre><playground:debug-output/></pre>

  </body>
</html>
