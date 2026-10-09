"""level.py - the world, drawn as text.

The world is 8 rooms wide and 4 tall; a room is 16 lines of 16 characters.
ROOMS is keyed by (column, row); a room that is not listed is solid rock.
build() turns the text into a 128x64 grid of sprite ids plus a list of
everything that is placed rather than drawn (the dragon, units, relics).
"""
import random

import tiles

ROOM, COLUMNS, ROWS = 16, 8, 4
WIDTH, HEIGHT = ROOM * COLUMNS, ROOM * ROWS

# one character -> a tile name in tiles.py
TERRAIN = {
    " ": None, "#": "rock", "d": "dirt", "B": "brick", ",": "brick back",
    "w": "wood", "-": "bridge", "t": "thorns", "c": "crate",
    "x": "cracked rock", "X": "cracked brick", "v": "vine", "h": "hay",
    "T": "tree", "g": "grass", "1": "ward kay", "2": "ward gawain",
    "3": "ward merlin", "^": "spikes", "~": "lava", "N": "nest",
    "i": "torch", "o": "window", "u": "mushroom", "n": "bones", "f": "banner",
}
# one character -> something placed by name (data.lua's unit and relic tables)
PLACED = {
    "D": "dragon",
    "s": "serf", "p": "pikeman", "a": "archer", "r": "crossbowman",
    "k": "knight", "m": "monk", "b": "bat", "l": "ballista",
    "S": "sheep", "P": "pig", "C": "cow",
    "K": "sir kay", "G": "sir gawain", "M": "merlin", "L": "sir lancelot",
    "A": "king arthur",
    "+": "heart", "*": "brimstone",
}
# what a solid tile becomes with open air above it
TOPS = {"rock": "rock top", "dirt": "turf", "brick": "brick top", "lava": "lava top"}

ROOMS = {
    (1, 3): [  # the lair
        "################",
        "################",
        "####        ####",
        "###          ###",
        "##            ##",
        "##            ##",
        "#            w  ",
        "#            w  ",
        "#  ND     u  w  ",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
    ],
    (2, 3): [
        "################",
        "################",
        "########      ##",
        "######          ",
        "#####           ",
        "####        ####",
        "          ######",
        "        ########",
        "     s  ########",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
    ],
    (3, 3): [
        "################",
        "################",
        "##            ##",
        "              ##",
        "    v  S      ##",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
    ],
}


def text_grid():
    """The whole world as HEIGHT strings of WIDTH characters."""
    lines = []
    for row in range(ROWS):
        for line in range(ROOM):
            parts = []
            for column in range(COLUMNS):
                room = ROOMS.get((column, row))
                if room:
                    assert len(room) == ROOM, (column, row)
                    assert len(room[line]) == ROOM, (column, row, line)
                parts.append(room[line] if room else "#" * ROOM)
            lines.append("".join(parts))
    return lines


def build():
    """(grid of sprite ids, [(name, tx, ty)] of what is placed)."""
    text = text_grid()
    rng = random.Random(7)
    names = [[None] * WIDTH for _ in range(HEIGHT)]
    placed = []
    for ty, line in enumerate(text):
        for tx, char in enumerate(line):
            if char in PLACED:
                placed.append((PLACED[char], tx, ty))
                # scenery carries on behind whatever stands in front of it
                if tx and names[ty][tx - 1] == "brick back":
                    names[ty][tx] = "brick back"
            else:
                assert char in TERRAIN, "unknown character %r at %d,%d" % (char, tx, ty)
                names[ty][tx] = TERRAIN[char]

    def is_open(tx, ty):
        if not (0 <= tx < WIDTH and 0 <= ty < HEIGHT):
            return False
        name = names[ty][tx]
        return name is None or not tiles.FLAGS[tiles.NAMES[name]] & tiles.SOLID

    grid = [[0] * WIDTH for _ in range(HEIGHT)]
    for ty in range(HEIGHT):
        for tx in range(WIDTH):
            name = names[ty][tx]
            if name is None:
                continue
            if name in TOPS and is_open(tx, ty - 1):
                name = TOPS[name]
            elif name == "rock" and rng.random() < 0.3:
                name = "rock alt"
            grid[ty][tx] = tiles.NAMES[name]
    for tx in range(WIDTH):
        assert not is_open(tx, 0) and not is_open(tx, HEIGHT - 1), "open border at column %d" % tx
    for ty in range(HEIGHT):
        assert not is_open(0, ty) and not is_open(WIDTH - 1, ty), "open border at row %d" % ty
    assert [name for name, _, _ in placed].count("dragon") == 1, "the dragon starts in one place"
    return grid, placed
