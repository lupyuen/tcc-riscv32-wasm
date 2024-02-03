//! TCC Test App (for WebAssembly)

/// Import the Zig Standard Library
const std = @import("std");

/// Import the WebAssembly Logger
const wasmlog = @import("wasmlog.zig");

/// Import the Hexdump Logger
const hexdump = @import("hexdump.zig");

/// Import the ROM FS
const c = @cImport({
    @cInclude("zig/zig_romfs.h");
});

/// Compile a C program to 64-bit RISC-V
pub export fn compile_program(
    options_ptr: [*:0]const u8, // Options for TCC Compiler (Pointer to JSON Array: ["-c", "hello.c"])
    code_ptr: [*:0]const u8, // C Program to be compiled (Pointer to String)
) [*]const u8 { // Returns a pointer to the `a.out` Compiled Code (Size in first 4 bytes)
    debug("compile_program: start", .{});
    defer debug("compile_program: end", .{});

    // Mount the ROM FS Filesystem
    const ret = c.romfs_bind(
        //struct inode *blkdriver, const void *data, void **handle
    );
    assert(ret >= 0);

    // Receive the TCC Compiler Options from JavaScript (JSON containing String Array: ["-c", "hello.c"])
    const options: []const u8 = std.mem.span(options_ptr);
    debug("compile_program: options={s}", .{options});
    const T = [][]u8;
    const parsed = std.json.parseFromSlice(T, std.heap.page_allocator, options, .{}) catch
        @panic("Failed to allocate memory");
    defer parsed.deinit();

    // Receive the C Program from JavaScript and set our Read Buffer
    // https://blog.battlefy.com/zig-made-it-easy-to-pass-strings-back-and-forth-with-webassembly
    const code: []const u8 = std.mem.span(code_ptr);
    debug("compile_program: code={s}", .{code});
    read_buf = code;

    // TODO: Compiler fails with "type '[*:0]const u8' does not support field access"
    // defer std.heap.page_allocator.free(code_ptr);

    // Create the Memory Allocator for malloc
    memory_allocator = std.heap.FixedBufferAllocator.init(&memory_buffer);

    // Prepare the TCC args
    const max_args = 64;
    const max_arg_size = 64;
    var args: [max_args][max_arg_size:0]u8 = undefined;
    var args_ptrs: [max_args:null]?[*:0]u8 = undefined;

    const tcc = "tcc";
    @memcpy(args[0][0..tcc.len], tcc);
    args[0][tcc.len] = 0;
    args_ptrs[0] = &args[0];

    const argc = parsed.value.len + 1;
    for (parsed.value, 0..) |option, i| {
        debug("compile_program: options[{}]={s}", .{ i, option });
        const a = i + 1;
        @memcpy(args[a][0..option.len], option);
        args[a][option.len] = 0;
        args_ptrs[a] = &args[a];
    }
    args_ptrs[argc] = null;

    // Call the TCC Compiler
    _ = main(@intCast(argc), &args_ptrs);

    // Dump the generated `a.out`
    debug("a.out: {} bytes", .{write_buflen});
    hexdump.hexdump(@ptrCast(&write_buf), write_buflen);

    // Return pointer of `a.out` to JavaScript.
    // First 4 bytes: Size of `a.out`. Followed by `a.out` data.
    const slice = std.heap.page_allocator.alloc(u8, write_buflen + 4) catch
        @panic("Failed to allocate memory");
    const size_ptr: *u32 = @alignCast(@ptrCast(slice.ptr));
    size_ptr.* = write_buflen;
    @memcpy(slice[4 .. write_buflen + 4], write_buf[0..write_buflen]);
    return slice.ptr; // TODO: Deallocate this memory
}

/// Allocate some WebAssembly Memory, so JavaScript can pass Strings to Zig
/// https://blog.battlefy.com/zig-made-it-easy-to-pass-strings-back-and-forth-with-webassembly
pub export fn allocUint8(length: u32) [*]const u8 {
    const slice = std.heap.page_allocator.alloc(u8, length) catch
        @panic("Failed to allocate memory");
    return slice.ptr;
}

