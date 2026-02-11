const std = @import("std");
const font = @import("font.zig");

// Font dimensions from generated font
pub const CHAR_W: u32 = font.FONT_W;
pub const LINE_H: u32 = font.FONT_H + 1; // Add 1px line spacing

// Display constants
pub const N_COLS: u32 = 80;
pub const N_ROWS: u32 = 24;
pub const TEXT_X: u32 = 8;
pub const TEXT_Y: u32 = 8;
pub const SCREEN_W: u32 = TEXT_X * 2 + CHAR_W * N_COLS;
pub const SCREEN_H: u32 = TEXT_Y * 2 + LINE_H * N_ROWS;

// Colors (RGB format)
pub const SCRN_RGB: u32 = 0x2B4D59;
pub const BORDER_RGB: u32 = 0x3A5C61;
pub const TEXT_RGB: u32 = 0xC0C0C0;
pub const BRIGHT_RGB: u32 = 0xBBFF82;
pub const CURSOR_RGB: u32 = 0xFF0000;

pub const N_FADE_STEPS: u32 = 25;

// Ring buffer for chunks
pub const NUM_BUFFERS: u32 = 4;
pub const MAX_CHUNK_SZ: u32 = 5 * N_COLS * N_ROWS;

const BufferState = enum(u8) { empty, ready, reading };

var chunk_buffers: [NUM_BUFFERS][MAX_CHUNK_SZ]u8 = undefined;
var buffer_lengths: [NUM_BUFFERS]u32 = .{ 0, 0, 0, 0 };
var buffer_states: [NUM_BUFFERS]BufferState = .{ .empty, .empty, .empty, .empty };
var read_buffer_idx: u32 = 0;
var read_pos: u32 = 0; // position within current buffer

// Timing
var manifest_start_ms: u64 = 0;
var manifest_duration_ms: u64 = 0;
var run_start_epoch_ms: u64 = 0;
var first_line_timestamp_ms: u64 = 0;
var have_first_timestamp: bool = false;
var reached_end: bool = false;

// Cursor
var cursor_visible: bool = true;
var last_cursor_toggle_ms: u64 = 0;
const CURSOR_BLINK_MS: u64 = 500;

// Pixel buffer (RGBA format for canvas)
var pixels: [SCREEN_W * SCREEN_H]u32 = undefined;

// Fade color table
var fade_colors: [N_FADE_STEPS]u32 = undefined;

// Screen state: lines of text with ages
const MAX_SCREEN_LINES: u32 = N_ROWS;
var screen_lines: [MAX_SCREEN_LINES][N_COLS]u8 = undefined;
var screen_line_lengths: [MAX_SCREEN_LINES]u32 = undefined;
var screen_line_ages: [MAX_SCREEN_LINES]u32 = undefined;
var num_screen_lines: u32 = 0;

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

fn drawBorder() void {
    const border = rgbToRgba(BORDER_RGB);
    for (0..SCREEN_W) |x| {
        pixels[x] = border;
        pixels[x + (SCREEN_H - 1) * SCREEN_W] = border;
    }
    for (0..SCREEN_H) |y| {
        pixels[y * SCREEN_W] = border;
        pixels[y * SCREEN_W + SCREEN_W - 1] = border;
    }
}

fn clearScreen() void {
    const rgba = rgbToRgba(SCRN_RGB);
    for (&pixels) |*p| {
        p.* = rgba;
    }
    drawBorder();
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

fn drawChar(c: u8, x: u32, y: u32, rgb: u32) void {
    if (c < 32 or c > 126) return;
    const idx: usize = c - 32;
    const char_data = font.font_data[idx];

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
}

fn drawString(s: []const u8, x: u32, y: u32, rgb: u32) void {
    var px = x;
    for (s) |c| {
        drawChar(c, px, y, rgb);
        px += CHAR_W;
    }
}

fn scrollUp() void {
    if (num_screen_lines == 0) return;
    for (0..MAX_SCREEN_LINES - 1) |i| {
        screen_line_lengths[i] = screen_line_lengths[i + 1];
        screen_line_ages[i] = screen_line_ages[i + 1];
        @memcpy(&screen_lines[i], &screen_lines[i + 1]);
    }
    num_screen_lines -= 1;
}

fn addScreenLine(text: []const u8) void {
    // Make room if needed
    while (num_screen_lines >= MAX_SCREEN_LINES) {
        scrollUp();
    }

    const copy_len = @min(text.len, N_COLS);
    @memcpy(screen_lines[num_screen_lines][0..copy_len], text[0..copy_len]);
    screen_line_lengths[num_screen_lines] = @intCast(copy_len);
    screen_line_ages[num_screen_lines] = 0;
    num_screen_lines += 1;
}

fn addLineWithWrap(text: []const u8) void {
    if (text.len == 0) {
        addScreenLine("");
        return;
    }

    var remaining = text;
    while (remaining.len > 0) {
        const chunk_len = @min(remaining.len, N_COLS);
        addScreenLine(remaining[0..chunk_len]);
        remaining = remaining[chunk_len..];
    }
}

const ParseResult = struct {
    timestamp_ms: u64,
    content_start: u32,
    content_end: u32,
    line_end: u32,
    is_end_signal: bool,
};

// Parse timestamp from: -=pr 1234567890.123456 is=-\ncontent
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

    // Look for -=pr prefix
    if (buf.len < 20 or !std.mem.eql(u8, buf[0..5], "-=pr ")) {
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

    // Parse seconds
    var i: u32 = 5;
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

    // Skip to " is=-\n"
    while (i < buf.len and buf[i] != '\n') : (i += 1) {}
    if (i < buf.len and buf[i] == '\n') i += 1;
    result.content_start = i;

    // Find end of content (next line or end of buffer)
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
            if (manifest_duration_ms > 0) {
                // Replay mode: reset for next loop
                resetForReplay();
            }
            break;
        }

        // Store first timestamp as baseline
        if (!have_first_timestamp and parsed.timestamp_ms > 0) {
            first_line_timestamp_ms = parsed.timestamp_ms;
            have_first_timestamp = true;
        }

        // Check if it's time to display this line
        if (parsed.timestamp_ms > 0 and have_first_timestamp) {
            const line_offset = parsed.timestamp_ms -| first_line_timestamp_ms;
            if (line_offset > run_elapsed) {
                break; // Not time yet
            }
        }

        // Display the line
        const content = chunk_buffers[read_buffer_idx][read_pos + parsed.content_start .. read_pos + parsed.content_end];
        addLineWithWrap(content);

        read_pos += parsed.line_end;
    }
}

