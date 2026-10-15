"""gen_cart.py - draws a project's sprites, sprite flags and sounds into its carts.

usage: py gen_cart.py

Rewrites everything from __gfx__ on in the game cart and tests/*.p8, leaving
the Lua alone, and writes sheet.png so the sprites can be looked at.
run_tests.py runs this first. Rename GAME, then add to the pictures below.

Sprites are rows of PICO-8 colour digits; "." is colour 0, transparent.
Art that is a variation of other art (a second animation frame, a near-copy
that differs by a few pixels, a surface built from a repeated piece) is
better made here by a function than drawn again by hand.
"""
import glob
import os
import time

from png import write_png

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = "bal8tro.p8"

# sprite number -> rows. a sprite wider or taller than 8 just has more.
SUITS = {
    1: ("""
...1...
..111..
.11111.
1111111
1111111
.1.1.1.
...1...
..111..
""", """
..1..
.111.
11111
..1..
.111.
"""),
    2: ("""
.88.88.
8888888
8888888
8888888
.88888.
..888..
...8...
.......
""", """
.8.8.
88888
88888
.888.
..8..
"""),
    3: ("""
..333..
..333..
33.3.33
3333333
33.3.33
...3...
..333..
.......
""", """
..3..
.333.
33333
..3..
.333.
"""),
    4: ("""
...9...
..999..
.99999.
9999999
.99999.
..999..
...9...
.......
""", """
..9..
.999.
99999
.999.
..9..
"""),
}

# sprite number -> rows. a sprite wider or taller than 8 just has more.
# big suits are sprites 1..4, small ones 17..20
SPRITES = {}
for suit, (big, small) in SUITS.items():
    SPRITES[suit] = big
    SPRITES[16 + suit] = small
# sprite number -> flag byte (1 is flag 0, 2 is flag 1, ...)
FLAGS = {}

# (speed, notes); a note is (pitch 0..63, waveform, volume, effect)
SOUNDS = [
    (4, [(36, 1, 4, 0), (43, 1, 2, 5)]),                  # 0 chips tick
    (4, [(29, 2, 5, 0), (34, 2, 3, 5)]),                  # 1 mult tick
    (2, [(48, 0, 3, 0), (52, 0, 2, 5)]),                  # 2 pick a card
    (6, [(24, 3, 5, 0), (31, 3, 5, 0), (36, 3, 5, 0),
         (43, 3, 4, 5)]),                                 # 3 hand total
    (1, [(40, 6, 2, 0), (34, 6, 1, 5)]),                  # 4 card dealt
]
# 5..12 chips ticks and 13..20 mult ticks, each a step up a major scale, so
# a long run of scoring steps climbs
SCALE = [0, 2, 4, 5, 7, 9, 11, 12]
SOUNDS += [(4, [(36 + s, 1, 4, 0), (43 + s, 1, 2, 5)]) for s in SCALE]
SOUNDS += [(4, [(29 + s, 2, 5, 0), (34 + s, 2, 3, 5)]) for s in SCALE]
# a pattern is "FF AABBCCDD": flags (1 loop start, 2 loop end), then the
# sfx on each of four channels, 0x40 and over meaning silent
MUSIC = []


def rows_of(text, width):
    rows = text.strip().split("\n")
    for row in rows:
        assert len(row) == width, "row %r is not %d wide" % (row, width)
    return [row.replace(".", "0") for row in rows]


def stamp(sheet, rows, sprite):
    left, top = sprite % 16 * 8, sprite // 16 * 8
    for y, row in enumerate(rows):
        sheet[top + y][left:left + len(row)] = row


def build_gfx():
    sheet = [["0"] * 128 for _ in range(128)]
    for sprite, text in SPRITES.items():
        stamp(sheet, rows_of(text, len(text.strip().split("\n")[0])), sprite)
    return ["".join(row) for row in sheet]


def build_flags():
    flags = "".join("%02x" % FLAGS.get(sprite, 0) for sprite in range(256))
    return [flags[:256], flags[256:]]


def build_sfx():
    lines = []
    for speed, notes in SOUNDS:
        assert len(notes) <= 32
        body = "".join("%02x%x%x%x" % note for note in notes)
        lines.append("00%02x0000" % speed + body.ljust(160, "0"))
    return lines


def write_cart(path, text):
    # opening a cart to write just after a pico-8 that had it loaded was
    # stopped has failed with "invalid argument" and worked a moment later
    for attempt in range(3):
        try:
            with open(path, "w", encoding="utf-8", newline="\n") as handle:
                handle.write(text)
            return
        except OSError:
            if attempt == 2:
                raise
            time.sleep(0.5)


def main():
    gfx = build_gfx()
    write_png(os.path.join(HERE, "sheet.png"), gfx[:64])
    tail = "\n".join(["__gfx__"] + gfx + ["__gff__"] + build_flags()
                     + ["__sfx__"] + build_sfx() + ["__music__"] + MUSIC) + "\n"
    carts = [GAME] + sorted(glob.glob(os.path.join(HERE, "tests", "*.p8")))
    written = 0
    for cart in carts:
        path = os.path.join(HERE, cart)
        with open(path, encoding="utf-8", newline="") as handle:
            before = handle.read()
        after = before.split("__gfx__")[0].rstrip("\n") + "\n" + tail
        # a cart that is already right is left alone
        if after != before:
            write_cart(path, after)
            written += 1
    print("wrote art and sound into %d of %d carts" % (written, len(carts)))


if __name__ == "__main__":
    main()
