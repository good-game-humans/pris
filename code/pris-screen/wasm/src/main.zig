const std = @import("std");
const font = @import("font");
const build_options = @import("build_options");

// Font dimensions from generated font
pub const CHAR_W: u32 = font.FONT_W;
pub const LINE_H: u32 = font.FONT_H + 1; // Add 1px line spacing

// Display constants
pub const N_COLS: u32 = build_options.n_cols;
pub const N_ROWS: u32 = build_options.n_rows;
pub const TEXT_X: u32 = 8;
pub const TEXT_Y: u32 = 8;
pub const SCREEN_W: u32 = TEXT_X * 2 + CHAR_W * N_COLS;
pub const SCREEN_H: u32 = TEXT_Y * 2 + LINE_H * N_ROWS;

// Color palette
const Color = enum(u8) {
    default    = 0,
    bold       = 1,
    red        = 2,   // SGR 31
    green      = 3,   // SGR 32
    yellow     = 4,   // SGR 33
    blue       = 5,   // SGR 34
    magenta    = 6,   // SGR 35
    cyan       = 7,   // SGR 36
    white      = 8,   // SGR 37
    black      = 9,   // SGR 30
    br_black   = 10,  // SGR 90
    br_red     = 11,  // SGR 91
    br_green   = 12,  // SGR 92
    br_yellow  = 13,  // SGR 93
    br_blue    = 14,  // SGR 94
    br_magenta = 15,  // SGR 95
    br_cyan    = 16,  // SGR 96
    br_white   = 17,  // SGR 97
    arch       = 18,  // SGR 38;2;23;147;209
};
const N_COLORS = @typeInfo(Color).@"enum".fields.len;

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

pub const N_FADE_STEPS: u32 = 25;

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

// Timing
var manifest_start_ms: u64 = 0;
var manifest_duration_ms: u64 = 0;
var run_start_epoch_ms: u64 = 0;
var reached_end: bool = false;
var last_status_line_count: u32 = 0;

// Cursor
var cursor_visible: bool = true;
var last_cursor_toggle_ms: u64 = 0;
const CURSOR_BLINK_MS: u64 = 500;

// Pending command: set when a "[pris:/dir]> " prompt line is seen; the next
// line gets appended to the "> " line rather than added as a new one.
var pending_command: bool = false;

// Pixel buffer (RGBA format for canvas)
var pixels: [SCREEN_W * SCREEN_H]u32 = undefined;

// Per-color fade tables: [Color][fade_step] -> RGB
var fade_colors: [N_COLORS][N_FADE_STEPS]u32 = undefined;

// Set when an unrecognised true-color RGB is encountered during parsing
var unknown_color_encountered: bool = false;

// Screen state: lines of text with per-character color and ages
const MAX_SCREEN_LINES: u32 = N_ROWS;
var screen_lines: [MAX_SCREEN_LINES][N_COLS]u8 = undefined;
var screen_line_colors: [MAX_SCREEN_LINES][N_COLS]Color = undefined;
var screen_line_bold: [MAX_SCREEN_LINES][N_COLS]bool = undefined;
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
    if (c < 32 or c > 126) return;
    const idx: usize = c - 32;
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
}

// --- ANSI escape sequence parsing ---

