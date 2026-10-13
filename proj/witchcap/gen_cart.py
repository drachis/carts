"""gen_cart.py - draws witchcap's sprites, sprite flags and sounds into the carts.

usage: py gen_cart.py

Rewrites everything from __gfx__ on in witchcap.p8 and tests/test_*.p8,
leaving the Lua alone, and writes sheet.png so the sprites can be looked at.
run_tests.py runs this first.

Sprites are rows of PICO-8 colour digits; "." is colour 0, transparent.
"""
import glob
import os

from png import write_png

HERE = os.path.dirname(os.path.abspath(__file__))

# mushroom kind k is sprite 95+k, and the sprite below it (111+k) is its
# second dance step, made by leaning(). odd kinds are the true ingredients, and each
# even number is the lookalike of the one before it, differing in one detail.
MUSHROOMS = [
    # 1 redcap: white spots
    """
........
..8888..
.878878.
88888788
87888888
...77...
...77...
..7777..
""",
    # 2 false redcap: no spots
    """
........
..8888..
.888888.
88888888
88888888
...77...
...77...
..7777..
""",
    # 3 bluecap: pale stem
    """
...cc...
..cccc..
..c7cc..
.cccccc.
.c1cc1c.
...77...
...77...
...77...
""",
    # 4 false bluecap: dark stem
    """
...cc...
..cccc..
..c7cc..
.cccccc.
.c1cc1c.
...dd...
...dd...
...dd...
""",
    # 5 goldcup: a funnel
    """
........
a......a
aa9..9aa
.aaaaaa.
..a99a..
...99...
...99...
...99...
""",
    # 6 false goldcup: a dome
    """
........
..aaaa..
.aa9aaa.
aaaaaaaa
a9aaaa9a
...99...
...99...
...99...
""",
]

# tiles from sprite 16; flag 0 is solid ground, flag 1 a branch that can be
# jumped up through and stood on.
TILES = [
    # 16 grass
    """
3b33b333
33333b33
43343343
44444444
44544444
44444454
45444444
44444444
""",
    # 17 earth
    """
44444444
44454444
44444444
45444424
44444444
44424444
44444454
44444444
""",
    # 18 branch
    """
3b3b33b3
b3333b33
44444444
42444244
.222222.
........
........
........
""",
]
TILE_FLAGS = {16: 1, 17: 1, 18: 2}

# the witch is two sprites square, facing right: sprites 32, 34 and 36 are
# a stride, the other stride, and a jump. the hat's point trails behind
# her, and so does her hair.
WITCH_TOP = """
....dd..........
....ddd.........
.....ddd........
......ddd2......
......dddd2.....
.....ddddd2.....
.....aa9aaa.....
..dddddddddddd..
...999ffff......
..99.9f1fff.....
.99..ddddd2.....
....dddddd2.....
....ddddddd2....
...dddddddd2....
"""
WITCH_LEGS = [
    """
..ddddddddd2....
....55....55....
""",
    """
..ddddddddd2....
......555.......
""",
    """
.dddddddddd2....
...55....55.....
""",
]

# 38: the cauldron, two sprites square
CAULDRON = """
................
................
....66666666....
...6bbbbbbbb6...
..65b3bbbb3b56..
..555555555555..
.55555555555555.
.55565555555555.
.55655555555555.
.55655555555555.
.55555555555555.
..555555555555..
...5555555555...
..55..9aa9..55..
..55.9a99a9.55..
....99999999....
"""

# baba yaga's hut is the big picture of the game. it is drawn at twice the
# size, facing right, in the lower half of the sheet: the body (sprite
# 128, 48 by 20: what shows of it below the top of the screen), a foot
# (sprite 140, 16 by 8, the ankle at its top), and the two halves of a leg
# (sprites 142 and 143, each with two more below it).
# the body is built by build_hut() from these details.
HUT_WINDOW = """
55555555
5aa55aa5
5a955a95
55555555
5aa55aa5
5a955a95
55555555
66666666
"""
HUT_PORTHOLE = """
.55.
5aa5
5a95
.55.
"""
HUT_DOOR = """
..5555..
.522225.
52222225
52d22d25
52222225
52222a25
52d22d25
52222225
52222225
"""
HUT_SKULL = """
.777.
71717
77777
.7.7.
"""
HUT_LANTERN = """
.5.
5a5
aaa
5a5
"""
# the legs and feet are slate grey, a colour no mushroom has, so that a
# foot planted beside a mushroom does not hide it
HUT_FOOT = """
......55........
......56........
.....555........
.....5565.......
....555555......
..5555655555557.
75555.55565.....
......5555557...
"""
# a leg is two pictures, each one sprite wide and three long, which the
# game stretches along the bone from joint to joint: a hen's feathered
# thigh, widest at the hip, and under it a scaly shank with the knee at
# its top (made by build_shank()).
HUT_THIGH = """
.444444.
44f44f44
44444444
4f44f44f
44444444
44f44f44
44444444
4f44f442
44444442
.4f44f42
.444444.
.4f44f4.
.444442.
..4f44..
..4444..
..4f42..
..4444..
...44...
..5445..
...55...
...55...
...55...
...55...
...55...
"""

