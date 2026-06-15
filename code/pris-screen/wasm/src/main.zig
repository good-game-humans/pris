const std = @import("std");
const font = @import("font");
const term = @import("terminal.zig");

// Font dimensions from generated font
pub const CHAR_W: u32 = font.FONT_W;
pub const LINE_H: u32 = font.FONT_H + 1; // Add 1px line spacing

// Display constants
pub const N_COLS: u32 = term.N_COLS;
pub const N_ROWS: u32 = term.N_ROWS;
pub const TEXT_X: u32 = 8;
pub const TEXT_Y: u32 = 8;
pub const SCREEN_W: u32 = TEXT_X * 2 + CHAR_W * N_COLS;
pub const SCREEN_H: u32 = TEXT_Y * 2 + LINE_H * N_ROWS;

const N_COLORS = term.N_COLORS;
const N_FADE_STEPS = term.N_FADE_STEPS;

// Bright (age=0) and normal (fully aged) RGB values per palette entry
const color_bright: [N_COLORS]u32 = .{
    0xBBFF82, // default
    0xFFFFFF, // bold
    0xFF5555, // red     (SGR 31)
    0x55FF55, // green   (SGR 32)
    0xFFFF55, // yellow  (SGR 33)
    0x6666FF, // blue    (SGR 34)
    0xFF55FF, // magenta (SGR 35)
    0x55FFFF, // cyan    (SGR 36)
    0xFFFFFF, // white   (SGR 37)
    0x555555, // black   (SGR 30)
    0xAAAAAA, // br_black  (SGR 90)
    0xFF8888, // br_red    (SGR 91)
    0x88FF88, // br_green  (SGR 92)
    0xFFFF88, // br_yellow (SGR 93)
    0x9999FF, // br_blue   (SGR 94)
    0xFF88FF, // br_magenta(SGR 95)
    0x88FFFF, // br_cyan   (SGR 96)
    0xFFFFFF, // br_white  (SGR 97)
    0x1793D1, // arch    (38;2;23;147;209)
};
const color_normal: [N_COLORS]u32 = .{
    0xCCCCCC, // default
    0xCCCCCC, // bold
    0xDD5555, // red     (SGR 31)
    0x55DD55, // green   (SGR 32)
    0xDDBB55, // yellow  (SGR 33)
    0x5555DD, // blue    (SGR 34)
    0xDD55DD, // magenta (SGR 35)
    0x55CCCC, // cyan    (SGR 36)
    0xCCCCCC, // white   (SGR 37)
    0x333333, // black   (SGR 30)
    0x888888, // br_black  (SGR 90)
    0xFF5555, // br_red    (SGR 91)
    0x55FF55, // br_green  (SGR 92)
    0xFFFF55, // br_yellow (SGR 93)
    0x6666FF, // br_blue   (SGR 94)
    0xFF55FF, // br_magenta(SGR 95)
    0x55FFFF, // br_cyan   (SGR 96)
    0xFFFFFF, // br_white  (SGR 97)
    0x1787C4, // arch    (38;2;23;147;209)
};

// Other colors (RGB format)
pub const SCRN_RGB: u32 = 0x1A2528;
pub const BORDER_RGB: u32 = 0x23322D;
pub const CURSOR_RGB: u32 = 0xCC0000;

// Rounded corner data (ported from original Java Pipe.java)
// Index 21 = outer background, index 22 = screen interior (SCRN_RGB)
const CORNER_W: u32 = 15;
const CORNER_H: u32 = 15;
const corner_pix: [CORNER_W * CORNER_H]u8 = .{
    21,21,21,21,21,21,21,21,21,11, 1, 0, 6, 9,14,
    21,21,21,21,21,21,21, 2, 7,18,10,20, 4, 5,12,
    21,21,21,21,21,21, 8,16,20,15,22,22,22,22,22,
    21,21,21,21,13, 0,17, 3,22,22,22,22,22,22,22,
    21,21,21,13,19,20,22,22,22,22,22,22,22,22,22,
    21,21,21, 0,20,22,22,22,22,22,22,22,22,22,22,
    21,21, 8,17,22,22,22,22,22,22,22,22,22,22,22,
    21, 2,16, 3,22,22,22,22,22,22,22,22,22,22,22,
    21, 7,20,22,22,22,22,22,22,22,22,22,22,22,22,
    11,18,15,22,22,22,22,22,22,22,22,22,22,22,22,
     1,10,22,22,22,22,22,22,22,22,22,22,22,22,22,
     0,20,22,22,22,22,22,22,22,22,22,22,22,22,22,
     6, 4,22,22,22,22,22,22,22,22,22,22,22,22,22,
     9, 5,22,22,22,22,22,22,22,22,22,22,22,22,22,
    14,12,22,22,22,22,22,22,22,22,22,22,22,22,22,
};
const corner_rgb: [23]u32 = .{
    0x202C2A, 0x1E2826, 0x1C2221, 0x1C2829, 0x1C2829, 0x1B2729,
    0x222F2B, 0x1F2B29, 0x1F2A28, 0x22312C, 0x202E2B, 0x1B1E1F,
    0x1B2628, 0x1B1E1E, 0x22312D, 0x1B2829, 0x22302C, 0x1F2D2B,
    0x22312C, 0x202E2B, 0x1E2B2A, 0x10181A, 0x1A2528,
};