/// Main Function from tcc.c
extern fn main(_argc: c_int, argv: [*:null]const ?[*:0]const u8) c_int;

///////////////////////////////////////////////////////////////////////////////
//  File Functions

export fn open(path: [*:0]const u8, oflag: c_uint, ...) c_int {
    debug("open: path={s}, oflag={}, return fd={}", .{ path, oflag, fd });
    const ret = fd;
    fd += 1;
    return ret;
}

export fn fdopen(fd0: c_int, mode: [*:0]const u8) *FILE {
    debug("fdopen: fd={}, mode={s}, return FILE={}", .{ fd0, mode, fd });
    const ret = fd;
    fd += 1;
    return @ptrFromInt(@as(usize, @intCast(ret)));
}

export fn read(fd0: c_int, buf: [*:0]u8, nbyte: size_t) isize {
    debug("read: fd={}, nbyte={}", .{ fd0, nbyte });

    // Copy from the Read Buffer
    // TODO: Support more than one file
    const len = read_buf.len;
    assert(len < nbyte);
    @memcpy(buf[0..len], read_buf[0..len]);
    buf[len] = 0;
    read_buf.len = 0;
    debug("read: return buf={s}", .{buf});
    return @intCast(len);
}

export fn fputc(ch: c_int, stream: *FILE) c_int {
    debug("fputc: ch=0x{X:0>2}, stream={*}", .{ @as(u8, @intCast(ch)), stream });

    // Copy to the Write Buffer
    // TODO: Support more than one `stream`
    @memset(write_buf[write_buflen .. write_buflen + 1], @intCast(ch));
    write_buflen += 1;
    return ch;
}

export fn fwrite(ptr: [*:0]const u8, size: usize, nmemb: usize, stream: *FILE) usize {
    debug("fwrite: size={}, nmemb={}, stream={*}", .{ size, nmemb, stream });
    hexdump.hexdump(ptr, size * nmemb);

    // Copy to the Write Buffer
    // TODO: Support more than one `stream`
    const len = size * nmemb;
    @memcpy(write_buf[write_buflen .. write_buflen + len], ptr[0..]);
    write_buflen += len;
    return nmemb;
}

export fn close(fd0: c_int) c_int {
    debug("close: fd={}", .{fd0});
    return 0;
}

export fn fclose(stream: *FILE) c_int {
    debug("close: stream={*}", .{stream});
    return 0;
}

export fn unlink(path: [*:0]const u8) c_int {
    debug("unlink: path={s}", .{path});
    return 0;
}

/// Write Buffer for fputc and fwrite
var write_buf = std.mem.zeroes([8192]u8);
var write_buflen: usize = 0;

/// Read Buffer for read
var read_buf: []const u8 = undefined;

/// Next File Descriptor
var fd: c_int = 3;
var first_read: bool = true;

///////////////////////////////////////////////////////////////////////////////
//  Semaphore Functions

export fn sem_init(sem: *sem_t, pshared: c_int, value: c_uint) c_int {
    debug("sem_init: sem={*}, pshared={}, value={}", .{ sem, pshared, value });
    return 0;
}

export fn sem_wait(sem: *sem_t) c_int {
    debug("sem_wait: sem={*}", .{sem});
    return 0;
}

export fn sem_post(sem: *sem_t) c_int {
    debug("sem_post: sem={*}", .{sem});
    return 0;
}

const sem_t = opaque {};

///////////////////////////////////////////////////////////////////////////////
//  Varargs Functions

