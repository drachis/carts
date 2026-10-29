"""gen_cart.py - draws Loretta's sprites, level, sounds and music into the carts.

usage: py gen_cart.py

Rewrites everything from __gfx__ on in loretta.p8 and tests/*.p8, leaving
the Lua alone, and writes sheet.png (the sprites) and level.png (the level
as the map will draw it) to look at. run_tests.py runs this first.

Sprites are rows of PICO-8 colour digits; "." is colour 0, transparent.
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
# a branch or a plank: she can jump up through it and land on top
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
# markers the game turns into things: the observatory gate and the sign
GATE_MARK = """
dddddddd
d......d
d......d
d......d
d......d
d......d
d......d
dddddddd
"""
SIGN_MARK = """
44444444
4......4
44444444
...44...
...44...
...44...
...44...
...44...
"""

# Loretta, 16x8, facing right: a long orange sausage, white socks, chest
# and muzzle, a green collar with a yellow tag, a pink tongue
CORGI_STAND = """
..........9...9.
..........9e.e9.
.7.999999999999.
.799999999b9909.
..99999999b97770
..97777777a777e.
..99....77...e..
..77....77......
"""
CORGI_RUN_A = """
..........9...9.
..........9e.e9.
.7.999999999999.
.799999999b9909.
..99999999b97770
..97777777a777e.
.99......77..e..
7.........77....
"""
CORGI_RUN_B = """
..........9...9.
..........9e.e9.
.7.999999999999.
.799999999b9909.
..99999999b97770
..97777777a777e.
...99..77....e..
....7.77........
"""
# in the air: ears swept back, legs tucked under
CORGI_JUMP = """
.........99..9..
..........9e9e9.
.7.999999999999.
.799999999b9909.
..99999999b97770
..97777777a777e.
...997..777.....
................
"""
# falling and paddling at the air with her short legs: two frames
CORGI_PADDLE_A = """
..........9...9.
..........9e.e9.
.7.999999999999.
.799999999b9909.
..99999999b97770
..97777777a777e.
..9.9...7.7..e..
..7.....7.......
"""
CORGI_PADDLE_B = """
..........9...9.
..........9e.e9.
.7.999999999999.
.799999999b9909.
..99999999b97770
..97777777a777e.
...9.9...7.7.e..
.....7.....7....
"""
CORGI_SIT = """
.........9..9...
.........9e.e9..
.........99999..
.........99099..
........b997770.
...999999a7777e.
.7999997777777..
..777....77.77..
"""
CORGI_NAP = """
................
................
................
...........9..9.
..999999999999..
.79999999b900970
..7777777a77777.
.77.......777...
"""
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
..9999..
.9aaaa9.
9a9a9aa9
9aaaa9a9
9a999aa9
9a999aa9
.9aaaa9.
..9999..
"""
COIN_EDGE = """
...99...
...9a...
...9a...
...9a...
...9a...
...9a...
...9a...
...99...
"""
BONE = """
........
........
76....76
.777777.
.766667.
76....76
........
........
"""
# a squirrel facing right: a big curled tail behind, ears up
SQUIRREL_A = """
.44.....
4994..4.
49.9.444
.49.4404
..94444f
..4444f.
..444f4.
..4..4..
"""
SQUIRREL_B = """
.44.....
4994..4.
49.9.444
.49.4404
..94444f
..4444f.
.444ff4.
.4....4.
"""
# spooked: tail straight up, standing tall
SQUIRREL_SPOOKED = """
.4....4.
.4...444
49..4704
49..444f
.4.4444f
..4444f.
..444f4.
.4....4.
"""
HYDRANT = """
...88...
..8778..
.888888.
888e8888
.88e888.
..8e88..
..8888..
.222222.
"""
HYDRANT_LIT = """
...aa...
..8aa8..
.888888.
888e8888
.88e888.
..8e88..
..8888..
.222222.
"""
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
# a neighbour in a sun hat, 8x16; the second frame waves
NEIGHBOUR = """
..eeee..
.eeeeee.
eeeeeeee
..ffff..
..f0f0..
..ffff..
...ff...
.dddddd.
fddddddf
fddddddf
.dddddd.
.dddddd.
..5555..
..5..5..
..5..5..
.44..44.
"""
NEIGHBOUR_WAVE = """
..eeee..
.eeeeeef
eeeeeeef
..ffff.f
..f0f0.d
..ffff.d
...ff..d
.ddddddd
fdddddd.
fdddddd.
.dddddd.
.dddddd.
..5555..
..5..5..
..5..5..
.44..44.
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


def wag(text):
    """The tail nub moved down a row: the idle wag's second frame."""
    rows = text.strip().split("\n")
    rows[2] = "." + "." + rows[2][2:]
    rows[3] = "7" + "." + rows[3][2:]
    return "\n".join(rows)


