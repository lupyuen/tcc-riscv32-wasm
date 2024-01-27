// Hexdump based on
// https://gist.github.com/KaneRoot/caa34cba0a317fb6f96d3a4f93b1e228

/// Import the Zig Standard Library
const std = @import("std");

/// Import the WebAssembly Logger
const wasmlog = @import("wasmlog.zig");

/// Dump the buffer in hex
pub fn hexdump(buffer: [*:0]const u8, len: usize) void {
    var hexb: u32 = 0;
    var ascii: [16]u8 = undefined;
    // First line, first left side (simple number).
    log("  {d:0>4}:  ", .{hexb});

    // Loop on all values in the buffer (i from 0 to len).
    var i: u32 = 0;
    while (i < len) : (i += 1) {
        // Print actual hexadecimal value.
        log("{X:0>2} ", .{buffer[i]});

        // What to print (simple ascii text, right side).
        if (buffer[i] >= ' ' and buffer[i] <= '~') {
            ascii[(i % 16)] = buffer[i];
        } else {
            ascii[(i % 16)] = '.';
        }

        // Next input is a multiple of 8 = extra space.
        if ((i + 1) % 8 == 0) {
            log(" ", .{});
        }

        // No next input: print the right amount of spaces.
        if ((i + 1) == len) {
            // Each line is 16 bytes to print, each byte takes 3 characters.
            var missing_spaces = 3 * (15 - (i % 16));
            // Missing an extra space if the current index % 16 is less than 7.
            if ((i % 16) < 7) {
                missing_spaces += 1;
            }
            while (missing_spaces > 0) : (missing_spaces -= 1) {
                log(" ", .{});
            }
        }

        // Every 16 bytes: print ascii text and line return.

        // Case 1: it's been 16 bytes AND it's the last byte to print.
        if ((i + 1) % 16 == 0 and (i + 1) == len) {
            log("{s}\n", .{ascii[0..ascii.len]});
        }
        // Case 2: it's been 16 bytes but it's not the end of the buffer.
        else if ((i + 1) % 16 == 0 and (i + 1) != len) {
            log("{s}\n", .{ascii[0..ascii.len]});
            hexb += 16;
            log("  {d:0>4}:  ", .{hexb});
        }
        // Case 3: not the end of the 16 bytes row but it's the end of the buffer.
        else if ((i + 1) % 16 != 0 and (i + 1) == len) {
            log(" {s}\n", .{ascii[0..((i + 1) % 16)]});
        }
        // Case 4: not the end of the 16 bytes row and not the end of the buffer.
        //         Do nothing.
    }

    log("\n", .{});
}

/// Print to the WebAssembly Logger
fn log(
    comptime format: []const u8,
    args: anytype,
) void {
    // Format the message
    const slice = std.fmt.bufPrint(buf[buflen..], format, args) catch {
        wasmlog.Console.log("*** log error: buf too small", .{});
        return;
    };
    buflen += slice.len;

    // Print the formatted message
    if (std.mem.containsAtLeast(u8, slice, 1, "\n")) {
        wasmlog.Console.log("{s}", .{buf[0 .. buflen - 1]});
        buflen = 0;
    }
}

/// Log Buffer
var buf = std.mem.zeroes([256]u8);
var buflen: usize = 0;