/// Pattern Matching for String Formatting: We will match these patterns when formatting strings
const format_patterns = [_]FormatPattern{
    // Format a Single `%d`, like `#define __TINYC__ %d`
    FormatPattern{ .c_spec = "%d", .zig_spec = "{}", .type0 = c_int, .type1 = null },

    // Format a Single `%u`, like `L.%u`
    FormatPattern{ .c_spec = "%u", .zig_spec = "{}", .type0 = c_int, .type1 = null },

    // Format a Single `%s`, like `#define __BASE_FILE__ "%s"` or `.rela%s`
    FormatPattern{ .c_spec = "%s", .zig_spec = "{s}", .type0 = [*:0]const u8, .type1 = null },

    // Format Two `%s`, like `#define %s%s\n`
    FormatPattern{ .c_spec = "%s%s", .zig_spec = "{s}{s}", .type0 = [*:0]const u8, .type1 = [*:0]const u8 },

    // Format `%s:%d`, like `%s:%d: `
    FormatPattern{ .c_spec = "%s:%d", .zig_spec = "{s}:{}", .type0 = [*:0]const u8, .type1 = c_int },
};

/// Runtime Function to format a string by Pattern Matching.
/// Return the number of bytes written to `str`, excluding terminating null.
fn format_string(
    ap: *std.builtin.VaList,
    str: [*]u8,
    size: size_t,
    format: []const u8, // Like `#define %s%s\n`
) usize {
    // If no Format Specifiers: Return the Format, like `warning: `
    const len = format_string0(str, size, format);
    if (len > 0) {
        return len;
    }

    // For every Format Pattern...
    inline for (format_patterns) |pattern| {
        // Try formatting the string with the pattern...
        const len2 =
            if (pattern.type1) |t1|
            // Pattern has 2 parameters
            format_string2(ap, str, size, format, // Output String and Format String
                pattern.c_spec, pattern.zig_spec, // Format Specifiers for C and Zig
                pattern.type0, t1 // Types of the Parameters
            )
        else
            // Pattern has 1 parameter
            format_string1(ap, str, size, format, // Output String and Format String
                pattern.c_spec, pattern.zig_spec, // Format Specifiers for C and Zig
                pattern.type0 // Type of the Parameter
            );
        if (len2 > 0) {
            return len2;
        }
    }

    // Format String doesn't match any Format Pattern. We return the Format String.
    debug("TODO: format_string: format={s}", .{format});
    const len3 = format.len;
    assert(len3 < size);
    @memcpy(str[0..len3], format[0..len3]);
    str[len3] = 0;
    return len3;
}

/// Runtime Function to format a string by Pattern Matching.
/// If no Format Specifiers: Return the Format, like `warning: `
/// Return the number of bytes written to `str`, excluding terminating null.
fn format_string0(
    str: [*]u8,
    size: size_t,
    format: []const u8, // Like `#define %s%s\n`
) usize {
    // Count the Format Specifiers: `%`
    const format_cnt = std.mem.count(u8, format, "%");

    // Check the Format Specifiers: Must have no `%`
    if (format_cnt != 0) {
        return 0;
    }

    // Format the string
    debug("format_string0: size={}, format={s}", .{ size, format });
    const len = format.len;
    assert(len < size);
    @memcpy(str[0..len], format[0..len]);
    str[len] = 0;
    return len;
}

