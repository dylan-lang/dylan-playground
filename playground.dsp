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
      /* The entire page is contained in the main column. */
      .main-column {
          display: flex;
          flex-direction: column;
          padding-left: 20px;
          padding-right: 20px;
      }
      /* The top row contains the title and most of the buttons. */
      .top-row {
          display: flex;
          flex-direction: row;
          margin: 0px 0px 10px 0px;
      }
      .examples-box {
          font-size: large;
          padding: 1px 10px;
          margin: 5px;
      }
      .editor {
          display: block;
          flex-grow: 8;
          padding-right: 20px;
      }
      .links-row {
          display: flex;
          flex-direction: row;
          font-size: small;
      }
      a {
          padding: 1px 30px 1px 1px;
      }
      textarea {
          font-family: monospace;
          font-size: 100%; /* not sure why this is necessary */
          width: 100%;
      }
      button {
          background-color: lightskyblue;
          border-radius: 4px;
          border-width: 0;
          font-size: large;
          padding: 1px 10px;
          margin: 5px;
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
          document.getElementById("compiler-output").innerText = "";
          document.getElementById("exe-output").innerText = "";

          var main_code = document.getElementById("main-code");
          var fdata = new FormData();
          fdata.append("main-code", main_code.value);
          var request = new XMLHttpRequest();
          request.addEventListener("load", function (event) {
              var table = JSON.parse(event.target.responseText);
              if (table["compiler-output"]) {
                  var w = document.getElementById("compiler-output");
                  w.innerText = table["compiler-output"];
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
      function shareCode() {
          var main_code = document.getElementById("main-code");
          var fdata = new FormData();
          fdata.append("main-code", main_code.value);
          var request = new XMLHttpRequest();
          request.addEventListener("load", function (event) {
              alert(event.target.responseText);
              var table = JSON.parse(event.target.responseText);
              if (table["URL"]) {
                  alert(table["URL"]); // temp
              }
          });
          request.addEventListener("error", function (event) {
              alert(event);
          });
          request.open("POST", "/share", true);
          request.send(fdata);
      }
    </script>
  </head>

  <body>

    <div class="main-column">
      <div class="top-row">
        <span style="font-size: large; margin: 5px;">Dylan Playground</span>
        <div>
          <button id="module-button" onClick="toggleShowModule()">Show Imports</button>
        </div>
        <div>
          <button id="share-button" onClick="shareCode()">Share</button>
        </div>
        <div class="examples-box">
          <select id="examples-menu" onchange="selectExample()">
            <playground:examples-menu/>
          </select>
        </div>
        <div>
          <button id="run-button" onClick="buildAndRunCode()">Run &gt;&gt;</button>
        </div>
      </div> <!-- top-row -->

      <div id="module-definition" style="display: none">
        Your code is compiled in this module. (In the future the module will be editable.)
        <code>
          <pre><playground:library-code/></pre>
        </code>
      </div>

      <div class="editor">
        <textarea autofocus id="main-code" rows="20"><playground:main-code/></textarea>
      </div>
      <div class="links-row">
        <a href="https://opendylan.org/documentation/#cheat-sheets" target="_blank">Cheat Sheets</a>
        <a href="https://opendylan.org/documentation/library-reference" target="_blank">Library Docs</a>
        <a href="https://opendylan.org/books/drm/Contents" target="_blank">Language Reference</a>
        <a href="https://github.com/cgay/web-playground/issues" target="_blank">Report a bug</a>
      </div> <!-- links-row -->

    </div> <!-- main-column -->
    <p/>

    <pre id="compiler-output"></pre>
    <hr>
    <pre id="exe-output"></pre>

  </body>
</html>
