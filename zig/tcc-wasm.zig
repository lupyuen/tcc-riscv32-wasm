//! TCC Test App (for WebAssembly)

/// Import the Zig Standard Library
const std = @import("std");

/// Compile a C program to 64-bit RISC-V
pub export fn compile_program() u32 {
    const max_args = 64;
    const max_arg_size = 64;
    var args: [max_args][max_arg_size:0]u8 = undefined;
    var args_ptrs: [max_args:null]?[*:0]u8 = undefined;

    const argv = [_][]const u8{
        "tcc",
        "-c",
        "hello.c",
    };
    const argc = argv.len;
    for (argv, 0..) |s, i| {
        @memcpy(&args[i], s);
        args[i][s.len] = 0;
        args_ptrs[i] = &args[i];
    }
    args_ptrs[argc] = null;

    // TODO: Calling main() will fail the build...
    // error: wasm-ld: tcc.o: undefined symbol: realloc
    _ = main(argc, &args_ptrs);

    return 123;
}

/// Main Function from tcc.c
extern fn main(_argc: c_int, argv: [*:null]const ?[*:0]const u8) c_int;
