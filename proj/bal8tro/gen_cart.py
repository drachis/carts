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

# joker portraits, 8x8, sprite 32+n for the n-th row of joker_specs (data.lua
# gives each spec its sprite in that order). Bal8tro's own art: jesters told
# apart by hat, face and mouth, and a few objects. "." is transparent, so the
# joker card's white shows through.
# a jester: A and B the hat's two colours, F the face, E the eyes, M the mouth
JESTER = """
A......B
AAA..BBB
.AAABBB.
..FFFF..
.FEFFEF.
.FFFFFF.
.FMMMMF.
..FFFF..
"""


def jester(hat_a, hat_b, face="f", eyes="0", mouth="8", eye_row=None, mouth_row=None):
    rows = JESTER.strip().split("\n")
    if eye_row:
        rows[4] = eye_row
    if mouth_row:
        rows[6] = mouth_row
    text = "\n".join(rows)
    for key, colour in (("A", hat_a), ("B", hat_b), ("F", face), ("E", eyes), ("M", mouth)):
        text = text.replace(key, colour)
    return text


JOKER_ART = [
    jester("8", "c"),                                        # joker
    jester("9", "9"),                                        # greedy, diamonds
    jester("8", "8"),                                        # lusty, hearts
    jester("1", "1"),                                        # wrath, spades
    jester("3", "3"),                                        # glutton, clubs
    jester("a", "9", mouth_row=".F8888F."),  # jolly
    jester("e", "2", eyes="c", eye_row=".Fc0Fc0."),         # zany, wild eyes
    jester("8", "2", face="e", eye_row=".F00F00."),          # mad
    jester("d", "c", mouth_row=".FF88FF."),                  # droll
    jester("5", "1", eye_row=".FF0FF0."),                    # sly, eyes aside
    jester("c", "1", eye_row=".0c00c0."),                    # clever, glasses
    """
..0000..
.000000.
.0b00b0.
.000000.
..0770..
..7.7...
..0000..
........
""",                                                         # scary, a skull
    """
8..c8..c
88cc88cc
.ff..ff.
f0f0f0f0
ffffffff
f88ff88f
.ff..ff.
........
""",                                                         # the duo
    """
8c.9a.2e
.ff.ff.f
f0ff0ff0
ffffffff
f8ff8ff8
.ff.ff.f
........
........
""",                                                         # tribe
    """
..88....
.8888...
..88.ccc
....cccc
.aa..ccc
aaaa....
.aa..33.
.....33.
""",                                                         # abstract: shapes
    """
5888888.
5888888.
5888888.
5.......
5.......
5.......
5.......
55......
""",                                                         # banner: a flag
    """
........
...77...
..7767..
..6666..
.666666.
.655556.
65555556
55555555
""",                                                         # mystic summit
    """
8......c
888...cc
.88..cc.
.ff.....
f0f.....
fff.....
f88.....
.ff.....
""",                                                         # half a jester
    """
...a....
.a.a.a..
..aaa...
aaa7aaa.
..aaa...
.a.a.a..
...a....
........
""",                                                         # supernova
    jester("b", "3", face="b", eyes="0", mouth="3"),         # green joker
    """
........
aaaaaaa.
a7a7a7a.
aaaaaaaa
aaaaaaaa
a0aaa0a.
.5...5..
........
""",                                                         # ride the bus
]
for number, art in enumerate(JOKER_ART):
    SPRITES[32 + number] = art
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
# the music: a slow lounge loop in a minor, in Balatro's spirit but its own
# tune. a walking bass, a held pad, and a lazy organ lead with vibrato.
# Am7 Dm7 Em7 Am7, then F Dm E7 E. each list is four bars of eight steps;
# 0 is a rest; pitches count semitones from c0, so 57 is the a above
# middle c.
TUNE_SPEED = 16
BASS_A = [33, 0, 40, 0, 45, 0, 40, 0,  38, 0, 45, 0, 50, 0, 45, 0,
          40, 0, 47, 0, 52, 0, 47, 0,  33, 0, 40, 0, 43, 0, 44, 0]
BASS_B = [29, 0, 36, 0, 41, 0, 36, 0,  38, 0, 45, 0, 41, 0, 45, 0,
          40, 0, 47, 0, 44, 0, 50, 0,  40, 0, 0, 0, 40, 0, 44, 0]
PAD_A = [48] * 8 + [53] * 8 + [55] * 8 + [52] * 8
PAD_B = [45] * 8 + [53] * 8 + [56] * 16
LEAD_A = [57, 57, 57, 60, 60, 60, 59, 59,  57, 57, 53, 53, 53, 53, 0, 0,
          55, 55, 55, 59, 59, 59, 57, 57,  55, 55, 52, 52, 52, 52, 0, 0]
LEAD_B = [53, 53, 53, 57, 57, 57, 60, 60,  62, 62, 60, 60, 57, 57, 57, 0,
          56, 56, 56, 59, 59, 59, 62, 62,  64, 64, 64, 64, 59, 59, 56, 56]


def voice(pitches, waveform, volume, effect):
    return [(pitch, waveform, volume, effect) if pitch else (0, 0, 0, 0) for pitch in pitches]


TUNE_FIRST = len(SOUNDS)
SOUNDS += [
    (TUNE_SPEED, voice(BASS_A, 1, 4, 5)),   # tilted saw, plucked
    (TUNE_SPEED, voice(BASS_B, 1, 4, 5)),
    (TUNE_SPEED, voice(PAD_A, 0, 2, 0)),    # triangle, held
    (TUNE_SPEED, voice(PAD_B, 0, 2, 0)),
    (TUNE_SPEED, voice(LEAD_A, 5, 3, 2)),   # organ with vibrato
    (TUNE_SPEED, voice(LEAD_B, 5, 3, 2)),
]
BASS_A_SFX, BASS_B_SFX, PAD_A_SFX, PAD_B_SFX, LEAD_A_SFX, LEAD_B_SFX = range(TUNE_FIRST, TUNE_FIRST + 6)

# after the tune, so the sound numbers above stay put
SOUNDS += [
    (1, [(46, 0, 2, 5)]),                                 # 27 cursor moves
]


def pattern(flags, *channels):
    sounds = list(channels) + [0x40] * (4 - len(channels))
    return "%02x " % flags + "".join("%02x" % sound for sound in sounds)


# a pattern is "FF AABBCCDD": flags (1 loop start, 2 loop end), then the
# sfx on each of four channels, 0x40 and over meaning silent. three
# channels only, so sound effects always have the fourth.
# 0-1 the shop and title: bass and pad. 2-3 the table: with the lead.
MUSIC = [
    pattern(1, BASS_A_SFX, PAD_A_SFX),
    pattern(2, BASS_B_SFX, PAD_B_SFX),
    pattern(1, BASS_A_SFX, PAD_A_SFX, LEAD_A_SFX),
    pattern(2, BASS_B_SFX, PAD_B_SFX, LEAD_B_SFX),
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
    # per-cart lite copies of the drawing modules for the replay test carts
    import sys
    sys.path.insert(0, os.path.join(HERE, "tests"))
    import make_lite
    make_lite.main()
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
