// Log WebAssembly Messages from Zig to JavaScript Console
// https://github.com/daneelsan/zig-wasm-logger/blob/master/script.js
const text_decoder = new TextDecoder();
let console_log_buffer = "";
let term = null;

// WebAssembly Helper Functions
const wasm = {
  // WebAssembly Instance
  instance: undefined,

  // Init the WebAssembly Instance
  init: function (obj) {
    this.instance = obj.instance;
  },

  // Fetch the Zig String from a WebAssembly Pointer
  getString: function (ptr, len) {
    const memory = this.instance.exports.memory;
    return text_decoder.decode(
      new Uint8Array(memory.buffer, ptr, len)
    );
  },
};

// Export JavaScript Functions to Zig
const importObject = {
  // JavaScript Functions exported to Zig
  env: {
    // Write to JavaScript Console from Zig
    // https://github.com/daneelsan/zig-wasm-logger/blob/master/script.js
    jsConsoleLogWrite: function(ptr, len) {
      console_log_buffer += wasm.getString(ptr, len);
    },

    // Flush JavaScript Console from Zig
    // https://github.com/daneelsan/zig-wasm-logger/blob/master/script.js
    jsConsoleLogFlush: function() {
      // Print to the Terminal
      term.write(console_log_buffer.split("\n").join("\r\n") + "\r\n");

      // Print to the JavaScript Console
      console.log(console_log_buffer);
      console_log_buffer = "";
    },
  }
};

// Main Function
function main() {
  console.log("main: start");

  // Allocate a String for passing the code to Zig
  const code = document.getElementById("code").value;
  const code_ptr = allocateString(code);

  // Call TCC to compile a program
  const ptr = wasm.instance.exports
    .compile_program(code_ptr);
  console.log(`main: ptr=${ptr}`);

  // Get the `a.out` size from first 4 bytes returned
  const memory = wasm.instance.exports.memory;
  const data_len = new Uint8Array(memory.buffer, ptr, 4);
  const len = data_len[0] | data_len[1] << 8 | data_len[2] << 16 | data_len[3] << 24;
  console.log(`main: len=${len}`);

  // Encode the `a.out` data from the rest of the bytes returned
  const data = new Uint8Array(memory.buffer, ptr, len + 4);
  let encoded_data = "";
  for (const i in data) {
    if (i < 4) { continue; }  // Skip the first 4 bytes
    const hex = Number(data[i]).toString(16).padStart(2, "0");
    encoded_data += `%${hex}`;
  }

  // Download the `a.out` data into the Web Browser
  console.log(encoded_data);
  download("a.out", encoded_data);

  console.log("main: end");
};

// Allocate a String for passing to Zig
// https://blog.battlefy.com/zig-made-it-easy-to-pass-strings-back-and-forth-with-webassembly
const allocateString = (string) => {
  // WebAssembly Memory exported by Zig
  const memory = wasm.instance.exports.memory;
  const buffer = new TextEncoder().encode(string);

  // Ask Zig to allocate memory
  const pointer = wasm.instance.exports
    .allocUint8(buffer.length + 1);
  const slice = new Uint8Array(
    memory.buffer,
    pointer,
    buffer.length + 1
  );
  slice.set(buffer);

  // Terminate the string with null
  slice[buffer.length] = 0;
  return pointer;
};

// Start the Terminal
function start_terminal() {
  term = new Term({ cols: 80, rows: 50, scrollback: 10000, fontSize: 15 });
  term.setKeyHandler(term_handler);
  term.open(
    document.getElementById("term_container"),
    document.getElementById("term_paste")
  );
  const term_wrap_el = document.getElementById("term_wrap");
  term_wrap_el.style.width = term.term_el.style.width;
  term_wrap_el.onclick = term_wrap_onclick_handler;
  term.write("This is a barebones port of TCC 64-bit RISC-V Compiler to WebAssembly. \r\nOnly very simple C programs are supported. (Sorry, no `#include`) \r\nThe generated RISC-V ELF `a.out` will be auto-downloaded. \r\nhttps://github.com/lupyuen/tcc-riscv32-wasm\r\n");
}

// Handle the Terminal Input
function term_handler(str) {
  for (let i = 0; i < str.length; i++) {
    // TODO: Send Terminal Input to WebAssembly
    // console_write1(str.charCodeAt(i));
  }
}

// Handle the Terminal Click
function term_wrap_onclick_handler() {
  const term_wrap_el = document.getElementById("term_wrap");
  const term_bar_el = document.getElementById("term_bar");
  const w = term_wrap_el.clientWidth;
  const h = term_wrap_el.clientHeight;
  const bar_h = term_bar_el.clientHeight;
  if (term.resizePixel(w, h - bar_h)) {
    // TODO: Send Resize Event to WebAssembly
    // console_resize_event();
  }
}

// Download the Encoded Data. `encoded_data` looks like "%fd%fe%ff"
function download(filename, encoded_data) {
  var element = document.createElement('a');
  element.setAttribute('href', 'data:application/octet-stream,' + encoded_data);
  element.setAttribute('download', filename);

  element.style.display = 'none';
  document.body.appendChild(element);

  element.click();

  document.body.removeChild(element);
}

// Load the WebAssembly Module and start the Main Function.
// Called by the Compile Button.
async function bootstrap() {
  // Load the WebAssembly Module
  // https://developer.mozilla.org/en-US/docs/WebAssembly/JavaScript_interface/instantiateStreaming
  const result = await WebAssembly.instantiateStreaming(
    fetch("tcc-wasm.wasm"),
    importObject
  );

  // Store references to WebAssembly Functions and Memory exported by Zig
  wasm.init(result);

  // Start the Main Function
  window.requestAnimationFrame(main);
}        

// Start the Terminal
start_terminal();
