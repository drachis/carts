"""contact_sheet.py - crops of dumped screens side by side, to look at motion.

usage: py contact_sheet.py log.p8l name,name,... x0,y0,x1,y1 out.png [reference x0,y0,x1,y1]

Reads screens a test cart dumped into its log (dump_screen in
tests/dump.lua), crops the same box from each, lays them in a row at
eight times size, and puts a reference picture cropped to the same
height at the end, if given.
"""
import re
import sys

from PIL import Image

from png import PALETTE


def screens(log):
    found = {}
    for line in open(log):
        match = re.match(r"^(\w+) ([0-9a-f]{128})$", line.strip())
        if match:
            found.setdefault(match.group(1), []).append(match.group(2))
    return found


def main():
    log, names, box, out = sys.argv[1:5]
    x0, y0, x1, y1 = (int(v) for v in box.split(","))
    found, scale = screens(log), 8
    pieces = []
    for name in names.split(","):
        rows = found[name]
        piece = Image.new("RGB", ((x1 - x0) * scale, (y1 - y0) * scale))
        for y in range(y0, y1):
            for x in range(x0, x1):
                colour = PALETTE[int(rows[y][x], 16)]
                for dy in range(scale):
                    for dx in range(scale):
                        piece.putpixel(((x - x0) * scale + dx, (y - y0) * scale + dy), colour)
        pieces.append(piece)
    if len(sys.argv) > 6:
        reference = Image.open(sys.argv[5]).convert("RGB").crop(tuple(int(v) for v in sys.argv[6].split(",")))
        height = pieces[0].height
        pieces.append(reference.resize((int(reference.width * height / reference.height), height)))
    sheet = Image.new("RGB", (sum(p.width for p in pieces) + 8 * len(pieces), pieces[0].height))
    left = 0
    for piece in pieces:
        sheet.paste(piece, (left, 0))
        left += piece.width + 8
    sheet.save(out)


if __name__ == "__main__":
    main()
