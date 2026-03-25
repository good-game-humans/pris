#!/usr/bin/env python3
"""
Rasterize a TTF font to Zig bitmap data for WASM embedding.
Outputs grayscale alpha values (0-255) for anti-aliased rendering.
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

def main():
    if not FONT_PATH.exists():
        print(f"Font not found: {FONT_PATH}")
        sys.exit(1)

    font = ImageFont.truetype(str(FONT_PATH), FONT_SIZE)

    # Measure characters to find max dimensions
    max_width = 0
    max_height = 0
    char_metrics = []

    for char in CHARS:
        # Get bounding box
        bbox = font.getbbox(char)
        width = bbox[2] - bbox[0]
        height = bbox[3] - bbox[1]
        max_width = max(max_width, width)
        max_height = max(max_height, height)
        char_metrics.append((char, bbox))

    # Compute cell size from actual ascent/descent extents across all glyphs
    max_ascent  = max(-bbox[1] for _, bbox in char_metrics)  # pixels above origin
    max_descent = max( bbox[3] for _, bbox in char_metrics)  # pixels below origin
    cell_width  = max_width + 2
    y_offset    = max_ascent + 2   # 2px top padding
    cell_height = y_offset + max_descent + 2  # 2px bottom padding

    print(f"// Font: {FONT_PATH.stem} {FONT_SIZE}pt")
    print(f"// Cell size: {cell_width}x{cell_height}")
    print(f"// Characters: ASCII 32-126 ({len(CHARS)} glyphs)")
    print()
    print(f"pub const FONT_W: u32 = {cell_width};")
    print(f"pub const FONT_H: u32 = {cell_height};")
    print()
    print(f"// Grayscale bitmap data: {len(CHARS)} chars x {cell_width} x {cell_height} bytes")
    print(f"pub const font_data: [{len(CHARS)}][{cell_height}][{cell_width}]u8 = .{{")

    for i, char in enumerate(CHARS):
        # Create image for this character
        img = Image.new('L', (cell_width, cell_height), 0)
        draw = ImageDraw.Draw(img)

        # Center the character horizontally, align to baseline
        bbox = font.getbbox(char)
        x_offset = (cell_width - (bbox[2] - bbox[0])) // 2 - bbox[0]

        draw.text((x_offset, y_offset), char, font=font, fill=255)

        # Output pixel data
        pixels = list(img.getdata())

        # Escape special characters for comment
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

if __name__ == "__main__":
    main()
