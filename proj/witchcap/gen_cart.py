"""gen_cart.py - draws witchcap's sprites, sprite flags and sounds into the carts.

usage: py gen_cart.py

Rewrites everything from __gfx__ on in witchcap.p8 and tests/test_*.p8,
leaving the Lua alone, and writes sheet.png so the sprites can be looked at.
run_tests.py runs this first.

Sprites are rows of PICO-8 colour digits; "." is colour 0, transparent.
"""
import glob
import os
import time

from png import write_png

HERE = os.path.dirname(os.path.abspath(__file__))

# mushrooms come in four families of four forms: 16 kinds, and kind k is
# sprite 95+k, with the sprite below it (111+k) its second dance step,
# made by leaning(). kinds 1..4 are the redcaps, 5..8 the bluecaps, 9..12
# the goldcups and 13..16 the moonpuffs. the forms of a family differ by a
# pixel or two; no form is the good one, the recipe names one each run.
#
# a family is its first form drawn out, and then for each other form the
# pixels that differ, as (x, y, colour). the bottom three rows are the
# stem, which stays put when the cap leans.
MUSHROOM_FAMILIES = [
    # redcaps: four spots; a spot moved; three spots; a grey ring on the stem
    ("""
........
..8888..
.878878.
88888788
87888888
...77...
...77...
..7777..
""", [
        [(5, 3, "8"), (2, 3, "7")],
        [(1, 4, "8")],
        [(3, 5, "6"), (4, 5, "6")],
    ]),
    # bluecaps: shine on the left; shine on the right; gills in the middle;
    # a grey foot
    ("""
...cc...
..cccc..
..c7cc..
.cccccc.
.c1cc1c.
...77...
...77...
...77...
""", [
        [(3, 2, "c"), (4, 2, "7")],
        [(2, 4, "c"), (5, 4, "c"), (3, 4, "1"), (4, 4, "1")],
        [(3, 7, "6"), (4, 7, "6")],
    ]),
    # goldcups: shading inside the rim; shading at the rim; no notch; a
    # pale throat
    ("""
........
a......a
aa9..9aa
.aaaaaa.
..a99a..
...99...
...99...
...99...
""", [
        [(2, 2, "a"), (5, 2, "a"), (1, 2, "9"), (6, 2, "9")],
        [(3, 2, "a"), (4, 2, "a")],
        [(3, 4, "a"), (4, 4, "a")],
    ]),
    # moonpuffs: two dimples; the upper one moved; one dimple; three
    ("""
........
..7777..
.777777.
77d77777
7777d777
.777777.
...66...
..6666..
""", [
        [(2, 3, "7"), (5, 3, "d")],
        [(4, 4, "7")],
        [(5, 2, "d")],
    ]),
]


def mushroom_kinds():
    """The 16 mushrooms in kind order, each as 8 rows."""
    kinds = []
    for first, others in MUSHROOM_FAMILIES:
        rows = rows_of(first, 8)
        kinds.append(rows)
        for changes in others:
            form = [list(row) for row in rows]
            for x, y, colour in changes:
                assert form[y][x] != colour, "a change that changes nothing"
                form[y][x] = colour
            kinds.append(["".join(row) for row in form])
    assert len(set(map(tuple, kinds))) == 16, "two kinds look the same"
    return kinds


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

# 19, 20: a bat for the backdrop, wings up and wings down
BATS = [
    """
........
2.2..2.2
22222222
22e22e22
..2222..
...22...
........
........
""",
    """
........
..2..2..
.222222.
22e22e22
2.2222.2
2..22..2
........
........
""",
]

# the witch is two sprites square, facing right. her seven frames are put
# together from a hat (8 rows), hair and face (3), a dress (3) and a hem
# with legs (2), so that the hat's point and her hair flap as she moves.
# frames are sprites 32, 34 .. 44: standing, four of a walk, rising, falling.
WITCH_HATS = {
    # the point up and trailing
    "up": """
....dd..........
....ddd.........
.....ddd........
......ddd2......
......dddd2.....
.....ddddd2.....
.....aa9aaa.....
..dddddddddddd..
""",
    # the point flopped down behind
    "down": """
................
...ddd..........
....dddd........
......ddd2......
......dddd2.....
.....ddddd2.....
.....aa9aaa.....
..dddddddddddd..
""",
}
WITCH_HAIR = {
    # hanging down her back
    "down": """
...999ffff......
..99.9f1fff.....
.99..ddddd2.....
""",
    # streaming straight out behind
    "out": """
.99999ffff......
9....9f1fff.....
.....ddddd2.....
""",
}
WITCH_DRESS = """
....dddddd2.....
....ddddddd2....
...dddddddd2....
"""
# (hat, hair, hem and legs)
WITCH_FRAMES = [
    ("up", "down", """
..ddddddddd2....
......5..5......
"""),
    ("up", "down", """
..ddddddddd2....
....55....55....
"""),
    ("down", "out", """
..ddddddddd2....
......555.......
"""),
    ("up", "out", """
.dddddddddd2....
...55......55...
"""),
    ("down", "down", """
..ddddddddd2....
.......55.......
"""),
    ("down", "down", """
..ddddddddd2....
....55.55.......
"""),
    ("up", "out", """
dddddddddddd2...
.....5...5......
"""),
]

