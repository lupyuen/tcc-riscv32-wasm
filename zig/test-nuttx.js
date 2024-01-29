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

// Load the WebAssembly
WebAssembly.instantiate(typedArray, {
  env: {
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
  }
}).then(result => {
  // Store references to WebAssembly Functions and Memory exported by Zig
  wasm.init(result);

  // Allocate a String for passing the Compiler Options to Zig
  const options = ["-c", "-r", "hello.c"];
  const options_ptr = allocateString(JSON.stringify(options));

  // Allocate a String for passing Program Code to Zig
  const code_ptr = allocateString(`
  int main(int argc, char *argv[])
  {
    // Make NuttX System Call to write(fd, buf, buflen)
    const unsigned int nbr = 61; // SYS_write
    const void *parm1 = 1;       // File Descriptor (stdout)
    const void *parm2 = "Hello, World!!\\n"; // Buffer
    const void *parm3 = 15; // Buffer Length

    // Execute ECALL for System Call to NuttX Kernel
    register long r0 asm("a0") = (long)(nbr);
    register long r1 asm("a1") = (long)(parm1);
    register long r2 asm("a2") = (long)(parm2);
    register long r3 asm("a3") = (long)(parm3);
  
    asm volatile
    (
      // Load 61 to Register A0 (SYS_write)
      // li a0, 61
      ".long 0x03d00513 \\n"

      // Load 1 to Register A1 (File Descriptor)
      // li a1, 1
      ".long 0x00100593 \\n"

      // Load 0xC0100000 to Register A2 (Buffer)
      // li a2, 0xC0100000
      ".long 0x00001637 \\n"
      ".long 0xc016061b \\n"
      ".long 0x01461613 \\n"

      // Load 15 to Register A3 (Buffer Length)
      // li a3, 15
      ".long 0x00f00693 \\n"

      // ECALL for System Call to NuttX Kernel
      "ecall \\n"

      // We inserted NOP, because TCC says it's invalid (see below)
      ".word 0x0001 \\n"
      :: "r"(r0), "r"(r1), "r"(r2), "r"(r3)
      : "memory"
    );
  
    // TODO: TCC says this is invalid
    // asm volatile("nop" : "=r"(r0));

    // Loop Forever
    for(;;) {}
    return 0;
  }
  `);

  // Call TCC to compile a program
  const ptr = wasm.instance.exports
    .compile_program(options_ptr, code_ptr);
  console.log(`ptr=${ptr}`);

  // Get the `a.out` size from first 4 bytes returned
  const memory = wasm.instance.exports.memory;
  const data_len = new Uint8Array(memory.buffer, ptr, 4);
  const len = data_len[0] | data_len[1] << 8 | data_len[2] << 16 | data_len[3] << 24;
  console.log(`main: len=${len}`);
  if (len <= 0) { return; }

  // Save the `a.out` data from the rest of the bytes returned
  const data = new Uint8Array(memory.buffer, ptr + 4, len);
  fs.writeFileSync("/tmp/a.out", Buffer.from(data));
  console.log("TCC Output saved to /tmp/a.out");
});

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