/// CompTime Function to format a string by Pattern Matching.
/// Format a Single Specifier, like `#define __BASE_FILE__ "%s"`
/// If the Spec matches the Format: Return the number of bytes written to `str`, excluding terminating null.
/// Else return 0.
fn format_string1(
    ap: *std.builtin.VaList,
    str: [*]u8,
    size: size_t,
    format: []const u8, // Like `#define %s%s\n`
    comptime c_spec: []const u8, // Like `%s%s`
    comptime zig_spec: []const u8, // Like `{s}{s}`
    comptime T0: type, // Like `[*:0]const u8`
) usize {
    // Count the Format Specifiers: `%`
    const spec_cnt = std.mem.count(u8, c_spec, "%");
    const format_cnt = std.mem.count(u8, format, "%");

    // Check the Format Specifiers: `%`
    if (format_cnt != spec_cnt or // Quit if the number of specifiers are different
        !std.mem.containsAtLeast(u8, format, 1, c_spec)) // Or if the specifiers are not found
    {
        return 0;
    }

    // Fetch the args
    const a = @cVaArg(ap, T0);
    if (T0 == c_int) {
        debug("format_string1: size={}, format={s}, a={}", .{ size, format, a });
    } else {
        debug("format_string1: size={}, format={s}, a={s}", .{ size, format, a });
    }

    // Format the string. TODO: Is 512 sufficient?
    var buf: [512]u8 = undefined;
    const buf_slice = std.fmt.bufPrint(&buf, zig_spec, .{a}) catch {
        wasmlog.Console.log("*** format_string1 error: buf too small", .{});
        @panic("*** format_string1 error: buf too small");
    };

    // Replace the Format Specifier. TODO: Is 512 sufficient?
    var buf2 = std.mem.zeroes([512]u8);
    _ = std.mem.replace(u8, format, c_spec, buf_slice, &buf2);

    // Return the string
    const len = std.mem.indexOfScalar(u8, &buf2, 0).?;
    assert(len < size);
    @memcpy(str[0..len], buf2[0..len]);
    str[len] = 0;
    return len;
}

/// CompTime Function to format a string by Pattern Matching.
/// Format Two Specifiers, like `#define %s%s\n` or `%s:%d`
/// If the Spec matches the Format: Return the number of bytes written to `str`, excluding terminating null.
/// Else return 0.
fn format_string2(
    ap: *std.builtin.VaList,
    str: [*]u8,
    size: size_t,
    format: []const u8, // Like `#define %s%s\n`
    comptime c_spec: []const u8, // Like `%s%s`
    comptime zig_spec: []const u8, // Like `{s}{s}`
    comptime T0: type, // Like `[*:0]const u8`
    comptime T1: type, // Like `[*:0]const u8`
) usize {
    // Count the Format Specifiers: `%`
    const spec_cnt = std.mem.count(u8, c_spec, "%");
    const format_cnt = std.mem.count(u8, format, "%");

    // Check the Format Specifiers: `%`
    if (format_cnt != spec_cnt or // Quit if the number of specifiers are different
        !std.mem.containsAtLeast(u8, format, 1, c_spec)) // Or if the specifiers are not found
    {
        return 0;
    }

    // Fetch the args
    const a0 = @cVaArg(ap, T0);
    const a1 = @cVaArg(ap, T1);

    // Fetch the args. TODO: Handle T0=c_int
    if (T0 != c_int and T1 == c_int) {
        debug("format_string2: size={}, format={s}, a0={s}, a1={}", .{ size, format, a0, a1 });
    } else {
        debug("format_string2: size={}, format={s}, a0={s}, a1={s}", .{ size, format, a0, a1 });
    }

    // Format the string. TODO: Is 512 sufficient?
    var buf: [512]u8 = undefined;
    const buf_slice = std.fmt.bufPrint(&buf, zig_spec, .{ a0, a1 }) catch {
        wasmlog.Console.log("*** format_string error2: buf too small", .{});
        @panic("*** format_string error2: buf too small");
    };

    // Replace the Format Specifier. TODO: Is 512 sufficient?
    var buf2 = std.mem.zeroes([512]u8);
    _ = std.mem.replace(u8, format, c_spec, buf_slice, &buf2);

    // Return the string
    const len = std.mem.indexOfScalar(u8, &buf2, 0).?;
    assert(len < size);
    @memcpy(str[0..len], buf2[0..len]);
    str[len] = 0;
    return len;
}

export fn vsnprintf(str: [*]u8, size: size_t, format: [*:0]const u8, ...) c_int {
    // Prepare the varargs
    var ap = @cVaStart();
    defer @cVaEnd(&ap);

    // Format the string
    const format_slice = std.mem.span(format);
    const len = format_string(&ap, str, size, format_slice);
    debug("vsnprintf: return str={s}", .{str[0..len]});
    return @intCast(len);
}

