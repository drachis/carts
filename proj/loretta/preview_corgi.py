"""preview_corgi.py - Loretta assembled from her parts, beside a reference.

usage: py preview_corgi.py [reference.png x0,y0,x1,y1] out.png

Puts corgi_art.py's parts together the way loretta.lua does when she
stands (body, far ear, face, near ear, eyes, mouth, four legs) and writes
a picture at ten times size, with the reference cropped beside it at the
same height, for checking proportions before writing any Lua.
"""
import sys

from PIL import Image

import corgi_art
from png import PALETTE

# where each part sits, from the top left of a 46x40 picture of her
BODY_AT = (4, 20)
FACE_AT = (20, 12)
FAR_EAR_AT = (19, 3)
NEAR_EAR_AT = (27, 3)
GROUND = 37
WIDTH, HEIGHT = 46, 40


def stamp(canvas, text, left, top, colours=None):
    for y, row in enumerate(text.split("\n")):
        for x, colour in enumerate(row):
            if colour != "." and 0 <= top + y < len(canvas) and 0 <= left + x < len(canvas[0]):
                canvas[top + y][left + x] = (colours or {}).get(colour, colour)


def leg(canvas, x, top, sock, upper):
    for y in range(top, GROUND + 1):
        for dx in range(-1, 4):
            colour = "0" if dx in (-1, 3) or y == GROUND else (sock if y > GROUND - 3 else upper)
            canvas[y][x + dx] = colour


def corgi():
    canvas = [["."] * WIDTH for _ in range(HEIGHT)]
    left, top = BODY_AT
    leg(canvas, left + 9, top + 11, "6", "4")
    leg(canvas, left + 22, top + 11, "6", "6")
    stamp(canvas, corgi_art.ear(-1, False), *FAR_EAR_AT, colours={"9": "4"})
    stamp(canvas, corgi_art.body(), left, top)
    leg(canvas, left + 5, top + 12, "7", "9")
    leg(canvas, left + 19, top + 12, "7", "7")
    stamp(canvas, corgi_art.face(), *FACE_AT)
    stamp(canvas, corgi_art.ear(1, True), *NEAR_EAR_AT)
    fx, fy = FACE_AT
    for x, y, colour in ((12, 6, "0"), (13, 6, "0"), (12, 7, "0"), (13, 7, "0"), (12, 8, "0"), (13, 8, "0"),
                         (12, 6, "7"), (5, 7, "0"), (5, 8, "0"),
                         (15, 12, "0"), (16, 13, "0"), (17, 13, "0"), (18, 12, "0"),
                         (16, 14, "e"), (17, 14, "e")):
        canvas[fy + y][fx + x] = colour
    return canvas


def main():
    out = sys.argv[-1]
    canvas = corgi()
    scale = 10
    picture = Image.new("RGB", (WIDTH * scale, HEIGHT * scale), (60, 50, 90))
    for y, row in enumerate(canvas):
        for x, colour in enumerate(row):
            if colour != ".":
                for py in range(scale):
                    for px in range(scale):
                        picture.putpixel((x * scale + px, y * scale + py), PALETTE[int(colour, 16)])
    if len(sys.argv) > 3:
        box = tuple(int(v) for v in sys.argv[2].split(","))
        reference = Image.open(sys.argv[1]).convert("RGB").crop(box)
        reference = reference.resize((int(reference.width * picture.height / reference.height), picture.height))
        both = Image.new("RGB", (picture.width + reference.width + 10, picture.height), (0, 0, 0))
        both.paste(picture, (0, 0))
        both.paste(reference, (picture.width + 10, 0))
        picture = both
    picture.save(out)


if __name__ == "__main__":
    main()
