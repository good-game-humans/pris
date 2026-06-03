const std = @import("std");
const linux = std.os.linux;

// pris-crlf-filter — stream-transform a build's serial output for pris-screen.
//
//   \r\n     -> \n               drop the redundant ONLCR carriage return
//   bare \r  -> \n + SENTINEL     a newline so `ts` can timestamp and stream the
//                                 update, plus a 0x01 sentinel telling pris-screen
//                                 the break was a carriage return (overwrite in place)
//   \n       -> \n
//
// Byte-streaming like `tr` (writes each read burst straight through), so
// carriage-return-only progress (ninja/LLVM) keeps flowing instead of buffering
// until a newline arrives — which is what line-oriented tools (sed/perl) cannot
// do, and what `tr` could not encode the sentinel for.
//
// Uses the raw Linux syscall layer (the binary only runs on the Linux target),
// which stays stable across the std I/O reworks.

const SENTINEL: u8 = 0x01;
const IN_SIZE = 65536;

fn writeAll(fd: i32, bytes: []const u8) void {
    var off: usize = 0;
    while (off < bytes.len) {
        const n: isize = @bitCast(linux.write(fd, bytes[off..].ptr, bytes.len - off));
        if (n <= 0) return;
        off += @intCast(n);
    }
}

pub fn main() void {
    var in_buf: [IN_SIZE]u8 = undefined;
    var out_buf: [IN_SIZE * 2 + 8]u8 = undefined; // worst case: every byte -> 2
    var pending_cr = false;

    while (true) {
        const n: isize = @bitCast(linux.read(0, &in_buf, in_buf.len));
        if (n <= 0) break;
        const count: usize = @intCast(n);

        var out_len: usize = 0;
        for (in_buf[0..count]) |c| {
            if (pending_cr) {
                pending_cr = false;
                if (c == '\n') {
                    out_buf[out_len] = '\n'; // \r\n -> \n
                    out_len += 1;
                    continue;
                }
                // bare \r -> newline + sentinel, then handle c below
                out_buf[out_len] = '\n';
                out_buf[out_len + 1] = SENTINEL;
                out_len += 2;
            }
            if (c == '\r') {
                pending_cr = true;
            } else {
                out_buf[out_len] = c;
                out_len += 1;
            }
        }
        if (out_len > 0) writeAll(1, out_buf[0..out_len]);
    }

    if (pending_cr) writeAll(1, &[_]u8{ '\n', SENTINEL });
}
