const std = @import("std");
const term = @import("terminal");
const linux = std.os.linux;

const CHUNK_SIZE   = 1600; // MAX_CHUNK_SZ in pris-screen
const POLL_NS      = 500 * std.time.ns_per_ms;
const IDLE_FLUSHES = 3; // flush partial buffer after this many consecutive idle polls
const END_MARKER   = "-=END=-";

// Keyframes: a periodic snapshot of the rendered screen so a fresh connection
// can prime its display instantly instead of starting blank. Written every
// KEYFRAME_INTERVAL_S of stream time; only the most recent KEYFRAME_KEEP .bin
// files are retained (the client only ever wants the latest one <= now-5s).
const KEYFRAME_INTERVAL_S: f64 = 5.0;
const KEYFRAME_KEEP: u32 = 12;

const State = struct { offset: u64, chunk: u32 };

// --- Raw Linux syscall I/O (stable across the std.Io reworks) ---

fn sysErr(r: usize) isize {
    return @bitCast(r);
}

fn openRead(path: [*:0]const u8) !i32 {
    const r = linux.open(path, .{ .ACCMODE = .RDONLY }, 0);
    if (sysErr(r) < 0) return error.OpenFailed;
    return @intCast(r);
}

fn openTrunc(path: [*:0]const u8) !i32 {
    const r = linux.open(path, .{ .ACCMODE = .WRONLY, .CREAT = true, .TRUNC = true }, 0o644);
    if (sysErr(r) < 0) return error.OpenFailed;
    return @intCast(r);
}

fn openAppend(path: [*:0]const u8) !i32 {
    const r = linux.open(path, .{ .ACCMODE = .WRONLY, .CREAT = true, .APPEND = true }, 0o644);
    if (sysErr(r) < 0) return error.OpenFailed;
    return @intCast(r);
}

fn writeAll(fd: i32, bytes: []const u8) !void {
    var off: usize = 0;
    while (off < bytes.len) {
        const n = sysErr(linux.write(fd, bytes.ptr + off, bytes.len - off));
        if (n <= 0) return error.WriteFailed;
        off += @intCast(n);
    }
}

fn sleepNs(ns: u64) void {
    var ts = linux.timespec{
        .sec = @intCast(ns / std.time.ns_per_s),
        .nsec = @intCast(ns % std.time.ns_per_s),
    };
    _ = linux.nanosleep(&ts, null);
}

// --- State persistence ---

fn loadState(output_dir: []const u8) State {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrintZ(&path_buf, "{s}/pris-chunk-writer.state", .{output_dir}) catch
        return .{ .offset = 0, .chunk = 0 };
    const fd = openRead(path.ptr) catch return .{ .offset = 0, .chunk = 0 };
    defer _ = linux.close(fd);

    var buf: [64]u8 = undefined;
    const n = sysErr(linux.read(fd, &buf, buf.len));
    if (n <= 0) return .{ .offset = 0, .chunk = 0 };
    const text = std.mem.trim(u8, buf[0..@intCast(n)], "\n\r ");
    const comma = std.mem.indexOfScalar(u8, text, ',') orelse
        return .{ .offset = 0, .chunk = 0 };
    const offset = std.fmt.parseInt(u64, text[0..comma], 10) catch
        return .{ .offset = 0, .chunk = 0 };
    const chunk = std.fmt.parseInt(u32, text[comma + 1 ..], 10) catch
        return .{ .offset = 0, .chunk = 0 };
    return .{ .offset = offset, .chunk = chunk };
}

fn saveState(output_dir: []const u8, offset: u64, chunk: u32) !void {
    var tmp_buf:  [512]u8 = undefined;
    var path_buf: [512]u8 = undefined;
    const tmp  = try std.fmt.bufPrintZ(&tmp_buf,  "{s}/pris-chunk-writer.state.tmp", .{output_dir});
    const path = try std.fmt.bufPrintZ(&path_buf, "{s}/pris-chunk-writer.state", .{output_dir});
    {
        const fd = try openTrunc(tmp.ptr);
        defer _ = linux.close(fd);
        var content_buf: [64]u8 = undefined;
        const content = try std.fmt.bufPrint(&content_buf, "{d},{d}\n", .{ offset, chunk });
        try writeAll(fd, content);
    }
    if (sysErr(linux.rename(tmp.ptr, path.ptr)) < 0) return error.RenameFailed;
}

fn extractFirstTimestamp(data: []const u8) []const u8 {
    const prefix = "[pris ";
    const start = std.mem.indexOf(u8, data, prefix) orelse return "";
    const ts_start = start + prefix.len;
    const ts_end = std.mem.indexOfScalarPos(u8, data, ts_start, ']') orelse return "";
    return data[ts_start..ts_end];
}

