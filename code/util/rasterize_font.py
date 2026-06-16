#!/usr/bin/env python3
"""
Rasterize a TTF font to Zig bitmap data for WASM embedding.
Outputs grayscale alpha values (0-255) for anti-aliased rendering.
Generates both regular and bold arrays with shared cell dimensions.
"""

import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Please install Pillow: pip3 install Pillow")
    sys.exit(1)

# Configuration
FONT_PATH = Path("/System/Library/Fonts/SFNSMono.ttf")
FONT_SIZE = int(sys.argv[1]) if len(sys.argv) > 1 else 16
CHARS = "".join(chr(c) for c in range(32, 127))  # ASCII 32-126

# Procedural box-drawing glyphs, appended after the ASCII glyphs (indices 95+).
# Each is built from arms reaching out from the cell center: every arm touches a
# cell edge, so adjacent cells connect with no gaps (unlike the font's own box
# glyphs, which tile at the font advance width, not our ink-derived cell width).
# Order here defines the glyph index offset from 95; keep it in sync with the
# DEC special-graphics mapping and the literal-UTF-8 box-codepoint mapping in
# pris-screen (wasm/src/terminal.zig).
#   arms: subset of {'up','down','left','right'}
#   heavy: thicker stroke, for the heavy/light box-drawing codepoints emitted
#   directly (as UTF-8) by tools like pip's progress bar, rather than via the
#   DEC special-graphics charset.
BOX_GLYPHS = [
    (0x2500, "horizontal",  {"left", "right"}, False),               # ─ q
    (0x2502, "vertical",    {"up", "down"}, False),                  # │ x
    (0x251C, "tee_right",   {"up", "down", "right"}, False),         # ├ t
    (0x2514, "up_right",    {"up", "right"}, False),                 # └ m
    (0x2510, "down_left",   {"down", "left"}, False),                # ┐ k
    (0x250C, "down_right",  {"down", "right"}, False),               # ┌ l
    (0x2518, "up_left",     {"up", "left"}, False),                  # ┘ j
    (0x2524, "tee_left",    {"up", "down", "left"}, False),          # ┤ u
    (0x252C, "tee_down",    {"down", "left", "right"}, False),       # ┬ w
    (0x2534, "tee_up",      {"up", "left", "right"}, False),         # ┴ v
    (0x253C, "cross",       {"up", "down", "left", "right"}, False), # ┼ n
    (0x2501, "heavy_horizontal", {"left", "right"}, True),           # ━ pip bar fill
    (0x257A, "heavy_right",      {"right"}, True),                   # ╺ pip bar edge
    (0x2578, "heavy_left",       {"left"}, True),                    # ╸ pip bar edge
]


def box_cell(arms, cell_width, cell_height, half_w):
    """Anti-aliased box glyph. Each arm reaches a cell edge so adjacent cells
    tile. Lines are ~2*half_w px wide with sub-pixel coverage, to match the
    font's anti-aliased stroke weight rather than the heavier solid rules."""
    px = [0] * (cell_width * cell_height)
    vc = cell_width / 2.0   # vertical rule centered horizontally
    hc = cell_height / 2.0  # horizontal rule centered vertically

    def cov(i, center):  # coverage of pixel [i, i+1] by [center-half_w, center+half_w]
        lo = max(float(i), center - half_w)
        hi = min(float(i) + 1.0, center + half_w)
        return hi - lo if hi > lo else 0.0

    for y in range(cell_height):
        for x in range(cell_width):
            a = 0.0
            cx = cov(x, vc)  # coverage across the vertical rule
            cy = cov(y, hc)  # coverage across the horizontal rule
            if "up" in arms and y <= hc:    a = max(a, cx)  # top edge -> center
            if "down" in arms and y >= hc:  a = max(a, cx)  # center -> bottom edge
            if "left" in arms and x <= vc:  a = max(a, cy)  # left edge -> center
            if "right" in arms and x >= vc: a = max(a, cy)  # center -> right edge
            px[y * cell_width + x] = round(a * 255)
    return px