# 46: the cauldron, two sprites square
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
# the legs and feet are a hen's pink, a colour nothing else in the game
# has, so that a foot planted beside a mushroom, the cauldron or the witch
# does not hide it
HUT_FOOT = """
......ee........
......ef........
.....eee........
.....eefe.......
....eeeeee......
..eeeefeeeeeee7.
7eeee.eeefe.....
......eeeeee7...
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
4f44f44f
44444444
44f44f44
44444444
4f44f442
44444442
44f44f42
.444444.
.4f44f4.
.444442.
.4f4442.
..4444..
..4f42..
..e44e..
...ee...
...ee...
...ee...
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
    (1, []),                                                                 # 7 unused
]

# the tune: cute and spooky. a music-box melody in a minor, a tiptoeing
# bass under it, and on the repeat a wavering ghost of a voice over the
# top. each list is four bars of eight steps; 0 is a rest. pitches count
# semitones from c0, so 45 is the a below middle c.
TUNE_SPEED = 18
MELODY_1 = [45, 0, 48, 0, 52, 0, 48, 0,  47, 0, 50, 0, 53, 0, 50, 0,
            45, 0, 48, 0, 52, 0, 57, 0,  56, 0, 52, 0, 51, 0, 52, 0]
MELODY_2 = [57, 0, 56, 0, 57, 0, 52, 0,  53, 0, 52, 0, 50, 0, 48, 0,
            47, 0, 48, 0, 50, 0, 53, 0,  52, 0, 0, 0, 40, 0, 0, 0]
BASS_1 = [21, 0, 28, 0, 21, 0, 28, 0,  26, 0, 33, 0, 26, 0, 33, 0,
          21, 0, 28, 0, 21, 0, 28, 0,  16, 0, 28, 0, 16, 0, 32, 0]
BASS_2 = [21, 0, 28, 0, 21, 0, 28, 0,  26, 0, 33, 0, 26, 0, 33, 0,
          26, 0, 33, 0, 26, 0, 33, 0,  16, 0, 28, 0, 16, 0, 0, 0]
GHOST = [57] * 8 + [53] * 8 + [52] * 8 + [56] * 8


def voice(pitches, waveform, volume, effect):
    return [(pitch, waveform, volume, effect) if pitch else (0, 0, 0, 0) for pitch in pitches]


SOUNDS += [
    (TUNE_SPEED, voice(MELODY_1, 0, 4, 5)),    # 8: triangle, each note fading
    (TUNE_SPEED, voice(MELODY_2, 0, 4, 5)),    # 9
    (TUNE_SPEED, voice(BASS_1, 1, 2, 5)),      # 10: tilted saw, soft
    (TUNE_SPEED, voice(BASS_2, 1, 2, 5)),      # 11
    (TUNE_SPEED, voice(GHOST, 5, 1, 2)),       # 12: organ with vibrato, faint
]
# four patterns, looping: the tune, then the tune again with the ghost.
# the first byte is 1 where the loop starts and 2 where it ends; a channel
# of 0x40 and over is silent.
MUSIC = [
    "01 080a4344",
    "00 090b4344",
    "00 080a0c44",
    "02 090b0c44",
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
    for number, rows in enumerate(mushroom_kinds()):
        stamp(sheet, rows, 96 + number)
        stamp(sheet, leaning(rows), 112 + number)
    for number, tile in enumerate(TILES + BATS):
        stamp(sheet, rows_of(tile, 8), 16 + number)
    for number, (hat, hair, legs) in enumerate(WITCH_FRAMES):
        witch = (rows_of(WITCH_HATS[hat], 16) + rows_of(WITCH_HAIR[hair], 16)
                 + rows_of(WITCH_DRESS, 16) + rows_of(legs, 16))
        assert len(witch) == 16
        stamp(sheet, witch, 32 + number * 2)
    stamp(sheet, rows_of(CAULDRON, 16), 46)
    # the hut has the lower half of the sheet
    # its long side: windows, and a lantern at the front corner
    stamp(sheet, build_hut(48, [
        (HUT_WINDOW, 8, 8, 7), (HUT_PORTHOLE, 4, 21, 8), (HUT_WINDOW, 8, 29, 7),
        (HUT_LANTERN, 3, 41, 8)]), 128)
    # its front, 32 wide, seen face on in the middle of a turn: the door,
    # with the skull over it
    stamp(sheet, build_hut(32, [
        (HUT_DOOR, 8, 12, 8), (HUT_SKULL, 5, 13, 2), (HUT_PORTHOLE, 4, 5, 9),
        (HUT_LANTERN, 3, 24, 8)]), 134)
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
    rows = ["..eeee..", "..effe..", "..eeee.."]
    for y in range(3, 24):
        rows.append("..." + ("2e" if y % 4 == 3 else "ef" if y % 2 else "ee") + "...")
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
                     + ["__sfx__"] + build_sfx() + ["__music__"] + MUSIC) + "\n"
    carts = ["witchcap.p8"] + sorted(glob.glob(os.path.join(HERE, "tests", "test_*.p8")))
    written = 0
    for cart in carts:
        path = os.path.join(HERE, cart)
        with open(path, encoding="utf-8", newline="") as handle:
            before = handle.read()
        after = before.split("__gfx__")[0].rstrip("\n") + "\n" + tail
        # a cart that is already right is left alone. twice, opening a cart
        # to write just after it had been used failed with "invalid
        # argument" and worked a moment later; the cause is not known.
        if after != before:
            write_cart(path, after)
            written += 1
    print("wrote art and sound into %d of %d carts" % (written, len(carts)))


def write_cart(path, text):
    for attempt in range(3):
        try:
            with open(path, "w", encoding="utf-8", newline="\n") as handle:
                handle.write(text)
            return
        except OSError:
            if attempt == 2:
                raise
            time.sleep(0.5)


if __name__ == "__main__":
    main()
