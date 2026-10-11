"""gen_cart.py - writes the sprites, sound effects and music into the carts.

usage: py gen_cart.py

Everything after __lua__ in hivefall.p8 and tests/test_*.p8 is replaced.
Sprites are drawn here as text: '.' is transparent, anything else is a
PICO-8 colour as a hex digit. Creatures and the mech are symmetrical, so
only their left half is drawn. sheet.png is written to look over.

The sheet is cut into 16x16 cells, numbered left to right, top to bottom;
enemy_specs in data.lua refers to cells. Each creature has two frames, in
neighbouring cells:

     0 skitter    2 wing        4 brute        6 wyrm head
     8 wyrm body 10 ship       12 portrait    14 spit
    16 claw      18 tyrant body 20 tyrant head

The six weapon icons are 8x8, in a row at (0,48), in weapon_specs order.

The mech is 24x24, at (0,64) and (24,64).
"""
import glob
import os

from png import write_png

HERE = os.path.dirname(os.path.abspath(__file__))

SKITTER = """
7.......
87......
.87.....
.88...22
..88.22e
..8822e2
...82222
...82a22
...f2222
..ff.271
..f..217
.ff..f71
.f...ff.
ff...f..
f....f..
........
"""

WING_UP = """
........
2.......
28......
288.....
2888..22
288882ee
288882a2
.2888272
..28822f
...222ff
......2f
......2f
.......2
.......2
........
........
"""

WING_DOWN = """
........
........
........
........
......22
.....2ee
..2222a2
.2888872
2888822f
28882.ff
2888..2f
288...2f
28.....2
2......2
........
........
"""

BRUTE = """
....2222
..222ee2
.222e222
.22e2222
22e22222
2222e222
f2222111
ff22a111
ff221717
.f227171
.ff22222
..ff2222
..fff22.
.fff.ff.
.ff..ff.
fff.fff.
"""

WYRM_HEAD = """
........
........
........
.....222
....22e2
...22e22
..222222
.8222222
88.2a222
8..22222
8..27171
8...1818
.8..7171
.....222
.....fff
....ffff
"""

WYRM_BODY = """
........
........
........
........
........
.....222
...222e2
8.222e22
8822e222
.8222222
..22ffff
..2fffff
8.2fffff
88.fffff
.8..ffff
......ff
"""

SHIP = """
......dd
....dd22
..dd2222
.d222e22
d222e222
d2222222
d22b22b2
d2222222
.d222888
..dd8878
..e.d888
.e..e.dd
.e..e..e
e...e..e
e....e.e
.....e..
"""

PORTRAIT = """
...55555
..566666
.5666666
.566dddd
566dcccc
56dccc7c
56dccccc
56ddcccc
566ddddd
.56fffff
.56ff4ff
.56fffee
..56ffff
..5566ff
.5566666
55666996
"""

SPIT = """
........
........
........
........
........
......bb
....bbbb
...bbb7b
...bbbbb
...3bbbb
...3bbbb
....33bb
......33
........
........
........
"""

# drawn whole: the left-hand claw; the right-hand one is drawn flipped
CLAW = """
.7..............
.87.............
.887............
..887...........
..8887..........
...8887.........
...88887........
....88887.......
....888887......
.....88888f.....
......8888ff....
.......888fff...
........88ffff..
.........fff2ff.
..........ff22f.
...........ffff.
"""

TYRANT_BODY = """
....2222
..22eee2
.22e2222
22e22222
2e222221
2e2221d1
22221d11
.2221d1d
.22221d1
..2221d1
..222211
.2222222
.222..22
222...2.
22...22.
fff.fff.
"""

TYRANT_HEAD = """
........
...2...2
..22..22
..2e2222
.22e22e2
.2222222
.22a1222
.2221122
..227171
..281818
..227171
...22222
....2ff2
........
........
........
"""

