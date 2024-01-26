//! TCC Test App (for WebAssembly)

/// Import the Zig Standard Library
const std = @import("std");

/// Import the WebAssembly Logger
const wasmlog = @import("wasmlog.zig");

/// Compile a C program to 64-bit RISC-V
pub export fn compile_program() u32 {
    wasmlog.Console.log("{s}", .{"compile_program"});

    // Create the Memory Allocator for malloc
    memory_allocator = std.heap.FixedBufferAllocator.init(&memory_buffer);

    const max_args = 64;
    const max_arg_size = 64;
    var args: [max_args][max_arg_size:0]u8 = undefined;
    var args_ptrs: [max_args:null]?[*:0]u8 = undefined;

    // Prepare the TCC args
    const argv = [_][]const u8{
        "tcc",
        "-c",
        "hello.c",
    };
    const argc = argv.len;
    for (argv, 0..) |s, i| {
        std.mem.copyForwards(u8, &args[i], s);
        args[i][s.len] = 0;
        args_ptrs[i] = &args[i];
    }
    args_ptrs[argc] = null;

    // Call the TCC Compiler
    _ = main(argc, &args_ptrs);

    return 123;
}

/// Main Function from tcc.c
extern fn main(_argc: c_int, argv: [*:null]const ?[*:0]const u8) c_int;

///////////////////////////////////////////////////////////////////////////////
//  Memory Allocator for malloc

/// Zig replacement for malloc
export fn malloc(size: usize) ?*anyopaque {
    // TODO: Save the slice length
    const mem = memory_allocator.allocator().alloc(u8, size) catch {
        @panic("*** malloc error: out of memory");
    };
    return mem.ptr;
}

/// Zig replacement for realloc
export fn realloc(old_mem: [*c]u8, size: usize) ?*anyopaque {
    // TODO: Call realloc instead
    // const mem = memory_allocator.allocator().realloc(old_mem[0..???], size) catch {
    //     @panic("*** realloc error: out of memory");
    // };
    const mem = memory_allocator.allocator().alloc(u8, size) catch {
        @panic("*** realloc error: out of memory");
    };
    _ = memcpy(mem.ptr, old_mem, size);
    if (old_mem != null) {
        // TODO: How to free without the slice length?
        // memory_allocator.allocator().free(old_mem[0..???]);
    }
    return mem.ptr;
}

/// Zig replacement for free
export fn free(mem: [*c]u8) void {
    _ = mem; // autofix
    // TODO: if (mem == null) {
    //     @panic("*** free error: pointer is null");
    // }
    // TODO: How to free without the slice length?
    // memory_allocator.allocator().free(mem[0..???]);
}

/// Memory Allocator for malloc
var memory_allocator: std.heap.FixedBufferAllocator = undefined;

/// Memory Buffer for malloc
var memory_buffer = std.mem.zeroes([1024 * 1024]u8);

///////////////////////////////////////////////////////////////////////////////
//  C Standard Library
//  From zig-macos-x86_64-0.10.0-dev.2351+b64a1d5ab/lib/zig/c.zig

export fn memset(dest: ?[*]u8, c2: u8, len: usize) callconv(.C) ?[*]u8 {
    @setRuntimeSafety(false);

    if (len != 0) {
        var d = dest.?;
        var n = len;
        while (true) {
            d[0] = c2;
            n -= 1;
            if (n == 0) break;
            d += 1;
        }
    }

    return dest;
}

export fn memcpy(noalias dest: ?[*]u8, noalias src: ?[*]const u8, len: usize) callconv(.C) ?[*]u8 {
    @setRuntimeSafety(false);

    if (len != 0) {
        var d = dest.?;
        var s = src.?;
        var n = len;
        while (true) {
            d[0] = s[0];
            n -= 1;
            if (n == 0) break;
            d += 1;
            s += 1;
        }
    }

    return dest;
}

export fn strcpy(dest: [*:0]u8, src: [*:0]const u8) callconv(.C) [*:0]u8 {
    var i: usize = 0;
    while (src[i] != 0) : (i += 1) {
        dest[i] = src[i];
    }
    dest[i] = 0;

    return dest;
}

// export fn strcmp(s1: [*:0]const u8, s2: [*:0]const u8) callconv(.C) c_int {
//     return std.cstr.cmp(s1, s2);
// }

export fn strlen(s: [*:0]const u8) callconv(.C) usize {
    return std.mem.len(s);
}

pub export fn getenv(_: c_int) ?[*]u8 {
    return null;
}

///////////////////////////////////////////////////////////////////////////////
/// Fix the Missing Variables
pub export var errno: c_int = 0;
pub export var stdout: c_int = 1;
pub export var stderr: c_int = 2;

