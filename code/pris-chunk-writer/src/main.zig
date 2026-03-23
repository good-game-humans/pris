const std = @import("std");

const CHUNK_SIZE = 24000;
const POLL_NS    = 500 * std.time.ns_per_ms;
const END_MARKER = "-=END=-";

const State = struct { offset: u64, chunk: u32 };

fn loadState(state_file: []const u8) State {
    var buf: [64]u8 = undefined;
    const file = std.fs.openFileAbsolute(state_file, .{}) catch
        return .{ .offset = 0, .chunk = 0 };
    defer file.close();
    const n = file.readAll(&buf) catch return .{ .offset = 0, .chunk = 0 };
    const text = std.mem.trim(u8, buf[0..n], "\n\r ");
    const comma = std.mem.indexOfScalar(u8, text, ',') orelse
        return .{ .offset = 0, .chunk = 0 };
    const offset = std.fmt.parseInt(u64, text[0..comma], 10) catch
        return .{ .offset = 0, .chunk = 0 };
    const chunk = std.fmt.parseInt(u32, text[comma + 1 ..], 10) catch
        return .{ .offset = 0, .chunk = 0 };
    return .{ .offset = offset, .chunk = chunk };
}

fn saveState(state_file: []const u8, offset: u64, chunk: u32) !void {
    var tmp_buf: [512]u8 = undefined;
    const tmp = try std.fmt.bufPrint(&tmp_buf, "{s}.tmp", .{state_file});
    {
        const file = try std.fs.createFileAbsolute(tmp, .{});
        defer file.close();
        var content_buf: [64]u8 = undefined;
        const content = try std.fmt.bufPrint(&content_buf, "{},{}\n", .{ offset, chunk });
        try file.writeAll(content);
    }
    try std.fs.renameAbsolute(tmp, state_file);
}

fn writeChunk(output_dir: []const u8, data: []const u8, num: u32) !void {
    var path_buf: [512]u8 = undefined;
    var tmp_buf:  [512]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "{s}/pris-lines-{d:0>6}.txt", .{ output_dir, num });
    const tmp  = try std.fmt.bufPrint(&tmp_buf,  "{s}/pris-lines-{d:0>6}.tmp", .{ output_dir, num });
    {
        const file = try std.fs.createFileAbsolute(tmp, .{});
        defer file.close();
        try file.writeAll(data);
    }
    try std.fs.renameAbsolute(tmp, path);
    std.log.info("wrote chunk {d} ({d} bytes)", .{ num, data.len });
}

fn flushChunk(output_dir: []const u8, state_file: []const u8, buf: *std.ArrayList(u8), state: *State) !void {
    const split = if (std.mem.lastIndexOfScalar(u8, buf.items[0..CHUNK_SIZE], '\n')) |i|
        i + 1
    else
        CHUNK_SIZE;
    try writeChunk(output_dir, buf.items[0..split], state.chunk);
    state.offset += split;
    state.chunk  += 1;
    try saveState(state_file, state.offset, state.chunk);
    std.mem.copyForwards(u8, buf.items, buf.items[split..]);
    buf.shrinkRetainingCapacity(buf.items.len - split);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len != 3) {
        std.debug.print("usage: pris-chunk-writer <build_log> <output_dir>\n", .{});
        return error.InvalidArgs;
    }

    const build_log  = args[1];
    const output_dir = args[2];

    var state_file_buf: [512]u8 = undefined;
    const state_file = try std.fmt.bufPrint(&state_file_buf, "{s}/pris-chunk-writer.state", .{output_dir});

    var state = loadState(state_file);
    std.log.info("starting: offset={d} chunk={d}", .{ state.offset, state.chunk });

    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(alloc);

    var read_buf: [65536]u8 = undefined;

    while (true) {
        const file = std.fs.openFileAbsolute(build_log, .{}) catch {
            std.Thread.sleep(POLL_NS);
            continue;
        };
        defer file.close();

        try file.seekTo(state.offset + buf.items.len);
        const n = try file.read(&read_buf);

        if (n == 0) {
            std.Thread.sleep(POLL_NS);
            continue;
        }

        try buf.appendSlice(alloc, read_buf[0..n]);

        // End marker — flush everything and exit
        if (std.mem.indexOf(u8, buf.items, END_MARKER)) |idx| {
            const nl  = std.mem.indexOfScalarPos(u8, buf.items, idx, '\n');
            const end = if (nl) |i| i + 1 else idx + END_MARKER.len;
            buf.shrinkRetainingCapacity(end);

            while (buf.items.len >= CHUNK_SIZE) try flushChunk(output_dir, state_file, &buf, &state);

            if (buf.items.len > 0) {
                try writeChunk(output_dir, buf.items, state.chunk);
                state.offset += buf.items.len;
                state.chunk  += 1;
                try saveState(state_file, state.offset, state.chunk);
            }
            std.log.info("end marker received, exiting", .{});
            return;
        }

        while (buf.items.len >= CHUNK_SIZE) try flushChunk(output_dir, state_file, &buf, &state);
    }
}
