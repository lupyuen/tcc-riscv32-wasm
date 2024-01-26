// References to Exported Zig Functions
let TCC;

// Export JavaScript Functions to Zig
const importObject = {
    // JavaScript Functions exported to Zig
    env: {
        // JavaScript Print Function exported to Zig
        print: function(x) { console.log(x); }
    }
};

// Main Function
function main() {
    console.log("main: start");

    const ret = TCC.instance.exports
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
    TCC = result;

    // Start the Main Function
    main();
}

// Start the loading of WebAssembly Module
bootstrap();
