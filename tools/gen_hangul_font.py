#!/usr/bin/env python3

from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont


FONT_SIZE = 8
X_OFFSET = 0
Y_OFFSET = 0
START = 0xAC00
END = 0xD7A3
HANGUL_COUNT = END - START + 1
RAW_PREFIX_BYTES = 8


def render_glyph(font: ImageFont.FreeTypeFont, char: str) -> list[int]:
    image = Image.new("1", (8, 8), 0)
    draw = ImageDraw.Draw(image)
    bbox = draw.textbbox((0, 0), char, font=font)
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    x = (8 - width) // 2 - bbox[0] + X_OFFSET
    y = (8 - height) // 2 - bbox[1] + Y_OFFSET
    draw.text((x, y), char, fill=1, font=font)

    columns: list[int] = []
    for x in range(8):
        value = 0
        for y in range(8):
            if image.getpixel((x, y)):
                value |= 1 << y
        columns.append(value)
    return columns


def load_raw_glyphs(raw_path: Path) -> list[list[int]]:
    data = raw_path.read_bytes()
    required = RAW_PREFIX_BYTES + (HANGUL_COUNT * 8)
    if len(data) < required:
        raise ValueError(f"raw font too small: expected at least {required} bytes, got {len(data)}")

    glyphs: list[list[int]] = []
    payload = data[RAW_PREFIX_BYTES:RAW_PREFIX_BYTES + (HANGUL_COUNT * 8)]
    for i in range(HANGUL_COUNT):
        start = i * 8
        glyphs.append(list(payload[start:start + 8]))
    return glyphs


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: gen_hangul_font.py <font.ttf|font.raw> <output.h>")
        return 1

    font_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    raw_mode = font_path.suffix.lower() == ".raw"
    glyphs = load_raw_glyphs(font_path) if raw_mode else None
    font = None if raw_mode else ImageFont.truetype(str(font_path), FONT_SIZE)

    with out_path.open("w", encoding="ascii") as fh:
        fh.write("#ifndef GENERATED_HANGUL_FONT_DATA_H\n")
        fh.write("#define GENERATED_HANGUL_FONT_DATA_H\n\n")
        fh.write("#include <stdint.h>\n\n")
        fh.write("static const uint8_t hangul_font8x8[11172][8] = {\n")

        for codepoint in range(START, END + 1):
            glyph = glyphs[codepoint - START] if glyphs else render_glyph(font, chr(codepoint))
            values = ",".join(f"0x{value:02X}" for value in glyph)
            fh.write(f"\t{{ {values} }}, // U+{codepoint:04X}\n")

        fh.write("};\n\n")
        fh.write("#endif\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
