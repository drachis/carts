"""gen_cart.py - draws Loretta's sprites, level, sounds and music into the carts.

usage: py gen_cart.py

Rewrites everything from __gfx__ on in loretta.p8 and tests/*.p8, leaving
the Lua alone, and writes sheet.png (the sprites) and level.png (the level
as the map will draw it) to look at. run_tests.py runs this first.

Sprites are rows of PICO-8 colour digits; "." is colour 0, transparent.
The screen palette (scenery.lua) shows slots 1, 2, 5 and 15 as navy, plum,
mauve and salmon; png.py draws them that way.
"""
import glob
import os
import time

from png import write_png

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = "loretta.p8"

# colours kept for what the player picks out (DESIGN.md rule 7): Loretta
# orange 9 and white 7, coins yellow 10, squirrels brown 4, hearts red 8,
# water blue 12.

GRASS = """
.b..b.b.
bbbbbbbb
b3bb3bb3
33333333
44443444
44444424
42444444
44444444
"""
DIRT = """
44444444
44424444
44444444
44444442
24444444
44444444
44442444
44444444
"""
# dirt with a vine hanging down it, as in the picture
VINE_DIRT = """
44344444
44344424
44b34444
44434444
24434444
44b44444
44444244
44444444
"""
# a branch, an awning or a plank: she can jump up through it and land on top
BRANCH = """
49999994
44444444
.2.2..2.
........
........
........
........
........
"""
WATER_TOP = """
........
.77..77.
cccccccc
cc1ccccc
cccccc1c
c1cccccc
cccc1ccc
cccccccc
"""
WATER = """
cccccccc
c1cccccc
ccccc1cc
cccccccc
cc1ccccc
ccccccc1
c1cccccc
cccc1ccc
"""
FLOWERS = """
........
........
..e..e..
.ebe.eae
.3b3e3e.
3bb3b33b
b3bbbb3b
3bb33bb3
"""
TUFT = """
........
........
........
........
.....b..
.b..b3..
.3b.3b.b
b3b3bb3b
"""


def sloped(rising_right):
    """A grassy 45 degree slope: dirt cut along the diagonal, grass on the
    cut. Solid on and below the diagonal, as world.lua's flag_at tests."""
    dirt = DIRT.strip().split("\n")
    rows = []
    for y in range(8):
        row = ""
        for x in range(8):
            surface = 7 - x if rising_right else x
            depth = y - surface
            row += "." if depth < 0 else "b" if depth < 1 else "3" if depth < 2 else dirt[y][x]
        rows.append(row)
    return "\n".join(rows)


def mark(colour):
    """A marker the game turns into a thing at the level's start."""
    return "\n".join([colour * 8] + [colour + "......" + colour] * 6 + [colour * 8])


# Loretta, 32x16, facing right: a long orange loaf outlined in brown, a
# peach highlight along her back, white chest, muzzle and socks, big ears
# with pink insides, a green collar with a gold tag, a pink tongue.
BODY = [
    "." * 23 + "4" + "." * 5 + "4" + "..",
    "." * 22 + "494" + "..." + "494" + ".",
    "." * 22 + "49e4" + "." + "4e94" + ".",
    "." * 21 + "49ee99ee94" + ".",
    ".." + "44" + "." * 16 + "4" + "9" * 9 + "4" + ".",
    "." + "4" + "7" + "9" + "4" * 16 + "9" * 11 + ".",
    "." + "4" + "7" + "99" + "f" * 10 + "9" * 5 + "9" * 7 + "0" + "999" + "4",
    "." + "4" + "9" * 18 + "9" * 4 + "7" * 7 + "0",
    "." + "4" + "9" * 17 + "bb" + "999" + "7" * 6 + "6" + ".",
    "." + "4" + "9" * 17 + "bb" + "7" * 8 + "ee" + ".",
    "." + "4" + "9999" + "7" * 13 + "33" + "7" * 6 + "6" + "." + "e" + "..",
    ".." + "4" + "9999" + "7" * 12 + "7" + "a" + "7" * 5 + "6" + "." * 5,
    "..." + "49999" + "6" * 9 + "77777" + "6" + "." * 9,
]
# a bright eye: two by two with a white glint
BODY[5] = BODY[5][:26] + "07" + BODY[5][28:]
BODY[6] = BODY[6][:26] + "00" + BODY[6][28:]
# her legs, three rows under the body: the near ones four wide, the far
# ones two wide and darker, drawn first so the near ones cover them
NEAR_BACK = ["4999", "6777", "6776"]
NEAR_FRONT = ["7776", "7776", "6776"]
FAR_BACK = ["44", "44", "66"]
FAR_FRONT = ["66", "66", "66"]


