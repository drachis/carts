"""level.py - the world, drawn as text, and a check that it can be finished.

The world is 8 rooms wide and 4 tall; a room is 16 lines of 16 characters.
ROOMS is keyed by (column, row); a room that is not listed is solid rock.
build() turns the text into a 128x64 grid of sprite ids plus a list of
everything that is placed rather than drawn (the dragon, units, relics).
check() walks the grid with each age's abilities in turn.

Rows, top to bottom: 0 the heights, 1 the surface, 2 the under, 3 the deep.
"""
import random
from collections import deque

import tiles
from rooms import INTERIOR, ROOMS

ROOM, COLUMNS, ROWS = 16, 8, 4
WIDTH, HEIGHT = ROOM * COLUMNS, ROOM * ROWS

# one character -> a tile name in tiles.py
TERRAIN = {
    " ": None, ".": None, "#": "rock", "d": "dirt", "B": "brick", ",": "brick back",
    "w": "wood", "-": "bridge", "t": "thorns", "c": "crate",
    "x": "cracked rock", "X": "cracked brick", "v": "vine", "h": "hay",
    "T": "tree", "g": "grass", "1": "ward kay", "2": "ward gawain",
    "3": "ward merlin", "^": "spikes", "~": "lava", "N": "nest",
    "i": "torch", "o": "window", "u": "mushroom", "n": "bones", "f": "banner",
    "|": "gate",
}
# one character -> something placed by name (data.lua's unit and relic tables)
PLACED = {
    "D": "dragon",
    "s": "serf", "p": "pikeman", "a": "archer", "r": "crossbowman",
    "k": "knight", "m": "monk", "b": "bat", "l": "ballista",
    "S": "sheep", "P": "pig", "C": "cow",
    "K": "sir kay", "G": "sir gawain", "M": "merlin",
    "O": "mine mouth", "H": "hovel", "Q": "barracks", "V": "roost",
    "A": "king arthur",
    "+": "heart", "*": "brimstone",
}
# what a solid tile becomes with open air above it
TOPS = {"rock": "rock top", "dirt": "turf", "brick": "brick top", "lava": "lava top"}
def text_grid():
    """The whole world as HEIGHT strings of WIDTH characters."""
    lines = []
    for row in range(ROWS):
        for line in range(ROOM):
            parts = []
            for column in range(COLUMNS):
                room = ROOMS.get((column, row))
                if room is None:
                    parts.append("#" * ROOM)
                    continue
                assert len(room) == ROOM, "room %s has %d lines" % ((column, row), len(room))
                assert len(room[line]) == ROOM, "room %s line %d is %d wide" % (
                    (column, row), line, len(room[line]))
                text = room[line]
                if (column, row) in INTERIOR:
                    text = text.replace(" ", ",")
                parts.append(text)
            lines.append("".join(parts))
    return lines


def flags_of(sprite_id):
    return tiles.FLAGS.get(sprite_id, 0)


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
    for tx in range(WIDTH):
        if names[0][tx] is None:
            names[0][tx] = "cap"

    def is_open(tx, ty):
        if not (0 <= tx < WIDTH and 0 <= ty < HEIGHT):
            return False
        name = names[ty][tx]
        return name is None or not tiles.FLAGS[tiles.NAMES[name]] & tiles.SOLID

    def buried(tx, ty):
        return not any(is_open(tx + dx, ty + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))

    grid = [[0] * WIDTH for _ in range(HEIGHT)]
    for ty in range(HEIGHT):
        for tx in range(WIDTH):
            name = names[ty][tx]
            if name is None:
                continue
            if name in TOPS and is_open(tx, ty - 1):
                name = TOPS[name]
            elif name == "rock" and buried(tx, ty):
                name = "rock deep"
            elif name == "rock" and rng.random() < 0.3:
                name = "rock alt"
            grid[ty][tx] = tiles.NAMES[name]
    for tx in range(WIDTH):
        assert not is_open(tx, 0) and not is_open(tx, HEIGHT - 1), "open border at column %d" % tx
    for ty in range(HEIGHT):
        assert not is_open(0, ty) and not is_open(WIDTH - 1, ty), "open border at row %d" % ty
    assert [name for name, _, _ in placed].count("dragon") == 1, "the dragon starts in one place"
    return grid, placed


# --- can it be finished? ---
#
# The dragon flies, so this is a flood through whatever it can pass at each
# age: open tiles, anything that burns, cracked tiles once it can charge, and
# the seals of the legends already fallen.
STAGES = [
    ("sir kay", {"charge": True, "ward": "ward kay"}),
    ("sir gawain", {"ward": "ward gawain"}),
    ("merlin", {"ward": "ward merlin"}),
    ("king arthur", {}),
]
AGE_NAMES = ["whelp", "drake", "wyrm", "great wyrm"]


def reachable(grid, start, charge=False, wards=()):
    """Every tile the dragon can be in, starting from `start`."""
    fallen = {tiles.NAMES[name] for name in wards}

    def passable(tx, ty):
        if not (0 <= tx < WIDTH and 0 <= ty < HEIGHT):
            return False
        sprite_id = grid[ty][tx]
        bits = flags_of(sprite_id)
        if bits & tiles.HAZARD:
            return False
        if not bits & tiles.SOLID or bits & tiles.FLAMMABLE or sprite_id in fallen:
            return True
        return bool(charge and bits & tiles.BRITTLE)

    cells, queue = {start}, deque([start])
    while queue:
        tx, ty = queue.popleft()
        for step in ((tx + 1, ty), (tx - 1, ty), (tx, ty + 1), (tx, ty - 1)):
            if step not in cells and passable(*step):
                cells.add(step)
                queue.append(step)
    return cells


def check(grid, placed):
    """Raise unless the legends can be reached in order; report what each age reaches."""
    start = next((tx, ty) for name, tx, ty in placed if name == "dragon")
    relics = [(name, tx, ty) for name, tx, ty in placed if name in ("heart", "brimstone")]
    legends = [name for name, _ in STAGES]
    where = {name: (tx, ty) for name, tx, ty in placed}
    abilities = {"wards": []}
    report = []
    for stage, (legend, gained) in enumerate(STAGES):
        cells = reachable(grid, start, **abilities)
        assert where[legend] in cells, "a %s cannot reach %s" % (AGE_NAMES[stage], legend)
        for later in legends[stage + 1:]:
            assert where[later] not in cells, "a %s can already reach %s" % (AGE_NAMES[stage], later)
        found = sum((tx, ty) in cells for _, tx, ty in relics)
        report.append("%s: %d tiles, %d/%d relics" % (AGE_NAMES[stage], len(cells), found, len(relics)))
        if stage == len(STAGES) - 1:
            lost = [(name, tx, ty) for name, tx, ty in placed if (tx, ty) not in cells]
            assert not lost, "nothing can reach %s" % lost
        gained = dict(gained)
        if "ward" in gained:
            abilities["wards"] = abilities["wards"] + [gained.pop("ward")]
        abilities.update(gained)
    return report