# 8x8 each, drawn whole, in the order of weapon_specs
ICONS = ["""
........
.cccccc7
.cccccc.
.cc1....
.cc.....
.cc.....
........
........
""", """
......a.
999999.a
944449a.
999999.a
.99...a.
.99.....
........
........
""", """
........
.5aaaaaa
55aaaaaa
.5aaaaaa
..55....
..55....
........
........
""", """
........
......77
eeeeee7e
e22eee77
ee......
e.......
........
........
""", """
........
6.......
6688887.
66888877
6688887.
6.......
........
........
""", """
...bb...
..bbbb..
..b77b..
..bbbb..
..bbbb..
.5bbbb5.
55.99.55
...99...
"""]

MECH = """
..5.........
..5.........
.565........
.565.....555
.565...5566d
.565..566ddd
5d6555666d99
5d65d6666d99
5d65d66666dd
5dd5d666ddd1
5dd5d66dd1a1
.55.5d6dd111
.....5dddddd
....55ddd555
...5665.5dd5
..56665..555
..5665......
.56665......
.5665.......
.5d65.......
.5dd5.......
..5d65......
.55dd55.....
.5555555....
"""

# (speed, [(pitch 0..63, waveform 0..7, volume 0..7, effect 0..7), ...])
# waveforms: 0 triangle 1 tilted saw 2 saw 3 square 4 pulse 5 organ 6 noise 7 phaser
# effects: 2 vibrato 3 drop
REST = (0, 0, 0, 0)
KICK, HAT, SNARE = (10, 0, 5, 3), (50, 6, 1, 0), (32, 6, 3, 0)
BASS_LINE = [14, 14, None, 14, 17, None, 14, None, 14, 14, None, 14, 19, None, 17, None,
             14, 14, None, 14, 17, None, 14, None, 12, 12, None, 12, 10, None, 12, 13]
DRUM_BAR = [KICK, REST, HAT, REST, SNARE, REST, HAT, REST,
            KICK, KICK, HAT, REST, SNARE, REST, HAT, HAT]

SOUNDS = [
    (2, [(40, 3, 4, 3), (32, 3, 3, 3), (24, 3, 2, 3)]),                      # 0 pulse
    (3, [(30, 6, 6, 0), (24, 6, 5, 0), (18, 6, 4, 0), (12, 6, 3, 0), (8, 6, 2, 0)]),   # 1 flak
    (1, [(20, 6, 3, 0), (16, 6, 2, 0)]),                                     # 2 minigun
    (3, [(50, 7, 5, 0), (56, 7, 5, 0), (60, 7, 4, 0), (48, 7, 3, 0), (40, 7, 2, 0)]),  # 3 shock
    (5, [(10, 6, 4, 0), (14, 6, 4, 0), (18, 6, 3, 0), (22, 6, 3, 0), (26, 6, 2, 0)]),  # 4 rocket
    (8, [(12, 2, 5, 0), (10, 2, 5, 0), (8, 2, 5, 0), (6, 2, 4, 0), (5, 2, 3, 0)]),     # 5 redeemer
    (2, [(36, 6, 5, 0), (28, 6, 4, 0), (20, 6, 3, 0), (12, 6, 2, 0)]),       # 6 pop
    (5, [(20, 6, 7, 0), (14, 6, 7, 0), (10, 6, 6, 0), (8, 6, 6, 0),
         (6, 6, 5, 0), (5, 6, 4, 0), (4, 6, 3, 0), (3, 6, 2, 0)]),           # 7 boom
    (4, [(12, 2, 6, 0), (8, 2, 6, 0), (5, 2, 5, 0), (3, 2, 4, 0)]),          # 8 hurt
    (3, [(36, 3, 3, 0), (48, 3, 3, 0)]),                                     # 9 weapon switch
    (10, [(24, 5, 4, 0), (24, 5, 4, 0), (31, 5, 4, 0), (36, 5, 5, 0), (36, 5, 3, 0)]),  # 10 wave
    (6, [(40, 4, 5, 0), (34, 4, 5, 0), (28, 4, 5, 0), (22, 4, 4, 0), (16, 4, 3, 0)]),   # 11 overheat
    (4, [(pitch, 2, 5, 0) for pitch in range(12, 52, 4)] + [(52, 7, 6, 0), (52, 7, 4, 0)]),  # 12 alpha
    (6, [(36, 0, 5, 0), (40, 0, 5, 0), (43, 0, 5, 0), (48, 0, 5, 0), (48, 0, 3, 0)]),   # 13 upgrade
    (3, [(8, 0, 4, 3), (4, 0, 3, 0)]),                                       # 14 step
    (8, [(10, 1, 6, 2), (8, 1, 6, 2), (6, 1, 6, 2), (5, 1, 5, 2),
         (4, 1, 5, 2), (3, 1, 4, 2), (3, 1, 3, 2)]),                         # 15 roar
    (16, [REST if pitch is None else (pitch, 2, 3, 0) for pitch in BASS_LINE]),  # 16 bass
    (16, DRUM_BAR * 2),                                                      # 17 drums
    (2, [(60, 6, 2, 0), (56, 6, 2, 0), (52, 6, 1, 0)]),                      # 18 vent
]
# pattern 0 loops on itself: bass and drums on the first two channels
MUSIC = ["03 10114344"]