export fn sprintf(str: [*]u8, format: [*:0]const u8, ...) c_int {
    // Prepare the varargs
    var ap = @cVaStart();
    defer @cVaEnd(&ap);

    // Format the string. TODO: Is 512 sufficient?
    const format_slice = std.mem.span(format);
    const len = format_string(&ap, str, 512, format_slice);
    debug("sprintf: return str={s}", .{str[0..len]});
    return @intCast(len);
}

export fn snprintf(str: [*]u8, size: size_t, format: [*:0]const u8, ...) c_int {
    // Prepare the varargs
    var ap = @cVaStart();
    defer @cVaEnd(&ap);

    // Format the string
    const format_slice = std.mem.span(format);
    const len = format_string(&ap, str, size, format_slice);
    debug("snprintf: return str={s}", .{str[0..len]});
    return @intCast(len);
}

export fn fprintf(stream: *FILE, format: [*:0]const u8, ...) c_int {
    // Prepare the varargs
    var ap = @cVaStart();
    defer @cVaEnd(&ap);

    // Format the string. TODO: Is 512 sufficient?
    var buf = std.mem.zeroes([512]u8);
    const format_slice = std.mem.span(format);
    const len = format_string(&ap, &buf, buf.len, format_slice);

    // TODO: Print to other File Streams. Right now we assume it's stderr (File Descriptor 2)
    debug("fprintf: stream={*}\n{s}", .{ stream, buf });
    return @intCast(len);
}

export fn sscanf(str: [*:0]const u8, format: [*:0]const u8, ...) c_int {
    debug("TODO: sscanf: str={s}, format={s}", .{ str, format });
    return 0;
}

/// Pattern for String Formatting
const FormatPattern = struct {
    c_spec: []const u8, // Format Specifier in C: `%s:%d`
    zig_spec: []const u8, // Equivalent Format Specifier in Zig: `{s}:{}`
    type0: type, // Type of the First Parameter: `[*:0]const u8`
    type1: ?type, // Type of the Second Parameter: `c_int`
};

const size_t = usize;
const FILE = opaque {};

///////////////////////////////////////////////////////////////////////////////
//  Memory Allocator for malloc

