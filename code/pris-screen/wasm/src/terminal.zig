// Terminal core: the grid state machine shared by the WASM renderer and (later)
// the server-side keyframe writer. It interprets the build's control stream
// (\r, \n, ESC M, ESC[J/K/G, ESC(0 DEC charset, the 0x01 CR sentinel) into a
// character grid with per-cell color — no rendering, no pixels.
const std = @import("std");
const build_options = @import("build_options");

pub const N_COLS: u32 = build_options.n_cols;
pub const N_ROWS: u32 = build_options.n_rows;
pub const MAX_SCREEN_LINES: u32 = N_ROWS;
pub const N_FADE_STEPS: u32 = 25;

// A ts-line beginning with this means the preceding break was a carriage
// return, not a newline.
pub const SENTINEL: u8 = 0x01;

// Box-drawing glyphs live at font indices 95+ and are stored in the grid as
// byte codes BOX_BASE..BOX_BASE+N_BOX_GLYPHS-1.
pub const BOX_BASE: u8 = 0x80;
pub const FIRST_BOX_GLYPH: usize = 95;
pub const N_BOX_GLYPHS: usize = 14;

// Color palette
pub const Color = enum(u8) {
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
pub const N_COLORS = @typeInfo(Color).@"enum".fields.len;

// --- Terminal emulation state (persists across ts-lines / chunk boundaries) ---
pub var cursor_row: u32 = 0;
pub var cursor_col: u32 = 0;
pub var term_color: Color = .default; // current SGR color, persists until changed
pub var term_bold: bool = false;
pub var charset_dec: bool = false; // true while DEC special-graphics (ESC ( 0) active
pub var pending_newline: bool = false; // a line break is deferred to the next ts-line

// Set when scrollUp ran since the last present; present() then skips its
// per-row change diff for that cycle (row indices shifted, and scrollUp has
// already seeded the incoming line's fade age).
pub var scrolled_since_present: bool = false;

// Pending command: set when a "[pris:/dir]> " prompt line is seen; the next
// ts-line is the command, drawn on the same line (after "> ") to look typed.
pub var pending_command: bool = false;

// Set when an unrecognised true-color RGB is encountered during parsing
pub var unknown_color_encountered: bool = false;

// The "work" grid the terminal writes into.
pub var screen_lines: [MAX_SCREEN_LINES][N_COLS]u8 = undefined;
pub var screen_line_colors: [MAX_SCREEN_LINES][N_COLS]Color = undefined;
pub var screen_line_bold: [MAX_SCREEN_LINES][N_COLS]bool = undefined;
pub var screen_line_lengths: [MAX_SCREEN_LINES]u32 = undefined;
pub var screen_line_ages: [MAX_SCREEN_LINES]u32 = undefined;
pub var num_screen_lines: u32 = 0;

// Display grid: the last presented (complete) frame. The work grid is copied
// here (present) only at completed frames — at a synchronized-update end
// (ESC[?2026l) or, for unwrapped output, after each line. A half-erased frame
// is therefore never visible, so identical redraws produce no flicker.
pub var disp_lines: [MAX_SCREEN_LINES][N_COLS]u8 = undefined;
pub var disp_colors: [MAX_SCREEN_LINES][N_COLS]Color = undefined;
pub var disp_bold: [MAX_SCREEN_LINES][N_COLS]bool = undefined;
pub var disp_lengths: [MAX_SCREEN_LINES]u32 = undefined;
pub var disp_ages: [MAX_SCREEN_LINES]u32 = undefined;
pub var disp_num: u32 = 0;
pub var disp_cursor_row: u32 = 0;
pub var disp_cursor_col: u32 = 0;
pub var sync_active: bool = false; // inside a synchronized update (ESC[?2026h..l)

// Map a DEC special-graphics byte to its box glyph code (order matches the
// BOX_GLYPHS list in code/util/rasterize_font.py). Non-box bytes pass through.
fn decMap(c: u8) u8 {
    return switch (c) {
        'q' => BOX_BASE + 0, // ─
        'x' => BOX_BASE + 1, // │
        't' => BOX_BASE + 2, // ├
        'm' => BOX_BASE + 3, // └
        'k' => BOX_BASE + 4, // ┐
        'l' => BOX_BASE + 5, // ┌
        'j' => BOX_BASE + 6, // ┘
        'u' => BOX_BASE + 7, // ┤
        'w' => BOX_BASE + 8, // ┬
        'v' => BOX_BASE + 9, // ┴
        'n' => BOX_BASE + 10, // ┼
        else => c, // space and others render as-is
    };
}

// Map a literal UTF-8 box-drawing codepoint to its box glyph code (order
// matches BOX_GLYPHS in code/util/rasterize_font.py). Tools like pip emit
// these directly as UTF-8 rather than via the DEC special-graphics charset.
fn boxCodepoint(cp: u21) ?u8 {
    return switch (cp) {
        0x2500 => BOX_BASE + 0,  // ─
        0x2502 => BOX_BASE + 1,  // │
        0x251C => BOX_BASE + 2,  // ├
        0x2514 => BOX_BASE + 3,  // └
        0x2510 => BOX_BASE + 4,  // ┐
        0x250C => BOX_BASE + 5,  // ┌
        0x2518 => BOX_BASE + 6,  // ┘
        0x2524 => BOX_BASE + 7,  // ┤
        0x252C => BOX_BASE + 8,  // ┬
        0x2534 => BOX_BASE + 9,  // ┴
        0x253C => BOX_BASE + 10, // ┼
        0x2501 => BOX_BASE + 11, // ━ pip bar fill
        0x257A => BOX_BASE + 12, // ╺ pip bar edge
        0x2578 => BOX_BASE + 13, // ╸ pip bar edge
        else => null,
    };
}

// Decode one UTF-8 sequence starting at raw[i]. Malformed or truncated
// sequences decode as a single byte so the parser can't get stuck.
fn utf8Decode(raw: []const u8, i: usize) struct { cp: u21, len: usize } {
    const b0 = raw[i];
    const len: usize = if (b0 & 0xE0 == 0xC0) 2 else if (b0 & 0xF0 == 0xE0) 3 else if (b0 & 0xF8 == 0xF0) 4 else 1;
    if (len == 1 or i + len > raw.len) return .{ .cp = b0, .len = 1 };
    var cp: u21 = b0 & (@as(u21, 0x7F) >> @intCast(len));
    for (1..len) |k| {
        const bk = raw[i + k];
        if (bk & 0xC0 != 0x80) return .{ .cp = b0, .len = 1 }; // not a continuation byte
        cp = (cp << 6) | (bk & 0x3F);
    }
    return .{ .cp = cp, .len = len };
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

// Parse the leading decimal parameter of a CSI sequence, or `default` if absent.
fn csiNum(params: []const u8, default: u32) u32 {
    var n: u32 = 0;
    var has_digit = false;
    for (params) |c| {
        if (c >= '0' and c <= '9') {
            n = n * 10 + (c - '0');
            has_digit = true;
        } else break;
    }
    return if (has_digit) n else default;
}

// Handle a decoded CSI sequence against the terminal cursor and grid.
fn handleCsi(cmd: u8, params: []const u8) void {
    switch (cmd) {
        'm' => parseSgr(params, &term_color, &term_bold),
        'G' => { // cursor to column N (1-based); ESC[G / ESC[1G => column 0
            const n = csiNum(params, 1);
            cursor_col = @min(if (n > 0) n - 1 else 0, N_COLS - 1);
        },
        'A' => { // cursor up N (default 1)
            var k: u32 = csiNum(params, 1);
            while (k > 0) : (k -= 1) cursorUp();
        },
        'K' => { // erase in line: 0 = cursor->EOL, 2 = whole line
            if (csiNum(params, 0) == 2) clearRow(cursor_row) else eraseToEol();
        },
        'J' => { // erase in display: 0 = cursor->end of screen, 2 = whole screen
            if (csiNum(params, 0) == 2) {
                var r: u32 = 0;
                while (r < num_screen_lines) : (r += 1) clearRow(r);
                num_screen_lines = 0;
                cursor_row = 0;
                cursor_col = 0;
            } else eraseToEos();
        },
        'h' => { // ESC[?2026h: begin synchronized update
            if (std.mem.eql(u8, params, "?2026")) sync_active = true;
        },
        'l' => { // ESC[?2026l: end synchronized update — present the finished frame
            if (std.mem.eql(u8, params, "?2026")) {
                sync_active = false;
                present();
            }
        },
        else => {}, // H, n, p, etc. ignored
    }
}

// --- Terminal grid operations (cursor-addressed) ---

fn clearRow(r: u32) void {
    @memset(&screen_lines[r], ' ');
    @memset(&screen_line_colors[r], Color.default);
    @memset(&screen_line_bold[r], false);
    screen_line_lengths[r] = 0;
}

// Scroll the whole viewport up by one row; the freed bottom row is blanked.
fn scrollUp() void {
    for (0..MAX_SCREEN_LINES - 1) |i| {
        @memcpy(&screen_lines[i], &screen_lines[i + 1]);
        @memcpy(&screen_line_colors[i], &screen_line_colors[i + 1]);
        @memcpy(&screen_line_bold[i], &screen_line_bold[i + 1]);
        screen_line_lengths[i] = screen_line_lengths[i + 1];
        screen_line_ages[i] = screen_line_ages[i + 1];
    }
    clearRow(MAX_SCREEN_LINES - 1);
    screen_line_ages[MAX_SCREEN_LINES - 1] = 0; // scrolled-in line fades in
    scrolled_since_present = true;
}

fn cursorUp() void {
    if (cursor_row > 0) cursor_row -= 1;
}

fn cursorCr() void {
    cursor_col = 0;
}

// Newline: column 0 of the next row, scrolling the viewport if at the bottom.
fn cursorNewline() void {
    cursor_col = 0;
    if (cursor_row + 1 >= MAX_SCREEN_LINES) {
        scrollUp();
        cursor_row = MAX_SCREEN_LINES - 1;
    } else {
        cursor_row += 1;
    }
    if (cursor_row + 1 > num_screen_lines) num_screen_lines = cursor_row + 1;
}

fn eraseToEol() void {
    var j = cursor_col;
    while (j < N_COLS) : (j += 1) {
        screen_lines[cursor_row][j] = ' ';
        screen_line_colors[cursor_row][j] = .default;
        screen_line_bold[cursor_row][j] = false;
    }
    if (screen_line_lengths[cursor_row] > cursor_col)
        screen_line_lengths[cursor_row] = cursor_col;
}

// Erase from the cursor to the end of the screen (current row tail + rows below).
fn eraseToEos() void {
    eraseToEol();
    var r = cursor_row + 1;
    while (r < num_screen_lines) : (r += 1) clearRow(r);
    num_screen_lines = cursor_row + 1;
}

// Write one glyph at the cursor and advance, wrapping at the right margin.
fn putGlyph(c: u8) void {
    if (cursor_col >= N_COLS) cursorNewline();
    if (cursor_row + 1 > num_screen_lines) num_screen_lines = cursor_row + 1;
    screen_lines[cursor_row][cursor_col] = c;
    screen_line_colors[cursor_row][cursor_col] = term_color;
    screen_line_bold[cursor_row][cursor_col] = term_bold;
    if (cursor_col + 1 > screen_line_lengths[cursor_row])
        screen_line_lengths[cursor_row] = cursor_col + 1;
    // Note: age is NOT reset here. The fade-in is triggered only when a line
    // scrolls in (see scrollUp), so in-place redraws (zig progress, the
    // countdown) update without re-fading — no flicker.
    cursor_col += 1;
}

// Feed the content bytes of one ts-line through the terminal state machine.
// The inter-line break (the \n separating ts-lines) is applied by the caller
// via the lazy-break logic in processTsLine; this handles everything within.
fn feedContent(raw: []const u8) void {
    var i: usize = 0;
    while (i < raw.len) {
        const c = raw[i];
        if (c == 0x1b) {
            if (i + 1 >= raw.len) {
                i += 1;
                continue;
            }
            switch (raw[i + 1]) {
                '[' => { // CSI: scan to final byte (0x40-0x7E)
                    i += 2;
                    const seq_start = i;
                    while (i < raw.len) {
                        const sc = raw[i];
                        if (sc >= 0x40 and sc <= 0x7E) {
                            handleCsi(sc, raw[seq_start..i]);
                            i += 1;
                            break;
                        }
                        i += 1;
                    }
                },
                ']' => { // OSC: skip to BEL or ST
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
                'P' => { // DCS: skip to ST
                    i += 2;
                    while (i < raw.len) {
                        if (raw[i] == 0x1b and i + 1 < raw.len and raw[i + 1] == '\\') {
                            i += 2;
                            break;
                        }
                        i += 1;
                    }
                },
                'M' => { // reverse index: cursor up one row
                    cursorUp();
                    i += 2;
                },
                '(' => { // designate G0 charset: ESC ( <set>  ('0' = DEC graphics)
                    if (i + 2 < raw.len) {
                        charset_dec = (raw[i + 2] == '0');
                        i += 3;
                    } else i += 2;
                },
                else => i += 2, // unknown escape: skip ESC + next byte
            }
        } else if (c == '\r') {
            cursorCr();
            i += 1;
        } else if (c == '\n') {
            cursorNewline();
            i += 1;
        } else if (c < 32) {
            i += 1; // other control chars ignored
        } else if (c < 0x80) {
            putGlyph(if (charset_dec) decMap(c) else c);
            i += 1;
        } else {
            const dec = utf8Decode(raw, i);
            i += dec.len;
            switch (dec.cp) {
                // Zero-width: variation selector, ZWJ, bidi controls — no cell.
                0xFE0F, 0x200D, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E => {},
                else => putGlyph(boxCodepoint(dec.cp) orelse ' '),
            }
        }
    }
}

// Does work row `i` differ from the last presented frame's row `i`?
fn rowDiffers(i: u32) bool {
    if (screen_line_lengths[i] != disp_lengths[i]) return true;
    for (0..screen_line_lengths[i]) |j| {
        if (screen_lines[i][j] != disp_lines[i][j] or
            screen_line_colors[i][j] != disp_colors[i][j] or
            screen_line_bold[i][j] != disp_bold[i][j]) return true;
    }
    return false;
}

// Copy the work grid to the display grid (a completed frame becomes visible).
// A row that genuinely changed since the last presented frame (or is newly
// added) restarts at the bright end of the fade — so in-place redraws fade like
// fresh output, while identical redraws keep settling toward normal. The diff is
// skipped on scroll cycles, where row indices shifted under scrollUp.
fn present() void {
    const prev_disp_num = disp_num;
    for (0..num_screen_lines) |i| {
        if (!scrolled_since_present) {
            const changed = i >= prev_disp_num or rowDiffers(@intCast(i));
            if (changed) screen_line_ages[i] = 0;
        }
        @memcpy(&disp_lines[i], &screen_lines[i]);
        @memcpy(&disp_colors[i], &screen_line_colors[i]);
        @memcpy(&disp_bold[i], &screen_line_bold[i]);
        disp_lengths[i] = screen_line_lengths[i];
        disp_ages[i] = screen_line_ages[i];
    }
    disp_num = num_screen_lines;
    disp_cursor_row = cursor_row;
    disp_cursor_col = cursor_col;
    scrolled_since_present = false;
}

// Process one timestamped log line's content. Resolves the deferred line break
// from the previous ts-line (real newline vs. a sentinel-marked carriage
// return), handles the prompt/command merge, then feeds the bytes to the
// terminal. A ts-line ending leaves `pending_newline` set so the *next* line
// resolves the break — letting a leading sentinel turn it into a CR instead.
pub fn processTsLine(content_in: []const u8) void {
    var content = content_in;
    const is_cr = content.len > 0 and content[0] == SENTINEL;
    if (is_cr) content = content[1..];

    // Command following a prompt: draw it on the prompt's "> " line so it looks
    // typed, then advance one row so the blinking cursor rests at column 0 of a
    // fresh bottom line while the command runs. Blank fillers are skipped
    // without disturbing the cursor parked after "> ".
    if (pending_command) {
        if (content.len == 0) return;
        feedContent(content);
        // A trailing backslash is a shell line-continuation: the command spans
        // further ts-lines. Advance a row but stay in command mode so each
        // continuation is drawn beneath, and only drop to the fresh blinking-
        // cursor line once the final (non-continued) line arrives.
        const continued = content[content.len - 1] == '\\';
        cursorNewline();
        if (!continued) {
            pending_command = false;
            pending_newline = false;
        }
        if (!sync_active) present();
        return;
    }

    // Resolve the break deferred by the previous ts-line.
    if (is_cr) {
        cursorCr();
    } else if (pending_newline) {
        cursorNewline();
    }
    pending_newline = false;

    // Prompt line "...[pris:/dir]> ": put the path on its own row and "> " on the
    // next, then await the command (handled above on the following ts-line).
    if (std.mem.indexOf(u8, content, "[pris:")) |pi| {
        var split: usize = pi + 6;
        while (split < content.len and content[split] != ']') : (split += 1) {}
        if (split < content.len) {
            feedContent(content[0 .. split + 1]); // "...[pris:/dir]"
            cursorNewline();
            feedContent(content[split + 1 ..]); // "> " (with its SGR color)
            pending_command = true;
            if (!sync_active) present();
            return;
        }
    }

    feedContent(content);
    pending_newline = true;
    if (!sync_active) present();
}

// Reset the terminal/grid state (cursor, grids, pending flags). Buffers, timing
// and unknown_color_encountered are owned by the caller.
pub fn reset() void {
    num_screen_lines = 0;
    cursor_row = 0;
    cursor_col = 0;
    term_color = .default;
    term_bold = false;
    charset_dec = false;
    pending_newline = false;
    pending_command = false;
    sync_active = false;
    scrolled_since_present = false;
    disp_num = 0;
    disp_cursor_row = 0;
    disp_cursor_col = 0;
    for (0..MAX_SCREEN_LINES) |i| {
        screen_line_lengths[i] = 0;
        screen_line_ages[i] = N_FADE_STEPS;
        @memset(&screen_line_colors[i], Color.default);
        @memset(&screen_line_bold[i], false);
    }
}

// --- Keyframe (de)serialization ---
//
// A compact dump of the full terminal state, used to prime the screen on a
// fresh connect / replay seek. The client resumes feeding at the exact line
// after the keyframe's timestamp, so the keyframe must reproduce the terminal
// state forward play had at that point — not just the visible pixels. zig's
// std.Progress redraws its tree cursor-addressed (ESC M up, ESC[J, redraw)
// almost entirely inside a synchronized update, so the work grid and cursor
// routinely differ from the last *presented* (display) frame mid-redraw;
// dumping the display grid + a guessed cursor desynced the resume and doubled
// the tree. So we dump the work grid plus the cursor and the cross-line flags.
//
// Format (5-byte header, then the rows):
//   [cursor_row: u8] [cursor_col: u8] [flags: u8] [term_color: u8] [num_rows: u8]
//   per row: [len: u8] then len × (char: u8, attr: u8)
// flags: bit0 pending_newline, bit1 charset_dec, bit2 sync_active,
//        bit3 pending_command, bit4 term_bold
// attr = color | (bold << 7). Tiny (a few KB) and re-rendered by the client,
// so it adapts to the canvas/font — never pixels. Keyframes are regenerated
// whenever this binary is (grid size already forces it), so there is no version
// tag: a stale keyframe is never read against mismatched code.

pub const KEYFRAME_MAX_BYTES: usize = 5 + MAX_SCREEN_LINES * (1 + N_COLS * 2);

// Serialize the current terminal state (work grid + cursor + flags) into `out`;
// returns the byte length.
pub fn serializeKeyframe(out: []u8) usize {
    var i: usize = 0;
    out[i] = @intCast(cursor_row);
    i += 1;
    out[i] = @intCast(@min(cursor_col, N_COLS));
    i += 1;
    var flags: u8 = 0;
    if (pending_newline) flags |= 0x01;
    if (charset_dec) flags |= 0x02;
    if (sync_active) flags |= 0x04;
    if (pending_command) flags |= 0x08;
    if (term_bold) flags |= 0x10;
    out[i] = flags;
    i += 1;
    out[i] = @intFromEnum(term_color);
    i += 1;
    out[i] = @intCast(num_screen_lines);
    i += 1;
    for (0..num_screen_lines) |r| {
        const len = screen_line_lengths[r];
        out[i] = @intCast(len);
        i += 1;
        for (0..len) |c| {
            out[i] = screen_lines[r][c];
            out[i + 1] = @intFromEnum(screen_line_colors[r][c]) |
                (if (screen_line_bold[r][c]) @as(u8, 0x80) else 0);
            i += 2;
        }
    }
    return i;
}

// Restore the full terminal state from a serialized keyframe. The grid is loaded
// into both the work and display grids so the screen renders immediately, and the
// cursor and cross-line flags are restored exactly so the resumed stream — which
// may pick up mid-redraw — continues as forward play would.
pub fn loadKeyframe(bytes: []const u8) void {
    reset();
    if (bytes.len < 5) return;
    var i: usize = 0;
    const c_row = bytes[i];
    i += 1;
    const c_col = bytes[i];
    i += 1;
    const flags = bytes[i];
    i += 1;
    const color_byte = bytes[i];
    i += 1;
    const rows = @min(@as(u32, bytes[i]), MAX_SCREEN_LINES);
    i += 1;
    var r: u32 = 0;
    while (r < rows and i < bytes.len) : (r += 1) {
        const len = @min(@as(u32, bytes[i]), N_COLS);
        i += 1;
        var c: u32 = 0;
        while (c < len and i + 1 < bytes.len) : (c += 1) {
            const ch = bytes[i];
            const attr = bytes[i + 1];
            i += 2;
            const ci: u8 = @min(attr & 0x7f, @as(u8, N_COLORS - 1));
            const color: Color = @enumFromInt(ci);
            const bold = (attr & 0x80) != 0;
            screen_lines[r][c] = ch;
            screen_line_colors[r][c] = color;
            screen_line_bold[r][c] = bold;
            disp_lines[r][c] = ch;
            disp_colors[r][c] = color;
            disp_bold[r][c] = bold;
        }
        screen_line_lengths[r] = len;
        screen_line_ages[r] = N_FADE_STEPS; // loaded content shows at normal brightness
        disp_lengths[r] = len;
        disp_ages[r] = N_FADE_STEPS;
    }
    num_screen_lines = rows;
    disp_num = rows;
    cursor_row = @min(@as(u32, c_row), MAX_SCREEN_LINES - 1);
    cursor_col = @min(@as(u32, c_col), N_COLS);
    pending_newline = (flags & 0x01) != 0;
    charset_dec = (flags & 0x02) != 0;
    sync_active = (flags & 0x04) != 0;
    pending_command = (flags & 0x08) != 0;
    term_bold = (flags & 0x10) != 0;
    term_color = @enumFromInt(@min(color_byte, @as(u8, N_COLORS - 1)));
    disp_cursor_row = cursor_row;
    disp_cursor_col = cursor_col;
}