def barking(text):
    """Her jaw dropped open: the bark."""
    rows = [list(row) for row in text.strip().split("\n")]
    rows[4][15] = "0"
    rows[5][13], rows[5][14], rows[5][15] = "7", "8", "8"
    rows[6][13] = "7"
    return "\n".join("".join(row) for row in rows)


# sprite number -> rows. a sprite wider or taller than 8 just has more.
SPRITES = {
    1: GRASS, 2: DIRT, 3: VINE_DIRT, 4: BRANCH, 5: WATER_TOP, 6: WATER,
    7: FLOWERS, 8: TUFT, 10: GATE_MARK, 11: SIGN_MARK,
    16: CORGI_STAND, 18: wag(CORGI_STAND), 20: CORGI_RUN_A, 22: CORGI_RUN_B,
    24: CORGI_JUMP, 26: CORGI_PADDLE_A, 28: CORGI_PADDLE_B, 30: CORGI_SIT,
    32: barking(CORGI_STAND), 34: CORGI_NAP,
    36: COIN, 37: squash(COIN, 4), 38: COIN_EDGE, 39: BONE,
    40: SQUIRREL_A, 41: SQUIRREL_B, 42: SQUIRREL_SPOOKED,
    43: HYDRANT, 44: HYDRANT_LIT, 45: HEART, 46: HEART_EMPTY, 47: SPARKLE,
    48: NEIGHBOUR, 49: NEIGHBOUR_WAVE, 50: CORGI_FACE,
}
# flag 0 solid, flag 1 semisolid (its top row only), flag 2 water
FLAGS = {1: 1, 2: 1, 3: 1, 4: 2, 5: 4, 6: 4}

# the level, as sections of sixteen rows laid side by side.
#   # ground (grass on top, dirt under)   = branch (jump up through it)
#   ~ water          o paw coin    b bone     s squirrel   h hydrant
#   n neighbour      L Loretta's start        S the Los Feliz sign
#   G the observatory gate   f flowers   , a grass tuft
EMPTY = "." * 24
STREET = [EMPTY] * 7 + [
    "..............ooo.......",
    EMPTY,
    ".............=====......",
    EMPTY,
    ".L..S....f.o.o.o..s.,...",
] + ["#" * 24] * 4
POND = [EMPTY] * 7 + [
    "..........ooo...........",
    "......................b.",
    "..........o.o......####.",
    "...................####.",
    "..h..f.,..........#####s",
    "#########....###########",
    "#########....###########",
    "#########~~~~###########",
    "#########~~~~###########",
]
BRANCHES = [EMPTY] * 6 + [
    "...........ooo..........",
    EMPTY,
    "..........=====.........",
    EMPTY,
    "....ooo.........ooo.....",
    "...=====.......=====....",
    "##..................####",
    "##..................####",
    "##~~~~~~~~~~~~~~~~~~####",
    "##~~~~~~~~~~~~~~~~~~####",
]
YARD = [EMPTY] * 6 + [
    "................ooooo...",
    EMPTY,
    "...............=======..",
    EMPTY,
    EMPTY,
    "..h..ff...n....s.....f..",
] + ["#" * 24] * 4
HILL = ["." * 32] * 3 + [
    "...............ooo..............",
    "." * 32,
    ".........ooo.......s...G...f....",
    "..................##############",
    "..............b...##############",
    "...ooo......####################",
    "............####################",
    "......##########################",
    ".h....##########################",
] + ["#" * 32] * 4
LEVEL_SECTIONS = [STREET, POND, BRANCHES, YARD, HILL]
LETTER_TILES = {".": 0, "=": 4, "f": 7, ",": 8, "G": 10, "S": 11, "L": 16,
                "o": 36, "b": 39, "s": 40, "h": 43, "n": 48}


def level_rows():
    rows = ["" for _ in range(16)]
    for section in LEVEL_SECTIONS:
        assert len(section) == 16, "a section has %d rows" % len(section)
        width = len(section[0])
        for y, row in enumerate(section):
            assert len(row) == width, "row %r is not %d wide" % (row, width)
            rows[y] += row
    assert len(rows[0]) <= 128
    return rows


def level_tiles(rows):
    tiles = []
    for y, row in enumerate(rows):
        line = []
        for x, letter in enumerate(row):
            above = rows[y - 1][x] if y > 0 else "."
            if letter == "#":
                tile = 1 if above != "#" else (3 if (x * 7 + y * 3) % 11 == 0 else 2)
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
    lines = []
    for y in range(32):
        row = tiles[y] if y < len(tiles) else []
        lines.append("".join("%02x" % tile for tile in row).ljust(256, "0"))
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
    write_png(os.path.join(HERE, "sheet.png"), gfx[:64])
    write_png(os.path.join(HERE, "level.png"), level_picture(gfx, tiles), 2)
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
