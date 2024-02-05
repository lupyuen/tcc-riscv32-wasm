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
  #include <stdio.h>
  #include <stdlib.h>

  // Caution: This may change
  #define SYS_write 61

  void main(int argc, char *argv[])
  {
    // Make NuttX System Call to write(fd, buf, buflen)
    const unsigned int nbr = 61; // SYS_write
    const void *parm1 = 1;       // File Descriptor (stdout)
    const void *parm2 = "Hello, World!!\\n"; // Buffer
    const void *parm3 = 15; // Buffer Length

    write(parm1, parm2, parm3);
    for(;;) {}

    // // Execute ECALL for System Call to NuttX Kernel
    // register long r0 asm("a0") = (long)(nbr);
    // register long r1 asm("a1") = (long)(parm1);
    // register long r2 asm("a2") = (long)(parm2);
    // register long r3 asm("a3") = (long)(parm3);
  
    // asm volatile
    // (
    //   // Load 61 to Register A0 (SYS_write)
    //   "addi a0, zero, 61 \\n"
      
    //   // Load 1 to Register A1 (File Descriptor)
    //   "addi a1, zero, 1 \\n"
      
    //   // Load 0xc0101000 to Register A2 (Buffer)
    //   "lui   a2, 0xc0 \\n"
    //   "addiw a2, a2, 257 \\n"
    //   "slli  a2, a2, 0xc \\n"
      
    //   // Load 15 to Register A3 (Buffer Length)
    //   "addi a3, zero, 15 \\n"
      
    //   // ECALL for System Call to NuttX Kernel
    //   "ecall \\n"
      
    //   // NuttX needs NOP after ECALL
    //   ".word 0x0001 \\n"

    //   // Input+Output Registers: None
    //   // Input-Only Registers: A0 to A3
    //   // Clobbers the Memory
    //   :
    //   : "r"(r0), "r"(r1), "r"(r2), "r"(r3)
    //   : "memory"
    // );

    // // Exit via System Call
    // exit(0);
  }

  typedef int size_t;
  typedef int ssize_t;
  typedef int uintptr_t;

  // Make a System Call with 3 parameters...
  ssize_t write(int parm1, const void * parm2, size_t parm3) {
    return (ssize_t) sys_call3(
      (unsigned int) SYS_write,  // System Call Number
      (uintptr_t) parm1,         // File Descriptor (1 = Standard Output)
      (uintptr_t) parm2,         // Buffer to be written
      (uintptr_t) parm3          // Number of bytes to write
    );
  }

  // Make a System Call with 3 parameters
  uintptr_t sys_call3(
    unsigned int nbr,  // System Call Number
    uintptr_t parm1,   // First Parameter
    uintptr_t parm2,   // Second Parameter
    uintptr_t parm3    // Third Parameter
  ) {
    // Pass the Function Number and Parameters in
    // Registers A0 to A3
    register long r0 asm("a0") = (long)(nbr);
    register long r1 asm("a1") = (long)(parm1);
    register long r2 asm("a2") = (long)(parm2);
    register long r3 asm("a3") = (long)(parm3);

    // ecall will jump from RISC-V User Mode
    // to RISC-V Supervisor Mode
    // to execute the System Call.
    // Input + Output Registers: A0 to A3
    // Clobbers the Memory
    asm volatile
    (
      // ECALL for System Call to NuttX Kernel
      "ecall \\n"
      
      // NuttX needs NOP after ECALL
      ".word 0x0001 \\n"

      // Input+Output Registers: None
      // Input-Only Registers: A0 to A3
      // Clobbers the Memory
      :
      : "r"(r0), "r"(r1), "r"(r2), "r"(r3)
      : "memory"
    );

    // Return the result from Register A0
    return r0;
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