// Ring buffer for chunks
pub const NUM_BUFFERS: u32 = 4;
pub const MAX_CHUNK_SZ: u32 = 1600;

const BufferState = enum(u8) { empty, ready, reading };

var chunk_buffers: [NUM_BUFFERS][MAX_CHUNK_SZ]u8 = undefined;
var buffer_lengths: [NUM_BUFFERS]u32 = .{ 0, 0, 0, 0 };
var buffer_states: [NUM_BUFFERS]BufferState = .{ .empty, .empty, .empty, .empty };
var read_buffer_idx: u32 = 0;
var write_buffer_idx: u32 = 0;
var read_pos: u32 = 0; // position within current buffer

// Keyframe: a connect-time screen prime. The client writes a serialized grid
// into keyframe_buf and calls loadKeyframe; keyframe_ms is then the stream time
// the keyframe represents, so already-captured lines are skipped during replay.
var keyframe_buf: [term.KEYFRAME_MAX_BYTES]u8 = undefined;
var keyframe_ms: u64 = 0;

// Timing
var manifest_start_ms: u64 = 0;
var manifest_duration_ms: u64 = 0;
var run_start_epoch_ms: u64 = 0;
var reached_end: bool = false;

// Cursor (blink)
var cursor_visible: bool = true;
var last_cursor_toggle_ms: u64 = 0;
const CURSOR_BLINK_MS: u64 = 500;

// Pixel buffer (RGBA format for canvas)
var pixels: [SCREEN_W * SCREEN_H]u32 = undefined;

// Per-color fade tables: [Color][fade_step] -> RGB
var fade_colors: [N_COLORS][N_FADE_STEPS]u32 = undefined;

fn lerp(a: u32, b: u32, t: u32, steps: u32) u32 {
    if (steps == 0) return a;
    if (a >= b) {
        return a - (a - b) * t / steps;
    } else {
        return a + (b - a) * t / steps;
    }
}

fn rgbToRgba(rgb: u32) u32 {
    const r = (rgb >> 16) & 0xFF;
    const g = (rgb >> 8) & 0xFF;
    const b = rgb & 0xFF;
    return 0xFF000000 | (b << 16) | (g << 8) | r;
}

fn drawCorners() void {
    // Paint all 4 corners by mirroring the top-left corner data
    for (0..CORNER_H) |y| {
        for (0..CORNER_W) |x| {
            const rgb = corner_rgb[corner_pix[y * CORNER_W + x]];
            const px = @as(u32, @intCast(x));
            const py = @as(u32, @intCast(y));
            setPixel(px,             py,             rgb); // top-left
            setPixel(SCREEN_W-1-px,  py,             rgb); // top-right
            setPixel(px,             SCREEN_H-1-py,  rgb); // bottom-left
            setPixel(SCREEN_W-1-px,  SCREEN_H-1-py,  rgb); // bottom-right
        }
    }
    // Straight border edges between corners
    const border = rgbToRgba(BORDER_RGB);
    for (CORNER_W..SCREEN_W - CORNER_W) |x| {
        pixels[x] = border;
        pixels[x + (SCREEN_H - 1) * SCREEN_W] = border;
    }
    for (CORNER_H..SCREEN_H - CORNER_H) |y| {
        pixels[y * SCREEN_W] = border;
        pixels[y * SCREEN_W + SCREEN_W - 1] = border;
    }
}

fn clearScreen() void {
    const rgba = rgbToRgba(SCRN_RGB);
    for (&pixels) |*p| {
        p.* = rgba;
    }
    drawCorners();
}

