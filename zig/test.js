const fs = require('fs');
const source = fs.readFileSync("./tcc-wasm.wasm");
const typedArray = new Uint8Array(source);

// Log WebAssembly Messages from Zig to JavaScript Console
// https://github.com/daneelsan/zig-wasm-logger/blob/master/script.js
const text_decoder = new TextDecoder();
let console_log_buffer = "";

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

WebAssembly.instantiate(typedArray, {
  env: {
    print: (result) => { console.log(`The result is ${result}`); },

    // Write to JavaScript Console from Zig
    // https://github.com/daneelsan/zig-wasm-logger/blob/master/script.js
    jsConsoleLogWrite: function(ptr, len) {
      console_log_buffer += wasm.getString(ptr, len);
    },

    // Flush JavaScript Console from Zig
    // https://github.com/daneelsan/zig-wasm-logger/blob/master/script.js
    jsConsoleLogFlush: function() {
      console.log(console_log_buffer);
      console_log_buffer = "";
    },
  }}).then(result => {

  // Store references to WebAssembly Functions and Memory exported by Zig
  wasm.init(result);

  // Call TCC to compile a program
  const compile_program = result.instance.exports.compile_program;
  const ret = compile_program();
  console.log(`ret=${ret}`);
});