/// Fix the Missing Functions
pub export fn atoi(_: c_int) c_int {
    @panic("TODO: atoi");
}
pub export fn close(_: c_int) c_int {
    @panic("TODO: close");
}
pub export fn exit(_: c_int) c_int {
    @panic("TODO: exit");
}
pub export fn fclose(_: c_int) c_int {
    @panic("TODO: fclose");
}
pub export fn fdopen(_: c_int) c_int {
    @panic("TODO: fdopen");
}
pub export fn fflush(_: c_int) c_int {
    @panic("TODO: fflush");
}
pub export fn fopen(_: c_int) c_int {
    @panic("TODO: fopen");
}
pub export fn fprintf(_: c_int) c_int {
    @panic("TODO: fprintf");
}
pub export fn fputc(_: c_int) c_int {
    @panic("TODO: fputc");
}
pub export fn fputs(_: c_int) c_int {
    @panic("TODO: fputs");
}
pub export fn fread(_: c_int) c_int {
    @panic("TODO: fread");
}
pub export fn fseek(_: c_int) c_int {
    @panic("TODO: fseek");
}
pub export fn ftell(_: c_int) c_int {
    @panic("TODO: ftell");
}
pub export fn fwrite(_: c_int) c_int {
    @panic("TODO: fwrite");
}
pub export fn getcwd(_: c_int) c_int {
    @panic("TODO: getcwd");
}
pub export fn gettimeofday(_: c_int) c_int {
    @panic("TODO: gettimeofday");
}
pub export fn ldexp(_: c_int) c_int {
    @panic("TODO: ldexp");
}
pub export fn localtime(_: c_int) c_int {
    @panic("TODO: localtime");
}
pub export fn lseek(_: c_int) c_int {
    @panic("TODO: lseek");
}
pub export fn open(_: c_int) c_int {
    @panic("TODO: open");
}
pub export fn printf(_: c_int) c_int {
    @panic("TODO: printf");
}
pub export fn puts(_: c_int) c_int {
    @panic("TODO: puts");
}
pub export fn qsort(_: c_int) c_int {
    @panic("TODO: qsort");
}
pub export fn read(_: c_int) c_int {
    @panic("TODO: read");
}
pub export fn remove(_: c_int) c_int {
    @panic("TODO: remove");
}
pub export fn sem_init(_: c_int) c_int {
    @panic("TODO: sem_init");
}
pub export fn sem_post(_: c_int) c_int {
    @panic("TODO: sem_post");
}
pub export fn sem_wait(_: c_int) c_int {
    @panic("TODO: sem_wait");
}
pub export fn snprintf(_: c_int) c_int {
    @panic("TODO: snprintf");
}
pub export fn sprintf(_: c_int) c_int {
    @panic("TODO: sprintf");
}
pub export fn sscanf(_: c_int) c_int {
    @panic("TODO: sscanf");
}
pub export fn strcat(_: c_int) c_int {
    @panic("TODO: strcat");
}
pub export fn strchr(_: c_int) c_int {
    @panic("TODO: strchr");
}
pub export fn strcmp(_: c_int) c_int {
    @panic("TODO: strcmp");
}
pub export fn strerror(_: c_int) c_int {
    @panic("TODO: strerror");
}
pub export fn strncmp(_: c_int) c_int {
    @panic("TODO: strncmp");
}
pub export fn strncpy(_: c_int) c_int {
    @panic("TODO: strncpy");
}
pub export fn strrchr(_: c_int) c_int {
    @panic("TODO: strrchr");
}
pub export fn strstr(_: c_int) c_int {
    @panic("TODO: strstr");
}
pub export fn strtod(_: c_int) c_int {
    @panic("TODO: strtod");
}
pub export fn strtof(_: c_int) c_int {
    @panic("TODO: strtof");
}
pub export fn strtol(_: c_int) c_int {
    @panic("TODO: strtol");
}
pub export fn strtold(_: c_int) c_int {
    @panic("TODO: strtold");
}
pub export fn strtoll(_: c_int) c_int {
    @panic("TODO: strtoll");
}
pub export fn strtoul(_: c_int) c_int {
    @panic("TODO: strtoul");
}
pub export fn strtoull(_: c_int) c_int {
    @panic("TODO: strtoull");
}
pub export fn time(_: c_int) c_int {
    @panic("TODO: time");
}
pub export fn unlink(_: c_int) c_int {
    @panic("TODO: unlink");
}
pub export fn vsnprintf(_: c_int) c_int {
    @panic("TODO: vsnprintf");
}