fn blendPixel(x: u32, y: u32, rgb: u32, alpha: u8) void {
    if (x >= SCREEN_W or y >= SCREEN_H) return;
    if (alpha == 0) return;

    const idx = y * SCREEN_W + x;
    const bg = pixels[idx];

    if (alpha == 255) {
        pixels[idx] = rgbToRgba(rgb);
        return;
    }

    const fr = (rgb >> 16) & 0xFF;
    const fg = (rgb >> 8) & 0xFF;
    const fb = rgb & 0xFF;
    const br = bg & 0xFF;
    const bbg = (bg >> 8) & 0xFF;
    const bb = (bg >> 16) & 0xFF;

    const a: u32 = alpha;
    const inv_a: u32 = 255 - a;
    const nr = (fr * a + br * inv_a) / 255;
    const ng = (fg * a + bbg * inv_a) / 255;
    const nb = (fb * a + bb * inv_a) / 255;

    pixels[idx] = 0xFF000000 | (nb << 16) | (ng << 8) | nr;
}

fn setPixel(x: u32, y: u32, rgb: u32) void {
    if (x >= SCREEN_W or y >= SCREEN_H) return;
    pixels[y * SCREEN_W + x] = rgbToRgba(rgb);
}

fn fillRect(x: u32, y: u32, w: u32, h: u32, rgb: u32) void {
    const rgba = rgbToRgba(rgb);
    var py = y;
    while (py < y + h and py < SCREEN_H) : (py += 1) {
        var px = x;
        while (px < x + w and px < SCREEN_W) : (px += 1) {
            pixels[py * SCREEN_W + px] = rgba;
        }
    }
}

fn drawChar(c: u8, x: u32, y: u32, rgb: u32, bold: bool) void {
    const is_box = c >= term.BOX_BASE and c < term.BOX_BASE + term.N_BOX_GLYPHS;
    const idx: usize = if (is_box)
        term.FIRST_BOX_GLYPH + (c - term.BOX_BASE)
    else if (c >= 32 and c <= 126)
        c - 32
    else
        return;
    const char_data = if (bold) font.font_data_bold[idx] else font.font_data[idx];

    for (0..font.FONT_H) |row| {
        for (0..font.FONT_W) |col| {
            const alpha = char_data[row][col];
            if (alpha > 0) {
                blendPixel(
                    x + @as(u32, @intCast(col)),
                    y + @as(u32, @intCast(row)),
                    rgb,
                    alpha,
                );
            }
        }
    }

    // Rows are drawn LINE_H (= FONT_H + 1) apart, so a 1px line-spacing gap sits
    // below each glyph. For box rules that would break vertical connections, so
    // repeat the glyph's bottom row into that gap. Only down-connecting glyphs
    // have ink in their bottom row, leaving horizontals/up-corners untouched.
    if (is_box) {
        const last = font.FONT_H - 1;
        for (0..font.FONT_W) |col| {
            const alpha = char_data[last][col];
            if (alpha > 0) {
                blendPixel(x + @as(u32, @intCast(col)), y + font.FONT_H, rgb, alpha);
            }
        }
    }
}

// --- Timestamp / buffer parsing ---

const ParseResult = struct {
    timestamp_ms: u64,
    content_start: u32,
    content_end: u32,
    line_end: u32,
    is_end_signal: bool,
};

// Parse timestamp from: [pris 1234567890.123456]  content\n
fn parseLine(buf: []const u8) ParseResult {
    var result = ParseResult{
        .timestamp_ms = 0,
        .content_start = 0,
        .content_end = 0,
        .line_end = 0,
        .is_end_signal = false,
    };

    // Check for end signal
    if (buf.len >= 7 and std.mem.eql(u8, buf[0..7], "-=END=-")) {
        result.is_end_signal = true;
        result.line_end = 7;
        if (buf.len > 7 and buf[7] == '\n') result.line_end = 8;
        return result;
    }

    // Look for [pris prefix
    if (buf.len < 10 or !std.mem.eql(u8, buf[0..6], "[pris ")) {
        // Not a timestamp line, find end of line
        for (buf, 0..) |c, i| {
            if (c == '\n') {
                result.content_end = @intCast(i);
                result.line_end = @intCast(i + 1);
                return result;
            }
        }
        result.content_end = @intCast(buf.len);
        result.line_end = @intCast(buf.len);
        return result;
    }

    // Parse seconds (starting after "[pris ")
    var i: u32 = 6;
    var secs: u64 = 0;
    while (i < buf.len and buf[i] >= '0' and buf[i] <= '9') : (i += 1) {
        secs = secs * 10 + (buf[i] - '0');
    }

    // Parse fractional part
    var frac: u64 = 0;
    var frac_digits: u32 = 0;
    if (i < buf.len and buf[i] == '.') {
        i += 1;
        while (i < buf.len and buf[i] >= '0' and buf[i] <= '9') : (i += 1) {
            if (frac_digits < 3) { // only need ms precision
                frac = frac * 10 + (buf[i] - '0');
                frac_digits += 1;
            }
        }
        // Pad to 3 digits
        while (frac_digits < 3) : (frac_digits += 1) {
            frac *= 10;
        }
    }

    result.timestamp_ms = secs * 1000 + frac;

    // Skip to ']' then skip spaces — content follows on the same line
    while (i < buf.len and buf[i] != ']') : (i += 1) {}
    if (i < buf.len and buf[i] == ']') i += 1;
    if (i < buf.len and buf[i] == ' ') i += 1; // skip single separator space
    result.content_start = i;

    // Find end of content (newline or end of buffer)
    while (i < buf.len and buf[i] != '\n') : (i += 1) {}
    result.content_end = i;
    if (i < buf.len and buf[i] == '\n') i += 1;
    result.line_end = i;

    return result;
}

