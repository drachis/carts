"""gen_cart.py - draws crestbeat's sprites, sounds and music into its carts.

usage: py gen_cart.py

Rewrites everything from __gfx__ on in crestbeat.p8 and tests/*.p8, leaving
the Lua alone, and writes sheet.png so the sprites can be looked at.
run_tests.py runs this first.

Sprites are rows of PICO-8 colour digits; "." is colour 0, transparent.
Symmetrical things are drawn as their left half and mirrored.

    alien      16x16 at (0,0) and (16,0), two hop frames
    civilian   16x16 at (32,0) and (48,0), arms up, fleeing
    robot      24x24 at (0,64) and (24,64), hivefall's mech in red

The music is 120 BPM: sfx speed 15, a note a quarter beat, 32 notes (eight
beats) a pattern. Channel 0 is the drums, and the game reads its note
number to keep its clock on the beat, so every pattern has drums on 0.
"""
import glob
import os
import time

from png import write_png

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = "crestbeat.p8"

CIVILIAN = """
..f.....
..f..444
..7.4444
..7.4f0f
..77ffff
...777ff
....7777
....7777
....7777
....7c77
....1111
....11..
....11..
....11..
...555..
........
"""

ALIEN = """
......33
....33bb
..33bbbb
3bbbbbbb
3bb00bbb
3bbbb00b
3bbb77bb
3bbb70bb
3bbbbbbb
3bbbb000
3bbb0bbb
..33bbbb
....33bb
......33
...e..e.
..e...e.
"""
ALIEN_LEGS = """
....e.e.
...e.e..
"""

MECH = """
............
............
............
.........555
.......5566d
......566ddd
.....55666d9
.....56666d9
.....566666d
.....5666dd1
..5555d6dd1a
.5666d5ddd11
566ddd55dddd
5ddd5..5ddd5
.55....56dd5
......566d55
.....5666d5.
.....566dd5.
.....56ddd5.
.....5dddd5.
......5dd5..
......5115..
......5995..
............
"""
# hivefall's greys turned red: light grey to red, lavender to dark red
RED = str.maketrans({"6": "8", "d": "2"})

REST = (0, 0, 0, 0)
KICK, HAT, SNARE = (10, 0, 6, 3), (50, 6, 2, 0), (32, 6, 4, 0)
DRUMS = ([KICK, REST, HAT, REST] + [SNARE, REST, HAT, HAT]) * 4
BASS = [14, 21, 14, 21, 19, 26, 21, 28, 14, 21, 14, 21, 19, 26, 21, 14]
TUNE_A = [45, 47, 45, 42, 38, 40, 42, 45, 47, 45, 42, 38, 40, 42, 40, 38]
TUNE_B = [50, 49, 47, 45, 47, 45, 42, 40, 42, 45, 47, 50, 45, 42, 40, 38]


def eighths(pitches, wave, volume):
    """Each pitch is an eighth note: struck, then fading, over two quarter beats."""
    notes = []
    for pitch in pitches:
        notes += [(pitch, wave, volume, 0), (pitch, wave, volume, 5)]
    return notes


# (speed, notes); a note is (pitch 0..63, waveform, volume, effect)
SOUNDS = [
    (2, [(52, 3, 6, 0), (60, 4, 5, 0), (48, 3, 4, 3), (40, 3, 3, 3)]),        # 0 perfect shot
    (2, [(40, 3, 5, 0), (34, 3, 4, 3), (28, 3, 3, 3)]),                       # 1 good shot
    (3, [(12, 6, 3, 0), (10, 6, 2, 0)]),                                      # 2 miss
    (1, [(56, 6, 7, 0), (30, 3, 6, 0), REST, (52, 6, 6, 0), (24, 3, 5, 0), (18, 3, 3, 0)]),  # 3 knockdown clack
    (4, [(12, 2, 6, 0), (8, 2, 6, 0), (5, 2, 5, 0), (3, 2, 4, 0)]),           # 4 hurt
    (2, [(30, 0, 2, 0), (34, 0, 2, 0)]),                                      # 5 lane step
    (8, [(38, 1, 5, 0), (42, 1, 5, 0), (45, 1, 5, 0), (50, 1, 6, 0), (50, 1, 4, 5)]),  # 6 hill clear
    (10, [(26, 2, 5, 0), (25, 2, 5, 0), (24, 2, 5, 0), (20, 2, 5, 5)]),       # 7 fallen
]
while len(SOUNDS) < 8:
    SOUNDS.append((1, []))
SOUNDS += [
    (15, DRUMS),                                                              # 8 drums
    (15, eighths(BASS, 0, 5)),                                                # 9 bass
    (15, eighths(TUNE_A, 1, 3)),                                              # 10 tune a
    (15, eighths(TUNE_B, 1, 3)),                                              # 11 tune b
    (4, [(18, 6, 7, 0), (14, 6, 6, 0), (10, 6, 5, 0), (8, 6, 4, 0), (6, 6, 2, 0)]),  # 12 rocket
]
# "FF AABBCCDD": flags (1 loop start, 2 loop end), then the sfx on each
# channel, 0x40 and over silent
MUSIC = ["01 08090a40", "02 08090b40"]


def rows_of(text, width):
    rows = text.strip().split("\n")
    for row in rows:
        assert len(row) == width, "row %r is not %d wide" % (row, width)
    return rows


def mirrored(text, half_width):
    return [(row + row[::-1]).replace(".", "0") for row in rows_of(text, half_width)]


def bobbed(rows, dropped_row):
    """A second frame: everything above `dropped_row` sinks a pixel, the feet stay."""
    return ["0" * len(rows[0])] + rows[:dropped_row] + rows[dropped_row + 1:]


def stamp(sheet, rows, left, top):
    for y, row in enumerate(rows):
        sheet[top + y][left:left + len(row)] = row


def build_gfx():
    sheet = [["0"] * 128 for _ in range(128)]
    alien = mirrored(ALIEN, 8)
    stamp(sheet, alien, 0, 0)
    stamp(sheet, alien[:14] + mirrored(ALIEN_LEGS, 8), 16, 0)
    civilian = mirrored(CIVILIAN, 8)
    stamp(sheet, civilian, 32, 0)
    stamp(sheet, bobbed(civilian, 10), 48, 0)
    mech = mirrored(MECH.translate(RED), 12)
    stamp(sheet, mech, 0, 64)
    stamp(sheet, bobbed(mech, 14), 24, 64)
    return ["".join(row) for row in sheet]


def build_sfx():
    lines = []
    for speed, notes in SOUNDS:
        assert len(notes) <= 32
        body = "".join("%02x%x%x%x" % note for note in notes)
        lines.append("00%02x0000" % speed + body.ljust(160, "0"))
    return lines


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


def main():
    gfx = build_gfx()
    write_png(os.path.join(HERE, "sheet.png"), gfx[:96])
    tail = "\n".join(["__gfx__"] + gfx + ["__sfx__"] + build_sfx()
                     + ["__music__"] + MUSIC) + "\n"
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