// Parse semicolon-separated SGR params and update cur_color / cur_bold.
fn parseSgr(params: []const u8, cur_color: *Color, cur_bold: *bool) void {
    var nums: [8]u32 = .{ 0, 0, 0, 0, 0, 0, 0, 0 };
    var num_count: usize = 0;
    var cur: u32 = 0;
    var has_digit = false;

    for (params) |c| {
        if (c >= '0' and c <= '9') {
            cur = cur * 10 + (c - '0');
            has_digit = true;
        } else if (c == ';') {
            if (num_count < 8) {
                nums[num_count] = cur;
                num_count += 1;
            }
            cur = 0;
            has_digit = false;
        }
    }
    if (has_digit and num_count < 8) {
        nums[num_count] = cur;
        num_count += 1;
    }
    // Empty params (e.g. ESC [ m) treated as a single 0 = reset
    if (num_count == 0) {
        nums[0] = 0;
        num_count = 1;
    }

    var i: usize = 0;
    while (i < num_count) : (i += 1) {
        switch (nums[i]) {
            0 => {
                cur_color.* = .default;
                cur_bold.* = false;
            },
            1 => cur_bold.* = true,
            22 => cur_bold.* = false,
            30 => cur_color.* = .black,
            31 => cur_color.* = .red,
            32 => cur_color.* = .green,
            33 => cur_color.* = .yellow,
            34 => cur_color.* = .blue,
            35 => cur_color.* = .magenta,
            36 => cur_color.* = .cyan,
            37 => cur_color.* = .white,
            39 => cur_color.* = if (cur_bold.*) .bold else .default,
            90 => cur_color.* = .br_black,
            91 => cur_color.* = .br_red,
            92 => cur_color.* = .br_green,
            93 => cur_color.* = .br_yellow,
            94 => cur_color.* = .br_blue,
            95 => cur_color.* = .br_magenta,
            96 => cur_color.* = .br_cyan,
            97 => cur_color.* = .br_white,
            38 => {
                // 38;2;R;G;B — 24-bit true color foreground
                if (i + 4 < num_count and nums[i + 1] == 2) {
                    const r = nums[i + 2];
                    const g = nums[i + 3];
                    const b = nums[i + 4];
                    if (r == 23 and g == 147 and b == 209) {
                        cur_color.* = .arch;
                    } else {
                        unknown_color_encountered = true;
                        cur_color.* = .default;
                    }
                    i += 4;
                }
            },
            else => {},
        }
    }
}

// Handle a single decoded CSI sequence, updating column, color, and line buffers.
fn handleCsi(
    cmd: u8,
    params: []const u8,
    col: *u32,
    cur_color: *Color,
    cur_bold: *bool,
    chars: *[N_COLS]u8,
    colors: *[N_COLS]Color,
) void {
    switch (cmd) {
        'm' => parseSgr(params, cur_color, cur_bold),
        'G' => {
            // Cursor to column N (1-based); ESC[G and ESC[1G both move to column 0
            var n: u32 = 0;
            var has_digit = false;
            for (params) |c| {
                if (c >= '0' and c <= '9') {
                    n = n * 10 + (c - '0');
                    has_digit = true;
                } else break;
            }
            const col_1based = if (has_digit and n > 0) n else 1;
            col.* = col_1based - 1;
        },
        'K' => {
            // Erase in line: 0 (default) = cursor to end, 2 = entire line
            var n: u32 = 0;
            var has_digit = false;
            for (params) |c| {
                if (c >= '0' and c <= '9') {
                    n = n * 10 + (c - '0');
                    has_digit = true;
                } else break;
            }
            const mode = if (has_digit) n else 0;
            if (mode == 2) {
                @memset(chars, ' ');
                @memset(colors, Color.default);
                col.* = 0;
            } else {
                // mode 0: erase from cursor to end
                var j = col.*;
                while (j < N_COLS) : (j += 1) {
                    chars[j] = ' ';
                    colors[j] = .default;
                }
            }
        },
        // All other commands (J, H, n, h, p, etc.) are ignored
        else => {},
    }
}

const ColorState = struct {
    color: Color = .default,
    bold: bool = false,
};

