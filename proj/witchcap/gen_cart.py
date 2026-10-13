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

# mushrooms are sprites 1..6: odd numbers are the true ingredients, and each
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

# the witch is one sprite wide and two tall, facing right: sprites 32..34
# over 48..50 are a stride, the other stride, and a jump.
WITCH_TOP = """
........
....d...
...dd...
...ddd..
..dddd..
..aaaa..
dddddddd
.9ffff..
.9f1f1..
.9ffff..
..dddd..
.dddddd.
.dddddd.
"""
WITCH_LEGS = [
    """
.dddddd.
..5..5..
..5..55.
""",
    """
.dddddd.
...55...
...55...
""",
    """
dddddddd
.55..55.
........
""",
]

# 36: the cauldron, two sprites square
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

# 44: baba yaga's hut on its chicken legs, two sprites square, drawn at
# twice the size in the backdrop
HUT = """
..........55....
.....5....55....
....555..5555...
...5555555555...
..555555555555..
.55555555555555.
..222222222222..
..222aa2222222..
..222aa2222222..
..222222222222..
....4......4....
...4......4.....
...4......4.....
....4......4....
....4......4....
..444....444....
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


def build_gfx():
    sheet = [["0"] * 128 for _ in range(128)]
    for number, mushroom in enumerate(MUSHROOMS):
        stamp(sheet, rows_of(mushroom, 8), 1 + number)
    for number, tile in enumerate(TILES):
        stamp(sheet, rows_of(tile, 8), 16 + number)
    for number, legs in enumerate(WITCH_LEGS):
        witch = rows_of(WITCH_TOP, 8) + rows_of(legs, 8)
        assert len(witch) == 16
        stamp(sheet, witch, 32 + number)
    stamp(sheet, rows_of(CAULDRON, 16), 36)
    stamp(sheet, rows_of(HUT, 16), 44)
    return ["".join(row) for row in sheet]


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
    write_png(os.path.join(HERE, "sheet.png"), gfx[:64])
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