fn getRunElapsed(now_ms: u64) u64 {
    var elapsed = now_ms -| run_start_epoch_ms;
    if (manifest_duration_ms > 0) {
        elapsed = elapsed % manifest_duration_ms;
    }
    return elapsed;
}

fn processPendingLines(now_ms: u64) void {
    const run_elapsed = getRunElapsed(now_ms);

    while (true) {
        // Check if current buffer has data
        if (buffer_states[read_buffer_idx] != .ready and buffer_states[read_buffer_idx] != .reading) {
            break;
        }

        if (buffer_states[read_buffer_idx] == .ready) {
            buffer_states[read_buffer_idx] = .reading;
        }

        const buf_len = buffer_lengths[read_buffer_idx];
        if (read_pos >= buf_len) {
            // Buffer exhausted, move to next
            buffer_states[read_buffer_idx] = .empty;
            read_buffer_idx = (read_buffer_idx + 1) % NUM_BUFFERS;
            read_pos = 0;
            continue;
        }

        const buf = chunk_buffers[read_buffer_idx][read_pos..buf_len];
        const parsed = parseLine(buf);

        if (parsed.is_end_signal) {
            reached_end = true;
            read_pos += parsed.line_end;
            break;
        }

        // Skip lines already captured by a loaded keyframe.
        if (keyframe_ms > 0 and parsed.timestamp_ms > 0 and parsed.timestamp_ms <= keyframe_ms) {
            read_pos += parsed.line_end;
            continue;
        }

        // Check if it's time to display this line
        if (parsed.timestamp_ms > 0) {
            const line_offset = parsed.timestamp_ms -| manifest_start_ms;
            if (line_offset > run_elapsed) {
                break; // Not time yet
            }
        }

        // Feed the line through the terminal emulator.
        const content = chunk_buffers[read_buffer_idx][read_pos + parsed.content_start .. read_pos + parsed.content_end];
        term.processTsLine(content);

        read_pos += parsed.line_end;
    }
}

fn resetForReplay() void {
    term.reset();

    read_buffer_idx = 0;
    write_buffer_idx = 0;
    read_pos = 0;
    for (0..NUM_BUFFERS) |i| {
        buffer_states[i] = .empty;
        buffer_lengths[i] = 0;
    }

    reached_end = false;
    run_start_epoch_ms = 0; // Will be set on next processFrame
    keyframe_ms = 0;
}

export fn resetReplay() void {
    resetForReplay();
}

fn renderScreen() void {
    // Clear text area
    fillRect(TEXT_X, TEXT_Y, CHAR_W * N_COLS + 1, LINE_H * N_ROWS, SCRN_RGB);

    // Paint from the display grid — the last presented (complete) frame.
    for (0..term.disp_num) |i| {
        const line_len = term.disp_lengths[i];
        const age = term.disp_ages[i];
        const y = TEXT_Y + @as(u32, @intCast(i)) * LINE_H;

        for (0..line_len) |j| {
            const ci = @intFromEnum(term.disp_colors[i][j]);
            const rgb = if (age >= N_FADE_STEPS)
                color_normal[ci]
            else
                fade_colors[ci][age];
            drawChar(term.disp_lines[i][j], TEXT_X + @as(u32, @intCast(j)) * CHAR_W, y, rgb, term.disp_bold[i][j]);
        }
    }

    // Advance fade ages each frame (fade only ever begins on scroll). The work
    // grid drives present(); the display grid is what's painted between presents,
    // so both must tick for the fade to animate smoothly rather than freeze
    // until the next line arrives.
    for (0..term.num_screen_lines) |i| {
        if (term.screen_line_ages[i] < N_FADE_STEPS) term.screen_line_ages[i] += 1;
    }
    for (0..term.disp_num) |i| {
        if (term.disp_ages[i] < N_FADE_STEPS) term.disp_ages[i] += 1;
    }

    // Draw the cursor at the presented position.
    if (cursor_visible) {
        const col = @min(term.disp_cursor_col, N_COLS);
        const cursor_x = TEXT_X + col * CHAR_W;
        const cursor_y = TEXT_Y + term.disp_cursor_row * LINE_H;
        for (0..font.FONT_H) |dy| {
            setPixel(cursor_x, cursor_y + @as(u32, @intCast(dy)), CURSOR_RGB);
        }
    }
}

