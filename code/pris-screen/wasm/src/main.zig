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
pub const BKGD_RGB: u32 = 0x2B3E43;
pub const SCRN_RGB: u32 = 0x2B4D59;
pub const BORDER_RGB: u32 = 0x3A5C61;
pub const TEXT_RGB: u32 = 0xC0C0C0;
pub const BRIGHT_RGB: u32 = 0xBBFF82;
pub const CURSOR_RGB: u32 = 0xFF0000;

pub const N_FADE_STEPS: u32 = 25;
pub const MAX_LINES: u32 = N_ROWS + 1;
pub const MAX_LINE_LEN: u32 = N_COLS;

// Pixel buffer (RGBA format for canvas)
var pixels: [SCREEN_W * SCREEN_H]u32 = undefined;

// Fade color table
var fade_colors: [N_FADE_STEPS]u32 = undefined;

// Screen state: lines of text with ages
var line_buffer: [MAX_LINES][MAX_LINE_LEN]u8 = undefined;
var line_lengths: [MAX_LINES]u32 = undefined;
var line_ages: [MAX_LINES]u32 = undefined;
var num_lines: u32 = 0;
var cursor_visible: bool = true;

fn lerp(a: u32, b: u32, t: u32, steps: u32) u32 {
    if (steps == 0) return a;
    if (a >= b) {
        return a - (a - b) * t / steps;
    } else {
        return a + (b - a) * t / steps;
    }
}

// Initialize the display
export fn init() void {
    // Generate fade colors (from BRIGHT_RGB to TEXT_RGB)
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

    // Clear screen
    clearScreen();

    // Initialize line buffer
    num_lines = 0;
    for (0..MAX_LINES) |i| {
        line_lengths[i] = 0;
        line_ages[i] = N_FADE_STEPS;
    }
}

fn clearScreen() void {
    // Fill with background color (convert RGB to RGBA)
    const rgba = rgbToRgba(SCRN_RGB);
    for (&pixels) |*p| {
        p.* = rgba;
    }

    // Draw border
    drawBorder();
}

fn rgbToRgba(rgb: u32) u32 {
    // Convert RGB to RGBA (for canvas ImageData which is ABGR in little-endian)
    const r = (rgb >> 16) & 0xFF;
    const g = (rgb >> 8) & 0xFF;
    const b = rgb & 0xFF;
    return 0xFF000000 | (b << 16) | (g << 8) | r;
}

fn drawBorder() void {
    const border = rgbToRgba(BORDER_RGB);

    // Top and bottom borders
    for (0..SCREEN_W) |x| {
        pixels[x] = border;
        pixels[x + (SCREEN_H - 1) * SCREEN_W] = border;
    }

    // Left and right borders
    for (0..SCREEN_H) |y| {
        pixels[y * SCREEN_W] = border;
        pixels[y * SCREEN_W + SCREEN_W - 1] = border;
    }
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

    // Extract foreground RGB
    const fr = (rgb >> 16) & 0xFF;
    const fg = (rgb >> 8) & 0xFF;
    const fb = rgb & 0xFF;

    // Extract background RGB (already in ABGR format)
    const br = bg & 0xFF;
    const bbg = (bg >> 8) & 0xFF;
    const bb = (bg >> 16) & 0xFF;

    // Alpha blend
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

// Add a line of text
export fn addLine(ptr: [*]const u8, len: u32) void {
    if (num_lines >= MAX_LINES) {
        // Scroll up
        for (0..MAX_LINES - 1) |i| {
            line_lengths[i] = line_lengths[i + 1];
            line_ages[i] = line_ages[i + 1];
            @memcpy(&line_buffer[i], &line_buffer[i + 1]);
        }
        num_lines = MAX_LINES - 1;
    }

    // Copy new line
    const copy_len = @min(len, MAX_LINE_LEN);
    @memcpy(line_buffer[num_lines][0..copy_len], ptr[0..copy_len]);
    line_lengths[num_lines] = copy_len;
    line_ages[num_lines] = 0;
    num_lines += 1;
}

// Toggle cursor visibility
export fn setCursor(visible: bool) void {
    cursor_visible = visible;
}

// Render the screen
export fn render() void {
    // Clear text area
    fillRect(TEXT_X, TEXT_Y, CHAR_W * N_COLS, LINE_H * N_ROWS, SCRN_RGB);

    // Calculate which lines to show (last N_ROWS lines)
    const start_line: u32 = if (num_lines > N_ROWS) num_lines - N_ROWS else 0;
    const visible_lines = num_lines - start_line;

    // Draw lines
    for (0..visible_lines) |i| {
        const line_idx = start_line + @as(u32, @intCast(i));
        const line_len = line_lengths[line_idx];
        const age = line_ages[line_idx];

        // Get color based on age
        const rgb = if (age >= N_FADE_STEPS) TEXT_RGB else fade_colors[age];

        // Draw the line
        const y = TEXT_Y + @as(u32, @intCast(i)) * LINE_H;
        drawString(line_buffer[line_idx][0..line_len], TEXT_X, y, rgb);

        // Age the line
        if (line_ages[line_idx] < N_FADE_STEPS) {
            line_ages[line_idx] += 1;
        }
    }

    // Draw cursor
    if (cursor_visible and visible_lines > 0) {
        const last_idx = start_line + visible_lines - 1;
        const cursor_x = TEXT_X + line_lengths[last_idx] * CHAR_W;
        const cursor_y = TEXT_Y + (visible_lines - 1) * LINE_H;

        // Draw vertical line cursor
        for (0..font.FONT_H) |dy| {
            setPixel(cursor_x, cursor_y + @as(u32, @intCast(dy)), CURSOR_RGB);
        }
    }
}

// Get pointer to pixel buffer
export fn getPixelBuffer() [*]u32 {
    return &pixels;
}

// Get buffer size
export fn getBufferSize() u32 {
    return SCREEN_W * SCREEN_H * 4;
}

export fn getScreenWidth() u32 {
    return SCREEN_W;
}

export fn getScreenHeight() u32 {
    return SCREEN_H;
}

export fn getVersion() u32 {
    return 3;
}