/// Zig replacement for malloc
export fn malloc(size: usize) ?*anyopaque {
    // TODO: Save the slice length
    const mem = memory_allocator.allocator().alloc(u8, size) catch {
        debug("*** malloc error: out of memory, size={}", .{size});
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
        debug("*** realloc error: out of memory, size={}", .{size});
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
    // TODO: Why is TCC passing NULL?
    // if (mem == null) {
    //     @panic("*** free error: pointer is null");
    // }
    // TODO: How to free without the slice length?
    // memory_allocator.allocator().free(mem[0..???]);
}

/// Memory Allocator for malloc
var memory_allocator: std.heap.FixedBufferAllocator = undefined;

/// Memory Buffer for malloc
var memory_buffer = std.mem.zeroes([16 * 1024 * 1024]u8);

///////////////////////////////////////////////////////////////////////////////
//  Logging

export fn puts(s: [*:0]const u8) c_int {
    debug("{s}", .{s});
    return 0;
}

export fn fputs(s: [*:0]const u8, stream: *FILE) c_int {
    debug("fputs: s={s}, stream={*}", .{ s, stream });
    return 0;
}

export fn fflush(_: c_int) c_int {
    return 0;
}

/// Called by Zig for `std.log.debug`, `std.log.info`, `std.log.err`, ...
/// https://gist.github.com/leecannon/d6f5d7e5af5881c466161270347ce84d
/// TODO: error: root struct of file 'c' has no member named 'fd_t': "pub const fd_t = system.fd_t;"
pub fn log(
    comptime _message_level: std.log.Level,
    comptime _scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = _message_level;
    _ = _scope;

    // Format the message
    var buf: [512]u8 = undefined; // Limit to 512 chars
    const slice = std.fmt.bufPrint(&buf, format, args) catch {
        wasmlog.Console.log("*** log error: buf too small", .{});
        return;
    };

    // Print the formatted message
    wasmlog.Console.log("{s}", .{slice});
}

/// Aliases for Zig Standard Library
const assert = std.debug.assert;
const debug = wasmlog.Console.log;

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

pub export fn getenv(_: c_int) ?[*]u8 {
    return null;
}

///////////////////////////////////////////////////////////////////////////////
// From ziglibc

// String Functions:
// https://github.com/marler8997/ziglibc/blob/main/src/cstd.zig

export fn strrchr(s: [*:0]const u8, char: c_int) callconv(.C) ?[*:0]const u8 {
    // trace.log("strrchr {} c='{}'", .{ trace.fmtStr(s), char });
    var next = s + strlen(s);
    while (true) {
        if (next[0] == char) return next;
        if (next == s) return null;
        next = next - 1;
    }
}

export fn strcmp(a: [*:0]const u8, b: [*:0]const u8) callconv(.C) c_int {
    // trace.log("strcmp {} {}", .{ trace.fmtStr(a), trace.fmtStr(b) });
    var a_next = a;
    var b_next = b;
    while (a_next[0] == b_next[0] and a_next[0] != 0) {
        a_next += 1;
        b_next += 1;
    }
    const result = @as(c_int, @intCast(a_next[0])) -| @as(c_int, @intCast(b_next[0]));
    // trace.log("strcmp return {}", .{result});
    return result;
}

export fn strstr(s1: [*:0]const u8, s2: [*:0]const u8) callconv(.C) ?[*:0]const u8 {
    // trace.log("strstr {} {}", .{ trace.fmtStr(s1), trace.fmtStr(s2) });
    const s1_len = strlen(s1);
    const s2_len = strlen(s2);
    var i: usize = 0;
    while (i + s2_len <= s1_len) : (i += 1) {
        const search = s1 + i;
        if (0 == strncmp(search, s2, s2_len)) return search;
    }
    return null;
}

export fn strchr(s: [*:0]const u8, char: c_int) callconv(.C) ?[*:0]const u8 {
    // trace.log("strchr {} c='{}'", .{ trace.fmtStr(s), char });
    var next = s;
    while (true) : (next += 1) {
        if (next[0] == char) return next;
        if (next[0] == 0) return null;
    }
}
export fn strncmp(a: [*:0]const u8, b: [*:0]const u8, n: usize) callconv(.C) c_int {
    // trace.log("strncmp {*} {*} n={}", .{ a, b, n });
    var i: usize = 0;
    while (a[i] == b[i] and a[0] != 0) : (i += 1) {
        if (i == n - 1) return 0;
    }
    return @as(c_int, @intCast(a[i])) -| @as(c_int, @intCast(b[i]));
}

export fn strlen(s: [*:0]const u8) callconv(.C) usize {
    // trace.log("strlen {}", .{trace.fmtStr(s)});
    const result = std.mem.len(s);
    // trace.log("strlen return {}", .{result});
    return result;
}

export fn strtoull(nptr: [*:0]const u8, endptr: ?*[*:0]u8, base: c_int) callconv(.C) c_ulonglong {
    // trace.log("strtoull {} endptr={*} base={}", .{ trace.fmtStr(nptr), endptr, base });
    return strto(c_ulonglong, nptr, endptr, base);
}

fn strto(comptime T: type, str: [*:0]const u8, optional_endptr: ?*[*:0]const u8, optional_base: c_int) T {
    var next = str;

    // skip whitespace
    while (isspace(next[0]) != 0) : (next += 1) {}
    const start = next;
    _ = start; // autofix

    const sign: enum { pos, neg } = blk: {
        if (next[0] == '-') {
            next += 1;
            break :blk .neg;
        }
        if (next[0] == '+') next += 1;
        break :blk .pos;
    };

    const base = blk: {
        if (optional_base != 0) {
            if (optional_base > 36) {
                if (optional_endptr) |endptr| endptr.* = next;
                errno = EINVAL;
                return 0;
            }
            if (optional_base == 16 and next[0] == '0' and (next[1] == 'x' or next[1] == 'X')) {
                next += 2;
            }
            break :blk @as(u8, @intCast(optional_base));
        }
        if (next[0] == '0') {
            if (next[1] == 'x' or next[1] == 'X') {
                next += 2;
                break :blk 16;
            }
            next += 1;
            break :blk 8;
        }
        break :blk 10;
    };

    const digit_start = next;
    var x: T = 0;

    while (true) : (next += 1) {
        const ch = next[0];
        if (ch == 0) break;
        const digit = std.math.cast(T, std.fmt.charToDigit(ch, base) catch break) orelse {
            if (optional_endptr) |endptr| endptr.* = next;
            errno = ERANGE;
            return 0;
        };
        if (x != 0) x = std.math.mul(T, x, std.math.cast(T, base) orelse {
            errno = EINVAL;
            return 0;
        }) catch {
            if (optional_endptr) |endptr| endptr.* = next;
            errno = ERANGE;
            return switch (sign) {
                .neg => std.math.minInt(T),
                .pos => std.math.maxInt(T),
            };
        };
        x = switch (sign) {
            .pos => std.math.add(T, x, digit) catch {
                if (optional_endptr) |endptr| endptr.* = next + 1;
                errno = ERANGE;
                return switch (sign) {
                    .neg => std.math.minInt(T),
                    .pos => std.math.maxInt(T),
                };
            },
            .neg => std.math.sub(T, x, digit) catch {
                if (optional_endptr) |endptr| endptr.* = next + 1;
                errno = ERANGE;
                return switch (sign) {
                    .neg => std.math.minInt(T),
                    .pos => std.math.maxInt(T),
                };
            },
        };
    }

    if (optional_endptr) |endptr| endptr.* = next;
    if (next == digit_start) {
        errno = EINVAL; // TODO: is this right?
    } else {
        // trace.log("strto str='{s}' result={}", .{ start[0 .. @intFromPtr(next) - @intFromPtr(start)], x });
    }
    return x;
}

export fn isspace(char: c_int) callconv(.C) c_int {
    // trace.log("isspace {}", .{char});
    return @intFromBool(std.ascii.isWhitespace(std.math.cast(u8, char) orelse return 0));
}

const EPERM: c_int = 1;
const ENOENT: c_int = 2;
const EINTR: c_int = 4;
const EAGAIN: c_int = 11;
const ENOMEM: c_int = 12;
const EACCES: c_int = 13;
const EEXIST: c_int = 17;
const EINVAL: c_int = 22;
const ENOTTY: c_int = 25;
const EPIPE: c_int = 32;
const EDOM: c_int = 33;
const ERANGE: c_int = 34;
const EWOULDBLOCK: c_int = 140;
const ECONNREFUSED: c_int = 111;

///////////////////////////////////////////////////////////////////////////////
/// Fix the Missing Variables
pub export var errno: c_int = 0;
pub export var stdout: c_int = 1;
pub export var stderr: c_int = 2;

/// Fix the Missing Functions
pub export fn atoi(_: c_int) c_int {
    @panic("TODO: atoi");
}
pub export fn exit(_: c_int) c_int {
    @panic("TODO: exit");
}
pub export fn fopen(_: c_int) c_int {
    @panic("TODO: fopen");
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
pub export fn printf(_: c_int) c_int {
    @panic("TODO: printf");
}
pub export fn qsort(_: c_int) c_int {
    @panic("TODO: qsort");
}
pub export fn remove(_: c_int) c_int {
    @panic("TODO: remove");
}
pub export fn strcat(_: c_int) c_int {
    @panic("TODO: strcat");
}
pub export fn strerror(_: c_int) c_int {
    @panic("TODO: strerror");
}
pub export fn strncpy(_: c_int) c_int {
    @panic("TODO: strncpy");
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
pub export fn time(_: c_int) c_int {
    @panic("TODO: time");
}
