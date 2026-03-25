#!/usr/bin/env python3

from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont


FONT_SIZE = 10
X_OFFSET = 0
Y_OFFSET = 0
START = 0xAC00
END = 0xD7A3


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


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: gen_hangul_font.py <font.ttf> <output.h>")
        return 1

    font_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    font = ImageFont.truetype(str(font_path), FONT_SIZE)

    with out_path.open("w", encoding="ascii") as fh:
        fh.write("#ifndef GENERATED_HANGUL_FONT_DATA_H\n")
        fh.write("#define GENERATED_HANGUL_FONT_DATA_H\n\n")
        fh.write("#include <stdint.h>\n\n")
        fh.write("static const uint8_t hangul_font8x8[11172][8] = {\n")

        for codepoint in range(START, END + 1):
            glyph = render_glyph(font, chr(codepoint))
            values = ",".join(f"0x{value:02X}" for value in glyph)
            fh.write(f"\t{{ {values} }}, // U+{codepoint:04X}\n")

        fh.write("};\n\n")
        fh.write("#endif\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