def legs(*parts):
    """Leg rows from (x, leg, lift): a lifted leg is shorter, its paw raised."""
    rows = [["."] * 32 for _ in range(3)]
    for x, leg, lift in sorted(parts, key=lambda part: len(part[1][0])):
        drawn = leg[:2 - lift] + [leg[2]] if lift else leg
        for y, line in enumerate(drawn):
            for i, colour in enumerate(line):
                rows[y][x + i] = colour
    return ["".join(row) for row in rows]


def corgi(*parts):
    return "\n".join(BODY + legs(*parts))


def edit(text, changes):
    """The picture with (x, y, colours) written over it."""
    rows = [list(row) for row in text.strip().split("\n")]
    for x, y, colours in changes:
        for i, colour in enumerate(colours):
            rows[y][x + i] = colour
    return "\n".join("".join(row) for row in rows)


CORGI_STAND = corgi((9, FAR_BACK, 0), (22, FAR_FRONT, 0), (4, NEAR_BACK, 0), (17, NEAR_FRONT, 0))
# the wag: her fluffy rump nub flicks up a row
CORGI_WAG = edit(CORGI_STAND, [(0, 3, ".44."), (0, 4, "4774"), (0, 5, ".499"), (0, 6, ".499")])
CORGI_RUN_A = corgi((8, FAR_BACK, 1), (24, FAR_FRONT, 1), (2, NEAR_BACK, 0), (20, NEAR_FRONT, 0))
CORGI_RUN_B = corgi((5, FAR_BACK, 0), (19, FAR_FRONT, 0), (8, NEAR_BACK, 1), (14, NEAR_FRONT, 1))
CORGI_JUMP = corgi((5, NEAR_BACK, 1), (9, FAR_BACK, 2), (18, NEAR_FRONT, 1), (22, FAR_FRONT, 2))
# falling and paddling at the air with her short legs: two frames
CORGI_PADDLE_A = corgi((3, NEAR_BACK, 0), (9, FAR_BACK, 2), (19, NEAR_FRONT, 2), (23, FAR_FRONT, 0))
CORGI_PADDLE_B = corgi((6, NEAR_BACK, 2), (8, FAR_BACK, 0), (16, NEAR_FRONT, 0), (22, FAR_FRONT, 2))
# the bark: her jaw drops open
CORGI_BARK = edit(CORGI_STAND, [(29, 8, "00."), (28, 9, "8ee."), (27, 10, "76e..")])
SIT_LEFT = ["." * 19] * 5 + [
    "." * 14 + "4" * 5,
    "." * 11 + "444" + "9" * 5,
    "." * 9 + "44" + "f" * 3 + "9" * 5,
    "." * 7 + "44" + "9" + "fff" + "9" * 6,
    "." * 5 + "44" + "9" * 12,
    "." * 4 + "4" + "9" * 10 + "7" * 4,
    "." * 3 + "4" + "9" * 10 + "7" * 5,
    "." * 3 + "4" + "9" * 9 + "7" * 6,
    ".." + "4" + "9" * 8 + "4" + ".." + "7" * 4 + "6",
    ".." + "4" + "9" * 7 + "4" + "..." + "7" * 4 + "6",
    "." + "6777776" + "." * 6 + "6776" + ".",
]
CORGI_SIT = "\n".join(SIT_LEFT[y] + (BODY[y][19:] if y < 13 else "." * 13) for y in range(16))
# asleep: lying flat, ears down, eyes shut
CORGI_NAP = edit("\n".join(["." * 32] * 5 + BODY[2:]), [(26, 8, "99"), (26, 9, "44")])

