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
            console.log(console_log_buffer);
            console_log_buffer = "";
        },
    }
};

// Main Function
function main() {
    console.log("main: start");

    // Call TCC to compile a program
    const ret = wasm.instance.exports
        .compile_program();
    console.log(`ret=${ret}`);

    console.log("main: end");
};

// Load the WebAssembly Module and start the Main Function
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
    main();
}

// Start the loading of WebAssembly Module
bootstrap();