fn appendChunkTime(output_dir: []const u8, chunk_num: u32, timestamp: []const u8) !void {
    if (timestamp.len == 0) return;
    var path_buf: [512]u8 = undefined;
    const path = try std.fmt.bufPrintZ(&path_buf, "{s}/chunk-times.txt", .{output_dir});
    const fd = try openAppend(path.ptr);
    defer _ = linux.close(fd);
    var line_buf: [128]u8 = undefined;
    const line = try std.fmt.bufPrint(&line_buf, "{d},{s}\n", .{ chunk_num, timestamp });
    try writeAll(fd, line);
}

fn writeChunk(output_dir: []const u8, data: []const u8, num: u32) !void {
    var path_buf: [512]u8 = undefined;
    var tmp_buf:  [512]u8 = undefined;
    const path = try std.fmt.bufPrintZ(&path_buf, "{s}/pris-lines-{d:0>8}.txt", .{ output_dir, num });
    const tmp  = try std.fmt.bufPrintZ(&tmp_buf,  "{s}/pris-lines-{d:0>8}.tmp", .{ output_dir, num });
    {
        const fd = try openTrunc(tmp.ptr);
        defer _ = linux.close(fd);
        try writeAll(fd, data);
    }
    if (sysErr(linux.rename(tmp.ptr, path.ptr)) < 0) return error.RenameFailed;
}

fn flushChunk(output_dir: []const u8, buf: *std.ArrayList(u8), state: *State) !void {
    const split = if (std.mem.lastIndexOfScalar(u8, buf.items[0..CHUNK_SIZE], '\n')) |i|
        i + 1
    else
        CHUNK_SIZE;
    const timestamp = extractFirstTimestamp(buf.items[0..split]);
    try writeChunk(output_dir, buf.items[0..split], state.chunk);
    try appendChunkTime(output_dir, state.chunk, timestamp);
    state.offset += split;
    state.chunk  += 1;
    try saveState(output_dir, state.offset, state.chunk);
    std.mem.copyForwards(u8, buf.items, buf.items[split..]);
    buf.shrinkRetainingCapacity(buf.items.len - split);
}

// --- Keyframes ---

// Serialize the current terminal screen and append it to the keyframe index,
// pruning the oldest retained snapshot.
fn writeKeyframe(output_dir: []const u8, id: u32, ts_str: []const u8, kf_buf: []u8) !void {
    const len = term.serializeKeyframe(kf_buf);

    var path_buf: [512]u8 = undefined;
    var tmp_buf:  [512]u8 = undefined;
    const path = try std.fmt.bufPrintZ(&path_buf, "{s}/keyframe-{d:0>8}.bin", .{ output_dir, id });
    const tmp  = try std.fmt.bufPrintZ(&tmp_buf,  "{s}/keyframe-{d:0>8}.tmp", .{ output_dir, id });
    {
        const fd = try openTrunc(tmp.ptr);
        defer _ = linux.close(fd);
        try writeAll(fd, kf_buf[0..len]);
    }
    if (sysErr(linux.rename(tmp.ptr, path.ptr)) < 0) return error.RenameFailed;

    {
        var idx_buf: [512]u8 = undefined;
        const idx_path = try std.fmt.bufPrintZ(&idx_buf, "{s}/keyframes.txt", .{output_dir});
        const fd = try openAppend(idx_path.ptr);
        defer _ = linux.close(fd);
        var line_buf: [128]u8 = undefined;
        const line = try std.fmt.bufPrint(&line_buf, "{d},{s}\n", .{ id, ts_str });
        try writeAll(fd, line);
    }

    // Prune the snapshot that has fallen out of the retention window.
    if (id >= KEYFRAME_KEEP) {
        var del_buf: [512]u8 = undefined;
        const del = std.fmt.bufPrintZ(&del_buf, "{s}/keyframe-{d:0>8}.bin", .{ output_dir, id - KEYFRAME_KEEP }) catch return;
        _ = linux.unlink(del.ptr);
    }
}