# her face for the player card, 16x16
CORGI_FACE = """
.9............9.
.99..........99.
.9e9........9e9.
.9ee9......9ee9.
.9ee99999999ee9.
..9e99977999e9..
..999997799999..
.99909977990999.
.99999777799999.
..999777777999..
..997770077799..
...7777007777...
...777e88e777...
....77eeee77....
.....b7ee7b.....
....bbbaabbb....
"""
COIN = """
................
.....999999.....
...99aaaaaa99...
..9aaa9aa9aaa9..
..9a7a9aa9aaa9..
.9aa9aaaaaa9aa9.
.9a79aa99aa9aa9.
.9aaaa9999aaaa9.
.9aaa999999aaa9.
.9aaa999999aaa9.
.9aaaa9999aaaa9.
..9aaaaaaaaaa9..
..9aaaaaaaa999..
...99aaaaaa99...
.....999999.....
................
"""
BONE = """
................
.77..........77.
7777........7777
.77777777777776.
.66666666666666.
7776........6776
.66..........66.
................
"""
# a squirrel facing right: a big curled tail behind, ears up, a peach belly
SQUIRREL_A = """
..2222..........
.244442.........
24499442........
2499f9942...2...
249f9f9442.242..
2499f942.2444442
2499994224440442
.249994244444ff0
..2494244444ff2.
...24424444fff2.
.....2444444fff.
....24444444fff2
....244444444ff2
.....24444444f2.
....24442..242..
...244442..2442.
"""
SQUIRREL_B = edit(SQUIRREL_A, [(0, 14, ".....2442..242.."), (0, 15, "....24442.2442..")])
# spooked: eyes wide
SQUIRREL_SPOOKED = edit(SQUIRREL_A, [(11, 6, "70"), (14, 7, "8")])
HYDRANT = """
......2222......
.....288882.....
....28877882....
....28888882....
...2222222222...
....28e88882....
..2228e8888222..
..2888e8888882..
..2228e8888222..
....28e88882....
....28e88882....
....28e88882....
....28888882....
...2222222222...
..255555555552..
..222222222222..
"""
HYDRANT_LIT = edit(HYDRANT, [(5, 1, "2aaaa2"), (4, 2, "2aa77aa2"), (4, 3, "2aaaaaa2")])
HEART = """
.88.88..
8778888.
8788888.
8888888.
.88888..
..888...
...8....
........
"""
HEART_EMPTY = """
.22.22..
2..2..2.
2.....2.
2.....2.
.2...2..
..2.2...
...2....
........
"""
SPARKLE = """
........
...7....
...7....
.77a77..
...7....
...7....
........
........
"""
# the neighbour, seen from a corgi's height: only shoes and trouser legs
# (drawn by the game, up off the top of the screen), and a hand that comes
# down to pat her
SHOES = """
................
................
................
.44444...44444..
.444444..444444.
.4444444.4444444
.2222222.2222222
................
"""
HAND = """
..dddd..
.ffffff.
ffffffff
ffffffff
ffffffff
f.f.f.f.
f.f.f.f.
........
"""