// Process raw content bytes containing ANSI escape sequences into parallel
// char and Color arrays of length N_COLS. Trailing spaces are trimmed.
// Sets out_raw_consumed to the number of raw bytes consumed; stops at N_COLS
// visible characters so the caller can wrap by re-invoking with the remainder.
// color_state is read on entry and updated on exit, allowing callers to carry
// color across multiple wrapped segments of the same logical line.
fn processContent(
    raw: []const u8,
    out_chars: *[N_COLS]u8,
    out_colors: *[N_COLS]Color,
    out_bold: *[N_COLS]bool,
    out_len: *u32,
    out_raw_consumed: *u32,
    color_state: *ColorState,
) void {
    @memset(out_chars, ' ');
    @memset(out_colors, Color.default);
    @memset(out_bold, false);

    var col: u32 = 0;
    var cur_color: Color = color_state.color;
    var cur_bold: bool = color_state.bold;
    var i: usize = 0;

    while (i < raw.len) {
        const c = raw[i];
        if (c == 0x1b) {
            if (i + 1 < raw.len) {
                switch (raw[i + 1]) {
                    '[' => {
                        // CSI sequence: scan for final byte (0x40–0x7E)
                        i += 2;
                        const seq_start = i;
                        while (i < raw.len) {
                            const sc = raw[i];
                            if (sc >= 0x40 and sc <= 0x7E) {
                                handleCsi(sc, raw[seq_start..i], &col, &cur_color, &cur_bold, out_chars, out_colors);
                                i += 1;
                                break;
                            }
                            i += 1;
                        }
                    },
                    ']' => {
                        // OSC sequence: skip to BEL (0x07) or ST (ESC \)
                        i += 2;
                        while (i < raw.len) {
                            if (raw[i] == 0x07) {
                                i += 1;
                                break;
                            } else if (raw[i] == 0x1b and i + 1 < raw.len and raw[i + 1] == '\\') {
                                i += 2;
                                break;
                            }
                            i += 1;
                        }
                    },
                    'P' => {
                        // DCS sequence: skip to ST (ESC \)
                        i += 2;
                        while (i < raw.len) {
                            if (raw[i] == 0x1b and i + 1 < raw.len and raw[i + 1] == '\\') {
                                i += 2;
                                break;
                            }
                            i += 1;
                        }
                    },
                    else => i += 2, // unknown escape sequence: skip ESC + next byte
                }
            } else {
                i += 1;
            }
        } else if (c == '\r') {
            col = 0;
            i += 1;
        } else if (c < 32) {
            // Skip other control characters
            i += 1;
        } else {
            if (col < N_COLS) {
                out_chars[col] = c;
                out_colors[col] = cur_color;
                out_bold[col] = cur_bold;
                col += 1;
                i += 1;
            } else {
                // Line full — stop here so caller can wrap
                out_raw_consumed.* = @intCast(i);
                color_state.color = cur_color;
                color_state.bold = cur_bold;
                var len: u32 = N_COLS;
                while (len > 0 and out_chars[len - 1] == ' ') len -= 1;
                out_len.* = len;
                return;
            }
        }
    }

    out_raw_consumed.* = @intCast(raw.len);
    color_state.color = cur_color;
    color_state.bold = cur_bold;
    // Trim trailing spaces (start from N_COLS, not col, to handle \r resets correctly)
    var len: u32 = N_COLS;
    while (len > 0 and out_chars[len - 1] == ' ') {
        len -= 1;
    }
    out_len.* = len;
}

// --- Screen line management ---

fn scrollUp() void {
    if (num_screen_lines == 0) return;
    for (0..MAX_SCREEN_LINES - 1) |i| {
        screen_line_lengths[i] = screen_line_lengths[i + 1];
        screen_line_ages[i] = screen_line_ages[i + 1];
        @memcpy(&screen_lines[i], &screen_lines[i + 1]);
        @memcpy(&screen_line_colors[i], &screen_line_colors[i + 1]);
        @memcpy(&screen_line_bold[i], &screen_line_bold[i + 1]);
    }
    num_screen_lines -= 1;
}

fn addScreenLine(chars: []const u8, colors: []const Color, bolds: []const bool) void {
    while (num_screen_lines >= MAX_SCREEN_LINES) {
        scrollUp();
    }
    const copy_len = @min(chars.len, N_COLS);
    @memcpy(screen_lines[num_screen_lines][0..copy_len], chars[0..copy_len]);
    @memcpy(screen_line_colors[num_screen_lines][0..copy_len], colors[0..copy_len]);
    @memcpy(screen_line_bold[num_screen_lines][0..copy_len], bolds[0..copy_len]);
    screen_line_lengths[num_screen_lines] = @intCast(copy_len);
    screen_line_ages[num_screen_lines] = 0;
    num_screen_lines += 1;
}