# (speed, notes); a note is (pitch 0..63, waveform, volume, effect)
SOUNDS = [
    (3, [(24, 0, 3, 0), (30, 0, 3, 0), (36, 0, 2, 0)]),                      # 0 jump
    (4, [(36, 1, 4, 0), (43, 1, 4, 0), (48, 1, 3, 0)]),                      # 1 pick
    (5, [(20, 0, 5, 3), (12, 0, 4, 3), (24, 5, 3, 0)]),                      # 2 into the pot
    (6, [(18, 2, 5, 2), (15, 2, 5, 2), (12, 2, 5, 2), (9, 2, 4, 2),
         (6, 2, 3, 2)]),                                                     # 3 poisoned
    (8, [(24, 5, 4, 0), (28, 5, 4, 0), (31, 5, 4, 0), (36, 5, 5, 0),
         (40, 5, 5, 0), (43, 5, 4, 0), (48, 5, 3, 0)]),                      # 4 brewed
    (10, [(16, 0, 4, 0), (13, 0, 4, 0), (10, 0, 4, 0), (6, 0, 3, 0)]),       # 5 out of time
    (3, [(10, 4, 3, 0), (8, 4, 2, 0)]),                                      # 6 not needed
]


def rows_of(text, width):
    rows = text.strip().split("\n")
    for row in rows:
        assert len(row) == width, "row %r is not %d wide" % (row, width)
    return [row.replace(".", "0") for row in rows]


def stamp(sheet, rows, sprite):
    left, top = sprite % 16 * 8, sprite // 16 * 8
    for y, row in enumerate(rows):
        sheet[top + y][left:left + len(row)] = row


def leaning(rows):
    """A mushroom's second dance step: its cap a pixel to the right of its stem.

    The bottom three rows of every mushroom are its stem and stay put.
    """
    return ["0" + row[:-1] for row in rows[:-3]] + rows[-3:]


def build_gfx():
    sheet = [["0"] * 128 for _ in range(128)]
    for number, mushroom in enumerate(MUSHROOMS):
        rows = rows_of(mushroom, 8)
        stamp(sheet, rows, 96 + number)
        stamp(sheet, leaning(rows), 112 + number)
    for number, tile in enumerate(TILES):
        stamp(sheet, rows_of(tile, 8), 16 + number)
    for number, legs in enumerate(WITCH_LEGS):
        witch = rows_of(WITCH_TOP, 16) + rows_of(legs, 16)
        assert len(witch) == 16
        stamp(sheet, witch, 32 + number * 2)
    stamp(sheet, rows_of(CAULDRON, 16), 38)
    # the hut has the lower half of the sheet
    stamp(sheet, build_hut(48, [
        (HUT_WINDOW, 8, 9, 7), (HUT_PORTHOLE, 4, 22, 8), (HUT_DOOR, 8, 31, 8),
        (HUT_SKULL, 5, 32, 3), (HUT_LANTERN, 3, 41, 8)]), 128)
    stamp(sheet, rows_of(HUT_FOOT, 16), 140)
    stamp(sheet, rows_of(HUT_THIGH, 8), 142)
    stamp(sheet, build_shank(), 143)
    return ["".join(row) for row in sheet]


def build_hut(width, details):
    """A view of the hut's body, 20 rows: a thatch eave, a wall of logs, a floor.

    `details` are (text, width, left, top) pictures laid over the wall.
    """
    body = [["0"] * width for _ in range(20)]
    # the eave: four rows of thatch with a ragged lower edge
    for y in range(4):
        for x in range(width):
            if y < 3 or x % 3:
                body[y][x] = "6" if (x * 3 + y * 5) % 7 == 0 else "5"
    # the wall: logs four rows deep with dark seams between, and their
    # pale sawn ends at the two corners
    for y in range(4, 17):
        seam = (y - 4) % 4 == 3
        for x in range(3, width - 3):
            knot = (x * 5 + y * 3) % 41 == 0
            body[y][x] = "2" if seam else "9" if knot else "4"
        if not seam:
            for x in (2, 3, width - 4, width - 3):
                body[y][x] = "f"
    # the floor, wider than the wall, with joists and things hanging
    for x in range(width):
        body[17][x] = "5"
        if 0 < x < width - 1:
            body[18][x] = "6" if x % 6 == 0 else "2"
        if x % 9 == 4:
            body[19][x] = "5"
    for text, detail_width, left, top in details:
        for y, row in enumerate(rows_of(text, detail_width)):
            for x, colour in enumerate(row):
                if colour != "0":
                    body[top + y][left + x] = colour
    return ["".join(row) for row in body]


def build_shank():
    """The lower leg, 8 by 24: a knob of a knee, then scales with darker bands."""
    rows = ["..5555..", "..5665..", "..5555.."]
    for y in range(3, 24):
        rows.append("..." + ("25" if y % 4 == 3 else "56" if y % 2 else "55") + "...")
    return [row.replace(".", "0") for row in rows]


def build_flags():
    flags = "".join("%02x" % TILE_FLAGS.get(sprite, 0) for sprite in range(256))
    return [flags[:256], flags[256:]]


def build_sfx():
    lines = []
    for speed, notes in SOUNDS:
        assert len(notes) <= 32
        body = "".join("%02x%x%x%x" % note for note in notes)
        lines.append("00%02x0000" % speed + body.ljust(160, "0"))
    return lines


def main():
    gfx = build_gfx()
    write_png(os.path.join(HERE, "sheet.png"), gfx[:96])
    tail = "\n".join(["__gfx__"] + gfx + ["__gff__"] + build_flags()
                     + ["__sfx__"] + build_sfx()) + "\n"
    carts = ["witchcap.p8"] + sorted(glob.glob(os.path.join(HERE, "tests", "test_*.p8")))
    for cart in carts:
        path = os.path.join(HERE, cart)
        with open(path, encoding="utf-8") as handle:
            lua = handle.read().split("__gfx__")[0]
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(lua.rstrip("\n") + "\n" + tail)
    print("wrote art and sound into %d carts" % len(carts))


if __name__ == "__main__":
    main()
