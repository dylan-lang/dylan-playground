<!DOCTYPE html>
<html lang="en">
  <head>
    <%dsp:taglib name="playground"/>

    <title>Dylan Playground</title>

    <style>
      body {
          font-family: Ariel, Helvetica, sans-serif;
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
              } else {
                  alert("no warnings");
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
      <h2>Dylan Playground (a work in progress!)</h2>
    </header>

    <div class="button-row">
      <button id="module-button" onClick="toggleShowModule()">Hide module definition</button>
      <button id="run-button" onClick="buildAndRunCode()">Run</button>
    </div>
    <div id="module-definition">
      Your code is compiled using the following library/module definition:
      <code>
        <pre><playground:library-code/></pre>
      </code>
    </div>

    <div class="editor-row">
      <div>
        <!-- TODO: Why is the font tiny if I omit font-size: 100% here? Seems
             to inherit from "system-ui". -->
        <textarea autofocus
                  id="main-code"
                  style="font-family: monospace; font-size: 100%; background-color: #f5e8c4;"
                  value=""
                  rows="25"
                  cols="90"><playground:main-code/></textarea>
      </div>
      <div class="examples-and-docs">
        <div>
          <label for="examples-menu">Choose an example</label><br>
          <select id="examples-menu"
                  onchange="selectExample()">
            <playground:examples-menu/>
          </select>
        </div>
        <div style="display: flex; flex-direction: column; padding-bottom: 10px;">
          <div>Need help?</div>
          <a href="https://opendylan.org/documentation/#cheat-sheets" target="_blank">Cheat Sheets</a>
          <a href="https://opendylan.org/documentation/library-reference" target="_blank">Library Docs</a>
          <a href="https://opendylan.org/books/drm/Contents" target="_blank">Language Reference</a>
        </div>
        <div style="padding-top: 20px;">
          <a href="https://github.com/cgay/web-playground/issues">Report a bug</a>
        </div>
      </div>
    </div>

    <p/>

    <pre id="warnings"></pre>
    <hr>
    <pre id="exe-output"></pre>

  </body>
</html>