fn appendToLastScreenLine(chars: []const u8, colors: []const Color, bolds: []const bool) void {
    if (num_screen_lines == 0) return;
    const idx = num_screen_lines - 1;
    var col = screen_line_lengths[idx];
    for (chars, colors, bolds) |c, color, bold| {
        if (col >= N_COLS) break;
        screen_lines[idx][col] = c;
        screen_line_colors[idx][col] = color;
        screen_line_bold[idx][col] = bold;
        col += 1;
    }
    screen_line_lengths[idx] = @min(col, N_COLS);
    screen_line_ages[idx] = 0;
}

fn addLineWithWrap(raw: []const u8) void {
    // Detect command prompt: a line containing "[pris:/dir]" followed by "> "
    // Split into two visual lines: "...[pris:/dir]" and "> ", then set
    // pending_command so the next log entry is appended after the "> ".
    if (std.mem.indexOf(u8, raw, "[pris:")) |pi| {
        var split: usize = pi + 6;
        while (split < raw.len and raw[split] != ']') : (split += 1) {}
        if (split < raw.len) {
            var proc_chars: [N_COLS]u8 = undefined;
            var proc_colors: [N_COLS]Color = undefined;
            var proc_bolds: [N_COLS]bool = undefined;
            var proc_len: u32 = 0;
            var consumed: u32 = 0;
            var prompt_state = ColorState{};
            processContent(raw[0 .. split + 1], &proc_chars, &proc_colors, &proc_bolds, &proc_len, &consumed, &prompt_state);
            addScreenLine(proc_chars[0..proc_len], proc_colors[0..proc_len], proc_bolds[0..proc_len]);

            // Parse content after ']' to get actual '>' color
            var gt_color: Color = .default;
            var gt_bold: bool = false;
            if (split + 1 < raw.len) {
                var gt_chars: [N_COLS]u8 = undefined;
                var gt_colors: [N_COLS]Color = undefined;
                var gt_bolds: [N_COLS]bool = undefined;
                var gt_len: u32 = 0;
                var gt_consumed: u32 = 0;
                var gt_state = ColorState{};
                processContent(raw[split + 1 ..], &gt_chars, &gt_colors, &gt_bolds, &gt_len, &gt_consumed, &gt_state);
                if (gt_len > 0) gt_color = gt_colors[0];
                if (gt_len > 0) gt_bold = gt_bolds[0];
            }
            const prompt_line_chars: [2]u8 = .{ '>', ' ' };
            const prompt_line_colors: [2]Color = .{ gt_color, .default };
            const prompt_line_bolds: [2]bool = .{ gt_bold, false };
            addScreenLine(&prompt_line_chars, &prompt_line_colors, &prompt_line_bolds);

            pending_command = true;
            return;
        }
    }

    var proc_chars: [N_COLS]u8 = undefined;
    var proc_colors: [N_COLS]Color = undefined;
    var proc_bolds: [N_COLS]bool = undefined;
    var proc_len: u32 = 0;

    if (pending_command) {
        var consumed: u32 = 0;
        var cmd_state = ColorState{};
        processContent(raw, &proc_chars, &proc_colors, &proc_bolds, &proc_len, &consumed, &cmd_state);
        appendToLastScreenLine(proc_chars[0..proc_len], proc_colors[0..proc_len], proc_bolds[0..proc_len]);
        pending_command = false;
        return;
    }

    var offset: usize = 0;
    var color_state = ColorState{};
    while (offset < raw.len) {
        var consumed: u32 = 0;
        processContent(raw[offset..], &proc_chars, &proc_colors, &proc_bolds, &proc_len, &consumed, &color_state);
        addScreenLine(proc_chars[0..proc_len], proc_colors[0..proc_len], proc_bolds[0..proc_len]);
        if (consumed == 0) break;
        offset += @as(usize, consumed);
    }
}