def measure_font(font):
    metrics = []
    for char in CHARS:
        bbox = font.getbbox(char)
        metrics.append((char, bbox))
    return metrics


def render_array(font, array_name, cell_width, cell_height, y_offset, line_hw):
    total = len(CHARS) + len(BOX_GLYPHS)
    print(f"pub const {array_name}: [{total}][{cell_height}][{cell_width}]u8 = .{{")
    for char in CHARS:
        img = Image.new('L', (cell_width, cell_height), 0)
        draw = ImageDraw.Draw(img)
        bbox = font.getbbox(char)
        x_offset = (cell_width - (bbox[2] - bbox[0])) // 2 - bbox[0]
        draw.text((x_offset, y_offset), char, font=font, fill=255)
        pixels = list(img.getdata())

        char_display = char
        if char == '\\':
            char_display = '\\\\'
        elif char == "'":
            char_display = "\\'"

        print(f"    // '{char_display}' (ASCII {ord(char)})")
        print("    .{")
        for row in range(cell_height):
            row_data = pixels[row * cell_width:(row + 1) * cell_width]
            row_str = ", ".join(f"{p:3}" for p in row_data)
            print(f"        .{{ {row_str} }},")
        print("    },")

    # Procedural box-drawing glyphs (indices 95+), shared across regular/bold.
    for offset, (codepoint, name, arms, heavy) in enumerate(BOX_GLYPHS):
        pixels = box_cell(arms, cell_width, cell_height, line_hw * 2.0 if heavy else line_hw)
        print(f"    // U+{codepoint:04X} {name} (index {len(CHARS) + offset})")
        print("    .{")
        for row in range(cell_height):
            row_data = pixels[row * cell_width:(row + 1) * cell_width]
            row_str = ", ".join(f"{p:3}" for p in row_data)
            print(f"        .{{ {row_str} }},")
        print("    },")
    print("};")


def main():
    if not FONT_PATH.exists():
        print(f"Font not found: {FONT_PATH}")
        sys.exit(1)

    font_regular = ImageFont.truetype(str(FONT_PATH), FONT_SIZE)
    font_bold = ImageFont.truetype(str(FONT_PATH), FONT_SIZE)
    font_bold.set_variation_by_name('Bold')

    # Measure both fonts together to get shared cell dimensions
    metrics_regular = measure_font(font_regular)
    metrics_bold = measure_font(font_bold)
    all_metrics = metrics_regular + metrics_bold

    max_width   = max(bbox[2] - bbox[0] for _, bbox in all_metrics)
    max_ascent  = max(-bbox[1]          for _, bbox in all_metrics)
    max_descent = max( bbox[3]          for _, bbox in all_metrics)

    cell_width  = max_width + 2
    y_offset    = max_ascent + 2        # 2px top padding
    cell_height = y_offset + max_descent + 2  # 2px bottom padding
    line_hw     = FONT_SIZE / 22.0  # box-rule half-width (~1.3px wide at 16pt)

    total = len(CHARS) + len(BOX_GLYPHS)
    print(f"// Font: {FONT_PATH.stem} {FONT_SIZE}pt")
    print(f"// Cell size: {cell_width}x{cell_height}")
    print(f"// Characters: ASCII 32-126 + {len(BOX_GLYPHS)} box-drawing ({total} glyphs)")
    print()
    print(f"pub const FONT_W: u32 = {cell_width};")
    print(f"pub const FONT_H: u32 = {cell_height};")
    print()
    print(f"// Grayscale bitmap data: {total} chars x {cell_width} x {cell_height} bytes")
    render_array(font_regular, "font_data",      cell_width, cell_height, y_offset, line_hw)
    print()
    render_array(font_bold,    "font_data_bold", cell_width, cell_height, y_offset, line_hw)


if __name__ == "__main__":
    main()
