//! TCC Test App (for WebAssembly)

/// Import the Zig Standard Library
const std = @import("std");

/// Compile a C program to 64-bit RISC-V
pub export fn compile_program() u32 {
    const argc = 1;
    _ = argc; // autofix
    const max_args = 64;
    const max_arg_size = 64;
    var args: [max_args][max_arg_size:0]u8 = undefined;
    var args_ptrs: [max_args:null]?[*:0]u8 = undefined;

    const s = "hello";
    std.mem.copyForwards(u8, &args[0], s);
    args[0][s.len] = 0;
    args_ptrs[1] = null;

    // TODO: Calling main() will show
    // error: wasm-ld: tcc.o: undefined symbol: realloc
    // _ = main(argc, &args_ptrs);

    return 123;
}

extern fn main(_argc: c_int, argv: [*:null]const ?[*:0]const u8) c_int;
