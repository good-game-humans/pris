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
FONT_SIZE = 16
CHARS = "".join(chr(c) for c in range(32, 127))  # ASCII 32-126


def measure_font(font):
    metrics = []
    for char in CHARS:
        bbox = font.getbbox(char)
        metrics.append((char, bbox))
    return metrics


def render_array(font, array_name, cell_width, cell_height, y_offset):
    print(f"pub const {array_name}: [{len(CHARS)}][{cell_height}][{cell_width}]u8 = .{{")
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

    print(f"// Font: {FONT_PATH.stem} {FONT_SIZE}pt")
    print(f"// Cell size: {cell_width}x{cell_height}")
    print(f"// Characters: ASCII 32-126 ({len(CHARS)} glyphs)")
    print()
    print(f"pub const FONT_W: u32 = {cell_width};")
    print(f"pub const FONT_H: u32 = {cell_height};")
    print()
    print(f"// Grayscale bitmap data: {len(CHARS)} chars x {cell_width} x {cell_height} bytes")
    render_array(font_regular, "font_data",      cell_width, cell_height, y_offset)
    print()
    render_array(font_bold,    "font_data_bold", cell_width, cell_height, y_offset)


if __name__ == "__main__":
    main()