// --- Timestamp / buffer parsing (unchanged) ---

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
    while (i < buf.len and buf[i] == ' ') : (i += 1) {}
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
            if (manifest_duration_ms > 0) {
                // Replay mode: reset for next loop
                resetForReplay();
            }
            break;
        }

        // Check if it's time to display this line
        if (parsed.timestamp_ms > 0) {
            const line_offset = parsed.timestamp_ms -| manifest_start_ms;
            if (line_offset > run_elapsed) {
                break; // Not time yet
            }
        }

        // Display the line
        const content = chunk_buffers[read_buffer_idx][read_pos + parsed.content_start .. read_pos + parsed.content_end];
        if (std.mem.startsWith(u8, content, "COMPILATION COMPLETE")) {
            if (last_status_line_count > 0 and num_screen_lines >= last_status_line_count) {
                num_screen_lines -= last_status_line_count;
            }

            const left = "COMPILATION COMPLETE";

            // Find right portion after the whitespace gap
            var right_start: usize = left.len;
            while (right_start < content.len and content[right_start] == ' ') : (right_start += 1) {}
            const right = std.mem.trimRight(u8, content[right_start..], " \r\n");

            // Build a right-aligned N_COLS-wide screen line
            var line_chars:  [N_COLS]u8    = [_]u8{' '}         ** N_COLS;
            var line_colors: [N_COLS]Color = [_]Color{.default} ** N_COLS;
            var line_bolds:  [N_COLS]bool  = [_]bool{false}     ** N_COLS;

            const left_len = @min(left.len, N_COLS);
            @memcpy(line_chars[0..left_len], left[0..left_len]);

            if (right.len > 0 and right.len <= N_COLS) {
                const right_pos = N_COLS - right.len;
                @memcpy(line_chars[right_pos..], right);
            }

            addScreenLine(&line_chars, &line_colors, &line_bolds);
            last_status_line_count = 1;
        } else {
            last_status_line_count = 0;
            addLineWithWrap(content);
        }

        read_pos += parsed.line_end;
    }
}

fn resetForReplay() void {
    num_screen_lines = 0;
    for (0..MAX_SCREEN_LINES) |i| {
        screen_line_lengths[i] = 0;
        screen_line_ages[i] = N_FADE_STEPS;
        @memset(&screen_line_colors[i], Color.default);
        @memset(&screen_line_bold[i], false);
    }

    read_buffer_idx = 0;
    write_buffer_idx = 0;
    read_pos = 0;
    for (0..NUM_BUFFERS) |i| {
        buffer_states[i] = .empty;
        buffer_lengths[i] = 0;
    }

    reached_end = false;
    last_status_line_count = 0;
    run_start_epoch_ms = 0; // Will be set on next processFrame
    pending_command = false;
}

fn renderScreen() void {
    // Clear text area
    fillRect(TEXT_X, TEXT_Y, CHAR_W * N_COLS + 1, LINE_H * N_ROWS, SCRN_RGB);

    // Draw lines with per-character color
    for (0..num_screen_lines) |i| {
        const line_len = screen_line_lengths[i];
        const age = screen_line_ages[i];
        const y = TEXT_Y + @as(u32, @intCast(i)) * LINE_H;

        for (0..line_len) |j| {
            const ci = @intFromEnum(screen_line_colors[i][j]);
            const rgb = if (age >= N_FADE_STEPS)
                color_normal[ci]
            else
                fade_colors[ci][age];
            drawChar(screen_lines[i][j], TEXT_X + @as(u32, @intCast(j)) * CHAR_W, y, rgb, screen_line_bold[i][j]);
        }

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

    num_screen_lines = 0;
    last_status_line_count = 0;
    for (0..MAX_SCREEN_LINES) |i| {
        screen_line_lengths[i] = 0;
        screen_line_ages[i] = N_FADE_STEPS;
        @memset(&screen_line_colors[i], Color.default);
        @memset(&screen_line_bold[i], false);
    }

    for (0..NUM_BUFFERS) |i| {
        buffer_states[i] = .empty;
        buffer_lengths[i] = 0;
    }
    read_buffer_idx = 0;
    write_buffer_idx = 0;
    read_pos = 0;

    unknown_color_encountered = false;
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
    if (reached_end and manifest_duration_ms == 0) return false;
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

export fn hadUnknownColor() bool {
    return unknown_color_encountered;
}

export fn getVersion() u32 {
    return 5;
}