// === Exports ===

export fn init() void {
    // Generate per-color fade tables
    for (0..N_COLORS) |ci| {
        const bright = color_bright[ci];
        const normal = color_normal[ci];
        const br = (bright >> 16) & 0xFF;
        const bg_c = (bright >> 8) & 0xFF;
        const bb = bright & 0xFF;
        const nr = (normal >> 16) & 0xFF;
        const ng = (normal >> 8) & 0xFF;
        const nb = normal & 0xFF;
        for (0..N_FADE_STEPS) |step| {
            const t: u32 = @intCast(step);
            const r = lerp(br, nr, t, N_FADE_STEPS - 1);
            const g = lerp(bg_c, ng, t, N_FADE_STEPS - 1);
            const b = lerp(bb, nb, t, N_FADE_STEPS - 1);
            fade_colors[ci][step] = (r << 16) | (g << 8) | b;
        }
    }

    clearScreen();

    term.reset();
    term.unknown_color_encountered = false;

    for (0..NUM_BUFFERS) |i| {
        buffer_states[i] = .empty;
        buffer_lengths[i] = 0;
    }
    read_buffer_idx = 0;
    write_buffer_idx = 0;
    read_pos = 0;
    keyframe_ms = 0;
}

export fn initTiming(start_ms: u64, duration_ms: u64, now_ms: u64) void {
    manifest_start_ms = start_ms;
    manifest_duration_ms = duration_ms;
    run_start_epoch_ms = now_ms;
    reached_end = false;
}

export fn getWriteBufferPtr() [*]u8 {
    return &chunk_buffers[write_buffer_idx];
}

export fn getWriteBufferIndex() u32 {
    return write_buffer_idx;
}

export fn markBufferReady(index: u32, len: u32) void {
    if (index < NUM_BUFFERS) {
        buffer_lengths[index] = len;
        buffer_states[index] = .ready;
        write_buffer_idx = (write_buffer_idx + 1) % NUM_BUFFERS;
    }
}

export fn needsBuffer() bool {
    if (reached_end) return false;
    return buffer_states[write_buffer_idx] == .empty;
}

export fn processFrame(now_ms: u64) void {
    // Initialize run start if not set
    if (run_start_epoch_ms == 0) {
        run_start_epoch_ms = now_ms;
    }

    // Toggle cursor
    if (now_ms - last_cursor_toggle_ms >= CURSOR_BLINK_MS) {
        cursor_visible = !cursor_visible;
        last_cursor_toggle_ms = now_ms;
    }

    // Process lines based on timing
    processPendingLines(now_ms);

    // Render
    renderScreen();
}

export fn getPixelBuffer() [*]u32 {
    return &pixels;
}

export fn getBufferSize() u32 {
    return SCREEN_W * SCREEN_H * 4;
}

export fn getScreenWidth() u32 {
    return SCREEN_W;
}

export fn getScreenHeight() u32 {
    return SCREEN_H;
}

export fn getMaxChunkSize() u32 {
    return MAX_CHUNK_SZ;
}

// --- Keyframe prime (connect-time full screen) ---

export fn getKeyframeBufferPtr() [*]u8 {
    return &keyframe_buf;
}

export fn getKeyframeMaxBytes() u32 {
    return @intCast(keyframe_buf.len);
}

// Load a serialized keyframe (already written into keyframe_buf) and record the
// stream time it represents so earlier lines are skipped during replay.
export fn loadKeyframe(len: u32, kf_ms: u64) void {
    term.loadKeyframe(keyframe_buf[0..len]);
    keyframe_ms = kf_ms;
}

export fn hadUnknownColor() bool {
    return term.unknown_color_encountered;
}

export fn getVersion() u32 {
    return 8;
}
