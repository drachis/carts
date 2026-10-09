"""gen_cart.py - writes the art, map and sound into the carts, and level.lua.

usage: py gen_cart.py [cart ...]

The world is 128x64 tiles, which is all of PICO-8's map memory. Its lower
half (rows 32..63) is the same memory as sprites 128..255, so the cart keeps
its sprites to ids 0..127 and this script writes those map rows into the
bottom half of __gfx__.

Also written, to look over: sheet.png (the sprites) and world.png (the map
with everything that is placed on it).
"""
import os
import re
import sys

import art
import bosses
import level
import stages
import tiles
from png import write_png

HERE = os.path.dirname(os.path.abspath(__file__))
CARTS = sys.argv[1:] or ["wyrmdeep.p8", "tests/test_data.p8", "tests/test_run.p8"]
SKY_ROWS = 32  # the surface and the heights: open air there is sky
SKY, DARK = "1", "0"


def sprites():
    merged = dict(art.SPRITES)
    merged.update(bosses.sprites())
    for sprite_id, rows in tiles.SPRITES.items():
        assert sprite_id not in merged, "sprite %d is defined twice" % sprite_id
        merged[sprite_id] = rows
    for sprite_id, rows in merged.items():
        assert sprite_id < 128, "sprite %d is in the map's half of the sheet" % sprite_id
        assert len(rows) == 8 and all(len(row) == 8 for row in rows), sprite_id
    return merged


def build_gfx(grid):
    sheet = [["0"] * 128 for _ in range(128)]
    for sprite_id, rows in sprites().items():
        top, left = (sprite_id // 16) * 8, (sprite_id % 16) * 8
        for y, row in enumerate(rows):
            sheet[top + y][left:left + 8] = row
    # a map byte is two pixels, low nibble first; a map row is two pixel rows
    for ty in range(32, 64):
        for tx in range(128):
            value = grid[ty][tx]
            y = 64 + (ty - 32) * 2 + tx // 64
            x = (tx % 64) * 2
            sheet[y][x], sheet[y][x + 1] = "%x" % (value & 15), "%x" % (value >> 4)
    return ["".join(row) for row in sheet]


def build_map(grid):
    return ["".join("%02x" % value for value in grid[ty]) for ty in range(32)]


def build_gff():
    flags = [0] * 256
    for sprite_id, bits in tiles.FLAGS.items():
        flags[sprite_id] = bits
    text = "".join("%02x" % flag for flag in flags)
    return text[:256] + "\n" + text[256:]


def write_level_lua(placed):
    """level.lua: everything that is placed, the stages' names, and tile ids."""
    rows = ["%s,%d,%d" % (name, tx * 8 + 4, ty * 8 + 4) for name, tx, ty in placed]
    constants = ["start_x=%d" % (level.START[0] * 8 + 4), "start_y=%d" % (level.START[1] * 8 + 4),
                 "stage_names=%s" % ",".join(name for name, _, _ in stages.STAGES),
                 "tile_fire=%d" % tiles.NAMES["fire"]]
    lua = "parse_record([[\n%s\n]],nil,_ENV)\n\nspawn_text=[[\n%s]]\n" % (
        "\n".join(constants), "\n".join(rows))
    with open(os.path.join(HERE, "level.lua"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(lua)


def named_sprites():
    """name -> sprite id, read from the rows of data.lua's tables."""
    found = {}
    for line in open(os.path.join(HERE, "data.lua"), encoding="utf-8"):
        row = re.match(r"([a-z' ]+),(\d+),", line)
        if row:
            found[row.group(1)] = int(row.group(2))
    return found


def write_world_png(grid, placed):
    art_of = sprites()
    canvas = [[SKY] * (level.WIDTH * 8) for _ in range(level.HEIGHT * 8)]

    def stamp(sprite_id, left, top, behind=None):
        for y, row in enumerate(art_of.get(sprite_id, [])):
            for x, pixel in enumerate(row):
                if pixel != "0" or behind is None:
                    canvas[top + y][left + x] = pixel
                else:
                    canvas[top + y][left + x] = behind

    for ty in range(level.HEIGHT):
        for tx in range(level.WIDTH):
            back = SKY
            stamp(grid[ty][tx], tx * 8, ty * 8, back)
    marks = named_sprites()
    for name, tx, ty in placed:
        sprite_id = marks.get(name)
        if sprite_id is not None:
            for y, row in enumerate(art_of[sprite_id]):
                for x, pixel in enumerate(row):
                    if pixel != "0":
                        canvas[ty * 8 + y][tx * 8 + x] = pixel
    write_png(os.path.join(HERE, "world.png"), ["".join(row) for row in canvas], scale=2)


def main():
    grid, placed = level.build()
    write_world_png(grid, placed)
    for line in level.check(grid, placed):
        print(line)
    gfx = build_gfx(grid)
    data = "\n__gfx__\n%s\n__gff__\n%s\n__map__\n%s\n__sfx__\n%s\n__music__\n%s\n" % (
        "\n".join(gfx), build_gff(), "\n".join(build_map(grid)),
        art.build_sfx(), "\n".join(art.MUSIC))
    for cart in CARTS:
        path = os.path.join(HERE, cart)
        source = open(path, encoding="utf-8").read()
        source = re.split(r"\n__gfx__\n.*", source, flags=re.S)[0].rstrip("\n")
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(source + data)
        print("patched", cart)
    write_level_lua(placed)
    write_png(os.path.join(HERE, "sheet.png"), gfx[:64])
    print("wrote level.lua, sheet.png, world.png (%d placed)" % len(placed))


if __name__ == "__main__":
    main()
