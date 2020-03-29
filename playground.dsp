<!DOCTYPE html>
<html lang="en">
  <head>
    <%dsp:taglib name="playground"/>
    <link rel="shortcut icon" href="/static/favicon.ico"/>

    <title>Dylan Playground</title>

    <style>
      body {
          font-family: Ariel, Helvetica, sans-serif;
          background-color: #f7f1dc;
      }
      .top-column {
          display: flex;
          flex-direction: column;
          padding-left: 20px;
          padding-right: 20px;
      }
      .editor {
          display: block;
          flex-grow: 8;
          padding-right: 20px;
      }
      textarea {
          font-family: monospace;
          font-size: 100%; /* not sure why this is necessary */
          width: 100%;
      }
      .editor-row {
          display: flex;
          flex-direction: row;
      }
      .examples-column {
          display: flex;
          flex-direction: column;
          justify-content: center;
          flex-grow: 2;
      }
      .examples-column > div {
          padding-bottom: 40px;
      }
      button#run-button {
          background-color: #4caf50;
          border-radius: 4px;
          font-size: large;
          padding: 8px 16px;
      }
      button#module-button {
          background-color: #4caf50;
          border-radius: 4px;
          margin-bottom: 4px;
          padding: 4px 8px;
      }
    </style>
    <script>
      function toggleShowModule() {
          var mod = document.getElementById("module-definition");
          var but = document.getElementById("module-button");
          if (mod.style.display === "none") {
              mod.style.display = "block";
              but.textContent = "Hide Imports";
          } else {
              mod.style.display = "none";
              but.textContent = "Show Imports";
          }
      }
      function selectExample() {
          var example = document.getElementById("examples-menu").value;
          var request = new XMLHttpRequest();
          request.addEventListener("load", function(event) {
              var main_code = document.getElementById("main-code");
              main_code.value = event.target.responseText;
          });
          request.open("GET", "/example/" + example, true);
          request.send();
      }
      function buildAndRunCode() {
          document.getElementById("warnings").innerText = "";
          document.getElementById("exe-output").innerText = "";

          var main_code = document.getElementById("main-code");
          var fdata = new FormData();
          fdata.append("main-code", main_code.value);
          var request = new XMLHttpRequest();
          request.addEventListener("load", function (event) {
              var table = JSON.parse(event.target.responseText);
              if (table["warnings"]) {
                  var w = document.getElementById("warnings");
                  w.innerText = table["warnings"];
              }
              if (table["exe-output"]) {
                  var out = document.getElementById("exe-output");
                  out.innerText = table["exe-output"];
              }
          });
          request.addEventListener("error", function (event) {
              alert(event);
          });
          request.open("POST", "/run", true);
          request.send(fdata);
      }
    </script>
  </head>

  <body>

    <header>
      <center><h2>Dylan Playground</h2></center>
    </header>

    <div class="top-column">
      <div>
        <button id="module-button" onClick="toggleShowModule()">Show Imports</button>
      </div>
      <div id="module-definition" style="display: none">
        Your code is compiled in this module. (In the future the module will be editable.)
        <code>
          <pre><playground:library-code/></pre>
        </code>
      </div>
      <div class="editor-row">
        <div class="editor">
          <textarea autofocus id="main-code" rows="20"><playground:main-code/></textarea>
        </div>
        <div class="examples-column">
          <div>
            <button id="run-button" onClick="buildAndRunCode()">Run &gt;&gt;</button>
          </div>
          <div>
            <label for="examples-menu">Choose an example</label>
            <select id="examples-menu" onchange="selectExample()">
              <playground:examples-menu/>
            </select>
          </div>
          <div style="display: flex; flex-direction: column; padding-bottom: 10px;">
            <div>Need help?</div>
            <a href="https://opendylan.org/documentation/#cheat-sheets" target="_blank">Cheat Sheets</a>
            <a href="https://opendylan.org/documentation/library-reference" target="_blank">Library Docs</a>
            <a href="https://opendylan.org/books/drm/Contents" target="_blank">Language Reference</a>
          </div>
          <div style="padding-top: 20px; font-size: small;">
            <a href="https://github.com/cgay/web-playground/issues" target="_blank">Report a bug</a>
          </div>
        </div> <!-- examples-column -->
      </div> <!-- editor-row -->
    </div> <!-- top-column -->
    <p/>

    <pre id="warnings"></pre>
    <hr>
    <pre id="exe-output"></pre>

  </body>
</html>