def rows_of(text, width):
    rows = text.strip().split("\n")
    for row in rows:
        assert len(row) == width, "row %r is not %d wide" % (row, width)
    return rows


def mirrored(text, half_width):
    rows = rows_of(text, half_width)
    assert len(rows) == half_width * 2, "%d rows, wanted %d" % (len(rows), half_width * 2)
    return [(row + row[::-1]).replace(".", "0") for row in rows]


def whole(text, width):
    return [row.replace(".", "0") for row in rows_of(text, width)]


def bobbed(rows, dropped_row):
    """A second frame: everything above `dropped_row` sinks a pixel, the feet stay."""
    return ["0" * len(rows[0])] + rows[:dropped_row] + rows[dropped_row + 1:]


def stamp(sheet, rows, left, top):
    for y, row in enumerate(rows):
        sheet[top + y][left:left + len(row)] = row


def build_gfx():
    sheet = [["0"] * 128 for _ in range(128)]
    skitter, brute = mirrored(SKITTER, 8), mirrored(BRUTE, 8)
    head, body, ship = mirrored(WYRM_HEAD, 8), mirrored(WYRM_BODY, 8), mirrored(SHIP, 8)
    portrait, spit, claw = mirrored(PORTRAIT, 8), mirrored(SPIT, 8), whole(CLAW, 16)
    tyrant, crown = mirrored(TYRANT_BODY, 8), mirrored(TYRANT_HEAD, 8)
    cells = [
        skitter, bobbed(skitter, 10), mirrored(WING_UP, 8), mirrored(WING_DOWN, 8),
        brute, bobbed(brute, 10), head, bobbed(head, 12),
        body, bobbed(body, 12), ship, bobbed(ship, 9),
        portrait, portrait, spit, bobbed(spit, 9),
        claw, bobbed(claw, 8), tyrant, bobbed(tyrant, 11),
        crown, bobbed(crown, 7),
    ]
    for number, rows in enumerate(cells):
        stamp(sheet, rows, number % 8 * 16, number // 8 * 16)
    for number, icon in enumerate(ICONS):
        stamp(sheet, whole(icon, 8), number * 8, 48)
    mech = mirrored(MECH, 12)
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


def main():
    gfx = build_gfx()
    write_png(os.path.join(HERE, "sheet.png"), gfx[:96])
    tail = "\n".join(["__gfx__"] + gfx + ["__sfx__"] + build_sfx() + ["__music__"] + MUSIC) + "\n"
    carts = ["hivefall.p8"] + sorted(glob.glob(os.path.join(HERE, "tests", "test_*.p8")))
    for cart in carts:
        path = os.path.join(HERE, cart)
        with open(path, encoding="utf-8") as handle:
            lua = handle.read().split("__gfx__")[0]
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(lua.rstrip("\n") + "\n" + tail)
    print("wrote art and sound into %d carts" % len(carts))


if __name__ == "__main__":
    main()