def squash(text, width):
    """The picture squeezed to `width` columns, centred: a coin turning."""
    rows = text.strip().split("\n")
    size = len(rows[0])
    left = (size - width) // 2
    out = []
    for row in rows:
        picked = "".join(row[column * size // width] for column in range(width))
        out.append("." * left + picked + "." * (size - width - left))
    return "\n".join(out)


# sprite number -> rows. a sprite wider or taller than 8 just has more.
# Loretta's poses are 4x2 sprites: 32 stand, 36 wag, 40 and 44 run,
# 64 jump, 68 and 72 paddle, 76 sit, 96 bark, 100 nap.
SPRITES = {
    1: GRASS, 2: DIRT, 3: VINE_DIRT, 4: BRANCH, 5: WATER_TOP, 6: WATER,
    7: FLOWERS, 8: TUFT, 9: sloped(True), 10: sloped(False),
    16: mark("9"), 17: mark("4"), 18: mark("d"), 19: mark("a"), 20: mark("7"),
    21: mark("2"), 22: mark("8"), 23: mark("f"),
    32: CORGI_STAND, 36: CORGI_WAG, 40: CORGI_RUN_A, 44: CORGI_RUN_B,
    64: CORGI_JUMP, 68: CORGI_PADDLE_A, 72: CORGI_PADDLE_B, 76: CORGI_SIT,
    96: CORGI_BARK, 100: CORGI_NAP,
    104: SQUIRREL_A, 106: SQUIRREL_B, 108: SQUIRREL_SPOOKED, 110: HYDRANT,
    128: HYDRANT_LIT, 130: COIN, 132: squash(COIN, 8), 134: squash(COIN, 3),
    136: BONE, 138: HEART, 139: HEART_EMPTY, 140: SPARKLE, 141: HAND,
    142: CORGI_FACE, 160: SHOES,
}
# flag 0 solid, 1 semisolid (its top row only), 2 water, 3 a slope rising
# to the right, 4 a slope rising to the left (solid only below the diagonal)
FLAGS = {1: 1, 2: 1, 3: 1, 4: 2, 5: 4, 6: 4, 9: 1 | 8, 10: 1 | 16}

# the level: eight sections of 32 by 16 tiles, side by side. the first four
# are map rows 0..15, the last four map rows 16..31 (world.lua joins them).
#   # ground (grass on top, dirt under)   / \ grassy slopes
#   = branch or awning (jump up through it)    ~ water
#   o paw coin    b bone     s squirrel   h hydrant    n neighbour
#   L Loretta's start   S the Los Feliz sign   G the observatory
#   f flowers   , a grass tuft
# a thing's letter goes in the cell it stands in.
GROUND = "#" * 32
EMPTY = "." * 32
STREET = [EMPTY] * 8 + [
    "." * 16 + "oooo" + "." * 12,
    "." * 14 + "=" * 8 + "." * 10,
    EMPTY,
    ".L....S.....o.o.o.....f...s.....",
] + [GROUND] * 4
LAWNS = [EMPTY] * 10 + [
    "." * 9 + "/" + "#" * 8 + "\\" + "." * 13,
    "." * 8 + "/" + "#" * 10 + "\\" + "..." + "h" + "...." + "s" + "...",
] + [GROUND] * 4
LAWNS[8] = "." * 11 + "o.o.o" + "." * 16
STREAM = [EMPTY] * 6 + [
    "." * 15 + "oooo" + "." * 13,
    "." * 17 + "b" + "." * 14,
    "." * 14 + "=" * 6 + "." * 12,
    "." * 7 + "oooo" + "." * 11 + "oooo" + "." * 6,
    "." * 6 + "=" * 6 + "." * 9 + "=" * 6 + "." * 5,
    EMPTY,
] + ["####" + "." * 24 + "####"] * 2 + ["####" + "~" * 24 + "####"] * 2
YARD = [EMPTY] * 7 + [
    "." * 18 + "oooooo" + "." * 8,
    "." * 17 + "=" * 8 + "." * 7,
    EMPTY,
    EMPTY,
    "..h...ff....n.......s.....f..s..",
] + [GROUND] * 4
TRAILHEAD = [EMPTY] * 7 + [
    "." * 18 + "o.o.o.o" + "." + "s" + "." * 5,
    "." * 15 + "/" + "#" * 16,
    "." * 10 + "o.o" + "." + "/" + "#" * 17,
    "." * 7 + "/" + "#" * 24,
    "." * 6 + "/" + "#" * 25,
] + [GROUND] * 4
RAVINE = [EMPTY] * 6 + [
    "." * 11 + "oooooo" + "." * 15,
    "..h" + "." * 21 + "s" + "." * 7,
    "#" * 10 + ".." + "====" + ".." + "#" * 14,
] + ["#" * 10 + "." * 8 + "#" * 14] * 5 + ["#" * 10 + "~" * 8 + "#" * 14] * 2
SWITCHBACK = [EMPTY] * 7 + [
    "." * 26 + "o.o.o" + ".",
    "#" * 8 + "\\" + "." * 14 + "/" + "#" * 8,
    "#" * 9 + "\\" + "..." + "n" + "." * 8 + "/" + "#" * 9,
] + [GROUND] * 6
LAWN_TOP = [EMPTY] * 7 + [
    "....f.....s.......G.......f.....",
] + [GROUND] * 8
LEVEL_SECTIONS = [STREET, LAWNS, STREAM, YARD, TRAILHEAD, RAVINE, SWITCHBACK, LAWN_TOP]
LETTER_TILES = {".": 0, "=": 4, "f": 7, ",": 8, "/": 9, "\\": 10,
                "L": 16, "S": 17, "G": 18, "o": 19, "b": 20, "s": 21, "h": 22, "n": 23}


def level_rows():
    rows = ["" for _ in range(16)]
    for section in LEVEL_SECTIONS:
        assert len(section) == 16, "a section has %d rows" % len(section)
        for y, row in enumerate(section):
            assert len(row) == 32, "row %r is not 32 wide" % row
            rows[y] += row
    return rows


def level_tiles(rows):
    tiles = []
    for y, row in enumerate(rows):
        line = []
        for x, letter in enumerate(row):
            above = rows[y - 1][x] if y > 0 else "."
            if letter == "#":
                tile = 1 if above not in "#/\\" else (3 if (x * 7 + y * 3) % 11 == 0 else 2)
            elif letter == "~":
                tile = 5 if above != "~" else 6
            else:
                tile = LETTER_TILES[letter]
            line.append(tile)
        tiles.append(line)
    return tiles


# (speed, notes); a note is (pitch 0..63, waveform, volume, effect).
# pitch 48 is middle c. waveforms: 0 triangle, 1 tilted saw, 2 saw,
# 3 square, 4 pulse, 5 organ, 6 noise, 7 phaser. effects: 1 slide,
# 2 vibrato, 3 drop, 4 fade in, 5 fade out.
REST = (0, 0, 0, 0)
SOUNDS = [
    (2, [(26, 1, 3, 0), (31, 1, 3, 0), (36, 1, 2, 0)]),                      # 0 jump
    (2, [(18, 6, 2, 0), (12, 6, 1, 0)]),                                     # 1 land
    (3, [(52, 3, 3, 0), (57, 3, 3, 0), (57, 3, 2, 5)]),                      # 2 coin
    (3, [(31, 2, 5, 0), (27, 2, 5, 0), (23, 6, 4, 3)]),                      # 3 bark
    (2, [(20, 1, 5, 0), (30, 1, 4, 0), (40, 1, 3, 0), (45, 1, 2, 0)]),       # 4 stomp
    (3, [(50, 0, 5, 0), (44, 0, 4, 3), (38, 0, 3, 3)]),                      # 5 hurt: a yip
    (3, [(30, 6, 3, 0), REST, (28, 6, 3, 0), REST, (32, 6, 3, 0)]),          # 6 munch
    (4, [(48, 0, 3, 0), (52, 0, 3, 0), (55, 0, 3, 0), (60, 0, 3, 5)]),       # 7 petted
    (4, [(40, 4, 3, 0), (47, 4, 3, 0), (52, 4, 3, 0), (59, 4, 2, 5)]),       # 8 checkpoint
    (2, [(36, 0, 1, 0), (40, 0, 1, 0), (36, 0, 1, 0), (40, 0, 1, 0)]),       # 9 paddle
    (3, [(30, 6, 5, 3), (24, 6, 4, 3), (18, 6, 3, 3)]),                      # 10 splash
    (10, [(36, 0, 4, 1), (43, 0, 5, 1), (48, 0, 5, 2), (48, 0, 4, 2),
          (47, 0, 3, 5)]),                                                   # 11 howl
    (2, [(60, 4, 2, 0), (58, 4, 2, 0), (60, 4, 2, 0), (57, 4, 1, 0)]),       # 12 chitter
    (10, [(36, 0, 4, 0), (32, 0, 4, 0), (28, 0, 4, 0), (24, 0, 3, 5)]),      # 13 game over
    (2, [(48, 3, 2, 0), (55, 3, 2, 5)]),                                     # 14 menu
    (2, [(40, 0, 1, 1), (48, 0, 1, 5)]),                                     # 15 sit
]

# the stroll: a jaunty tune in c major for a walk at sunset. four bars of
# eight steps to a sound; 0 is a rest.
TUNE_SPEED = 14
MELODY_1 = [52, 0, 55, 0, 60, 0, 57, 55,  57, 0, 53, 0, 57, 0, 60, 0,
            59, 0, 55, 0, 62, 0, 59, 0,  60, 0, 55, 0, 52, 0, 0, 0]
MELODY_2 = [57, 0, 60, 0, 64, 0, 62, 60,  60, 0, 57, 0, 53, 0, 57, 0,
            55, 0, 57, 0, 59, 0, 62, 0,  60, 0, 0, 0, 0, 0, 0, 0]
BASS_1 = [24, 0, 31, 0, 24, 0, 31, 0,  29, 0, 36, 0, 29, 0, 36, 0,
          31, 0, 38, 0, 31, 0, 38, 0,  24, 0, 31, 0, 24, 0, 28, 0]
BASS_2 = [33, 0, 40, 0, 33, 0, 40, 0,  29, 0, 36, 0, 29, 0, 36, 0,
          31, 0, 38, 0, 31, 0, 38, 0,  24, 0, 31, 0, 24, 0, 31, 0]
DRUMS = [(10, 6, 3, 0), REST, (50, 6, 1, 0), REST] * 8


def voice(pitches, waveform, volume, effect):
    return [(pitch, waveform, volume, effect) if pitch else REST for pitch in pitches]


SOUNDS += [
    (TUNE_SPEED, voice(MELODY_1, 4, 3, 5)),    # 16: pulse, each note fading
    (TUNE_SPEED, voice(MELODY_2, 4, 3, 5)),    # 17
    (TUNE_SPEED, voice(BASS_1, 1, 3, 0)),      # 18: tilted saw
    (TUNE_SPEED, voice(BASS_2, 1, 3, 0)),      # 19
    (TUNE_SPEED, DRUMS),                       # 20: a soft kick and hat
]
# two patterns, looping. the first byte is 1 where the loop starts and 2
# where it ends; a channel of 0x40 and over is silent.
MUSIC = [
    "01 10121444",
    "02 11131444",
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
    for sprite, text in SPRITES.items():
        stamp(sheet, rows_of(text, len(text.strip().split("\n")[0])), sprite)
    return ["".join(row) for row in sheet]


def build_flags():
    flags = "".join("%02x" % FLAGS.get(sprite, 0) for sprite in range(256))
    return [flags[:256], flags[256:]]


def build_map(tiles):
    """Columns 0..127 of the level in map rows 0..15, 128..255 in 16..31."""
    lines = []
    for strip in range(2):
        for row in tiles:
            lines.append("".join("%02x" % tile for tile in row[strip * 128:strip * 128 + 128]).ljust(256, "0"))
    return lines


def level_picture(gfx, tiles):
    """The level as the map draws it, over a plain sky, one pixel a pixel."""
    picture = []
    for y in range(len(tiles) * 8):
        row = []
        for x in range(len(tiles[0]) * 8):
            tile = tiles[y // 8][x // 8]
            colour = gfx[tile // 16 * 8 + y % 8][tile % 16 * 8 + x % 8] if tile else "0"
            row.append("2" if colour == "0" else colour)
        picture.append("".join(row))
    return picture


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
    tiles = level_tiles(level_rows())
    write_png(os.path.join(HERE, "sheet.png"), gfx[:128])
    write_png(os.path.join(HERE, "level.png"), level_picture(gfx, tiles), 1)
    tail = "\n".join(["__gfx__"] + gfx + ["__gff__"] + build_flags()
                     + ["__map__"] + build_map(tiles)
                     + ["__sfx__"] + build_sfx() + ["__music__"] + MUSIC) + "\n"
    carts = [GAME] + sorted(glob.glob(os.path.join(HERE, "tests", "*.p8")))
    written = 0
    for cart in carts:
        path = os.path.join(HERE, cart)
        with open(path, encoding="utf-8", newline="") as handle:
            before = handle.read()
        after = before.split("__gfx__")[0].rstrip("\n") + "\n" + tail
        if after != before:
            write_cart(path, after)
            written += 1
    print("wrote art and sound into %d of %d carts" % (written, len(carts)))


if __name__ == "__main__":
    main()
