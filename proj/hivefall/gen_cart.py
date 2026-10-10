"""gen_cart.py - writes the sprites and sound effects into the carts.

usage: py gen_cart.py

Everything after __lua__ in hivefall.p8 and tests/test_*.p8 is replaced.
Sprites are drawn here as text: '.' is transparent, anything else is a
PICO-8 colour as a hex digit. Creatures and the mech are symmetrical, so
only their left half is drawn. sheet.png is written to look over.

The sheet is cut into 16x16 cells, numbered left to right, top to bottom;
enemy_specs in data.lua refers to cells. Each creature has two frames, in
neighbouring cells. The mech is 24x24, at (0,32) and (24,32).
"""
import glob
import os

from png import write_png

HERE = os.path.dirname(os.path.abspath(__file__))

SKITTER = """
........
7.......
87......
88....22
.88..222
.88.2222
..8822ee
..88ffaf
...8ffff
...2f8f7
..22ff88
.222.fff
.22..2f2
22...22.
2....2..
f....f..
"""

WING_UP = """
........
2.......
28......
288.....
2888..22
288882ee
28888faf
.2888fff
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
..222faf
.28888ff
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
......22
....2222
8..222e2
88.22e22
88222222
.882ffff
.88ffaaf
..8fffff
8.2ff787
882fff87
8822ffff
.8222fff
..2222ff
.2222.2f
.222..22
ff2...ff
"""

WYRM_HEAD = """
........
........
........
.....222
....22e2
...22e22
..222222
.822ffff
88.fafff
8..fffff
8..ff7f7
8...f878
.8..f888
.....f87
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
SOUNDS = [
    (2, [(40, 3, 4, 3), (32, 3, 3, 3), (24, 3, 2, 3)]),                      # 0 pulse
    (1, [(20, 6, 3, 0), (16, 6, 2, 0)]),                                     # 1 minigun
    (3, [(30, 6, 6, 0), (24, 6, 5, 0), (18, 6, 4, 0), (12, 6, 3, 0), (8, 6, 2, 0)]),   # 2 flak
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
]


def mirrored(text, half_width):
    rows = text.strip().split("\n")
    assert len(rows) == half_width * 2, "%d rows, wanted %d" % (len(rows), half_width * 2)
    for row in rows:
        assert len(row) == half_width, "row %r is not %d wide" % (row, half_width)
    return [(row + row[::-1]).replace(".", "0") for row in rows]


def bobbed(rows, dropped_row):
    """A second frame: everything above `dropped_row` sinks a pixel, the feet stay."""
    return ["0" * len(rows[0])] + rows[:dropped_row] + rows[dropped_row + 1:]


def stamp(sheet, rows, left, top):
    for y, row in enumerate(rows):
        sheet[top + y][left:left + len(row)] = row


def build_gfx():
    sheet = [["0"] * 128 for _ in range(128)]
    cells = []
    for art in (SKITTER, None, BRUTE, WYRM_HEAD, WYRM_BODY, SHIP):
        if art is None:
            cells += [mirrored(WING_UP, 8), mirrored(WING_DOWN, 8)]
        else:
            frame = mirrored(art, 8)
            cells += [frame, bobbed(frame, 10)]
    cells.append(mirrored(PORTRAIT, 8))
    for number, rows in enumerate(cells):
        stamp(sheet, rows, number % 8 * 16, number // 8 * 16)
    mech = mirrored(MECH, 12)
    stamp(sheet, mech, 0, 32)
    stamp(sheet, bobbed(mech, 14), 24, 32)
    return ["".join(row) for row in sheet]


def build_sfx():
    lines = []
    for speed, notes in SOUNDS:
        body = "".join("%02x%x%x%x" % note for note in notes)
        lines.append("00%02x0000" % speed + body.ljust(160, "0"))
    return lines


def main():
    gfx = build_gfx()
    write_png(os.path.join(HERE, "sheet.png"), gfx[:64])
    tail = "__gfx__\n" + "\n".join(gfx) + "\n__sfx__\n" + "\n".join(build_sfx()) + "\n"
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