// Feed one log line (without trailing newline) through the terminal model, and
// emit a keyframe when KEYFRAME_INTERVAL_S of stream time has elapsed.
fn processLine(
    line: []const u8,
    output_dir: []const u8,
    kf_id: *u32,
    last_kf_ts: *f64,
    kf_buf: []u8,
) !void {
    if (std.mem.startsWith(u8, line, END_MARKER)) return;

    const prefix = "[pris ";
    if (!std.mem.startsWith(u8, line, prefix)) {
        term.processTsLine(line);
        return;
    }

    var i: usize = prefix.len;
    const ts_start = i;
    while (i < line.len and line[i] != ']') : (i += 1) {}
    const ts_str = line[ts_start..i];
    if (i < line.len) i += 1; // skip ']'
    if (i < line.len and line[i] == ' ') i += 1; // skip one separator space

    term.processTsLine(line[i..]);

    const ts = std.fmt.parseFloat(f64, ts_str) catch return;
    if (last_kf_ts.* == 0 or ts >= last_kf_ts.* + KEYFRAME_INTERVAL_S) {
        try writeKeyframe(output_dir, kf_id.*, ts_str, kf_buf);
        last_kf_ts.* = ts;
        kf_id.* += 1;
    }
}

pub fn main(init: std.process.Init.Minimal) !void {
    const alloc = std.heap.page_allocator;

    const argv = init.args.vector;
    if (argv.len != 3) {
        std.debug.print("usage: pris-chunk-writer <build_log> <output_dir>\n", .{});
        return error.InvalidArgs;
    }

    const build_log  = std.mem.span(argv[1]);
    const output_dir = std.mem.span(argv[2]);

    // Initialize the shared terminal grid (the WASM does this via init()).
    term.reset();

    var state = loadState(output_dir);

    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(alloc);

    // Separate line accumulator that drives the terminal model for keyframes,
    // independent of the size-based chunking above.
    var line_buf: std.ArrayList(u8) = .empty;
    defer line_buf.deinit(alloc);
    var kf_id: u32 = 0;
    var last_kf_ts: f64 = 0;
    var kf_buf: [term.KEYFRAME_MAX_BYTES]u8 = undefined;

    var read_buf: [65536]u8 = undefined;
    var idle_polls: u32 = 0;

    while (true) {
        const fd = openRead(build_log.ptr) catch {
            sleepNs(POLL_NS);
            continue;
        };
        _ = linux.lseek(fd, @intCast(state.offset + buf.items.len), linux.SEEK.SET);
        const rr = sysErr(linux.read(fd, &read_buf, read_buf.len));
        _ = linux.close(fd);
        if (rr < 0) {
            sleepNs(POLL_NS);
            continue;
        }
        const n: usize = @intCast(rr);

        if (n == 0) {
            idle_polls += 1;
            if (idle_polls >= IDLE_FLUSHES and buf.items.len > 0) {
                const ts = extractFirstTimestamp(buf.items);
                try writeChunk(output_dir, buf.items, state.chunk);
                try appendChunkTime(output_dir, state.chunk, ts);
                state.offset += buf.items.len;
                state.chunk  += 1;
                try saveState(output_dir, state.offset, state.chunk);
                buf.shrinkRetainingCapacity(0);
                idle_polls = 0;
            }
            sleepNs(POLL_NS);
            continue;
        }

        idle_polls = 0;
        try buf.appendSlice(alloc, read_buf[0..n]);

        // Drive the terminal model with each complete line, for keyframes.
        try line_buf.appendSlice(alloc, read_buf[0..n]);
        var ls: usize = 0;
        while (std.mem.indexOfScalarPos(u8, line_buf.items, ls, '\n')) |nl| {
            try processLine(line_buf.items[ls..nl], output_dir, &kf_id, &last_kf_ts, &kf_buf);
            ls = nl + 1;
        }
        if (ls > 0) {
            std.mem.copyForwards(u8, line_buf.items, line_buf.items[ls..]);
            line_buf.shrinkRetainingCapacity(line_buf.items.len - ls);
        }

        // End marker — flush everything and exit
        if (std.mem.indexOf(u8, buf.items, END_MARKER)) |idx| {
            const nl  = std.mem.indexOfScalarPos(u8, buf.items, idx, '\n');
            const end = if (nl) |i| i + 1 else idx + END_MARKER.len;
            buf.shrinkRetainingCapacity(end);

            while (buf.items.len >= CHUNK_SIZE) try flushChunk(output_dir, &buf, &state);

            if (buf.items.len > 0) {
                const ts = extractFirstTimestamp(buf.items);
                try writeChunk(output_dir, buf.items, state.chunk);
                try appendChunkTime(output_dir, state.chunk, ts);
                state.offset += buf.items.len;
                state.chunk  += 1;
                try saveState(output_dir, state.offset, state.chunk);
            }
            return;
        }

        while (buf.items.len >= CHUNK_SIZE) try flushChunk(output_dir, &buf, &state);
    }
}