fn resetForReplay() void {
    // Clear screen state
    num_screen_lines = 0;
    for (0..MAX_SCREEN_LINES) |i| {
        screen_line_lengths[i] = 0;
        screen_line_ages[i] = N_FADE_STEPS;
    }

    // Reset buffer reading
    read_buffer_idx = 0;
    read_pos = 0;
    for (0..NUM_BUFFERS) |i| {
        buffer_states[i] = .empty;
        buffer_lengths[i] = 0;
    }

    // Reset timing
    have_first_timestamp = false;
    first_line_timestamp_ms = 0;
    reached_end = false;
    run_start_epoch_ms = 0; // Will be set on next processFrame
}

fn renderScreen() void {
    // Clear text area
    fillRect(TEXT_X, TEXT_Y, CHAR_W * N_COLS, LINE_H * N_ROWS, SCRN_RGB);

    // Draw lines
    for (0..num_screen_lines) |i| {
        const line_len = screen_line_lengths[i];
        const age = screen_line_ages[i];
        const rgb = if (age >= N_FADE_STEPS) TEXT_RGB else fade_colors[age];
        const y = TEXT_Y + @as(u32, @intCast(i)) * LINE_H;
        drawString(screen_lines[i][0..line_len], TEXT_X, y, rgb);

        // Age the line
        if (screen_line_ages[i] < N_FADE_STEPS) {
            screen_line_ages[i] += 1;
        }
    }

    // Draw cursor
    if (cursor_visible and num_screen_lines > 0) {
        const last_idx = num_screen_lines - 1;
        const cursor_x = TEXT_X + screen_line_lengths[last_idx] * CHAR_W;
        const cursor_y = TEXT_Y + last_idx * LINE_H;
        for (0..font.FONT_H) |dy| {
            setPixel(cursor_x, cursor_y + @as(u32, @intCast(dy)), CURSOR_RGB);
        }
    }
}

// === Exports ===

export fn init() void {
    // Generate fade colors
    const br = (BRIGHT_RGB >> 16) & 0xFF;
    const bg = (BRIGHT_RGB >> 8) & 0xFF;
    const bb = BRIGHT_RGB & 0xFF;
    const tr = (TEXT_RGB >> 16) & 0xFF;
    const tg = (TEXT_RGB >> 8) & 0xFF;
    const tb = TEXT_RGB & 0xFF;

    for (0..N_FADE_STEPS) |i| {
        const t: u32 = @intCast(i);
        const r = lerp(br, tr, t, N_FADE_STEPS - 1);
        const g = lerp(bg, tg, t, N_FADE_STEPS - 1);
        const b = lerp(bb, tb, t, N_FADE_STEPS - 1);
        fade_colors[i] = (r << 16) | (g << 8) | b;
    }

    clearScreen();

    // Initialize screen lines
    num_screen_lines = 0;
    for (0..MAX_SCREEN_LINES) |i| {
        screen_line_lengths[i] = 0;
        screen_line_ages[i] = N_FADE_STEPS;
    }

    // Initialize buffers
    for (0..NUM_BUFFERS) |i| {
        buffer_states[i] = .empty;
        buffer_lengths[i] = 0;
    }
}

export fn initTiming(start_ms: u64, duration_ms: u64, now_ms: u64) void {
    manifest_start_ms = start_ms;
    manifest_duration_ms = duration_ms;
    run_start_epoch_ms = now_ms;
    have_first_timestamp = false;
    first_line_timestamp_ms = 0;
    reached_end = false;
}

export fn getWriteBufferPtr() [*]u8 {
    // Find first empty buffer
    for (0..NUM_BUFFERS) |i| {
        if (buffer_states[i] == .empty) {
            return &chunk_buffers[i];
        }
    }
    return &chunk_buffers[0]; // Fallback
}

export fn getWriteBufferIndex() u32 {
    for (0..NUM_BUFFERS) |i| {
        if (buffer_states[i] == .empty) {
            return @intCast(i);
        }
    }
    return 0;
}

export fn markBufferReady(index: u32, len: u32) void {
    if (index < NUM_BUFFERS) {
        buffer_lengths[index] = len;
        buffer_states[index] = .ready;
    }
}

export fn needsBuffer() bool {
    // Check if any buffer is empty and we haven't reached end
    if (reached_end and manifest_duration_ms == 0) return false;

    for (0..NUM_BUFFERS) |i| {
        if (buffer_states[i] == .empty) {
            return true;
        }
    }
    return false;
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

export fn getVersion() u32 {
    return 4;
}
