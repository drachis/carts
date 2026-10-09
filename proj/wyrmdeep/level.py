"""level.py - turns the stages' text into the map, and checks they can be finished.

stages.py lays each stage out as text. build() turns that into a 128x64 grid
of sprite ids (four stages of 16 rows) plus a list of everything that is
placed rather than drawn (units, spawn points, relics). check() floods each
stage from its start.
"""
from collections import deque

import stages
import tiles

WIDTH, HEIGHT, STAGE_ROWS = 128, 64, 16
START = (3, 11)  # where the dragon enters a stage, in tiles (data.lua agrees)

# one character -> a tile name in tiles.py
TERRAIN = {
    " ": None, "#": "rock", "d": "dirt", "=": "paving", "B": "brick", ",": "brick back",
    "w": "wood", "-": "bridge", "t": "thorns", "c": "crate",
    "X": "cracked brick", "v": "vine", "h": "hay",
    "T": "tree", "g": "grass", "i": "torch", "f": "banner",
}
# one character -> something placed by name (data.lua's unit and relic tables)
PLACED = {
    "s": "serf", "p": "pikeman", "a": "archer", "r": "crossbowman",
    "k": "knight", "m": "monk", "b": "bat", "l": "ballista",
    "S": "sheep", "P": "pig", "C": "cow",
    "K": "sir kay", "G": "sir gawain", "M": "merlin", "A": "king arthur",
    "H": "hovel", "Q": "barracks", "V": "roost",
    "+": "heart", "*": "brimstone",
}
LEGENDS = ["sir kay", "sir gawain", "merlin", "king arthur"]
# what a solid tile becomes with open air above it
TOPS = {"dirt": "turf", "brick": "brick top"}


def flags_of(sprite_id):
    return tiles.FLAGS.get(sprite_id, 0)


def build():
    """(grid of sprite ids, [(name, tx, ty)] of what is placed)."""
    text = stages.lines()
    assert len(text) == HEIGHT and all(len(line) == WIDTH for line in text)
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
    # an unseen lid over each stage, and walls at both ends
    for ty in range(HEIGHT):
        for tx in range(WIDTH):
            if names[ty][tx] is None and (ty % STAGE_ROWS == 0 or tx in (0, WIDTH - 1)):
                names[ty][tx] = "cap"

    def is_open(tx, ty):
        name = names[ty][tx]
        return name is None or not tiles.FLAGS[tiles.NAMES[name]] & tiles.SOLID

    grid = [[0] * WIDTH for _ in range(HEIGHT)]
    for ty in range(HEIGHT):
        for tx in range(WIDTH):
            name = names[ty][tx]
            if name is None:
                continue
            if name in TOPS and ty and is_open(tx, ty - 1):
                name = TOPS[name]
            elif name == "paving" and not is_open(tx, ty - 1):
                name = "paving deep"
            grid[ty][tx] = tiles.NAMES[name]
    return grid, placed


def reachable(grid, start, top, charge):
    """Every tile of the stage whose first row is `top` that the dragon can be in.

    It flies, so this is a flood through open tiles, anything that burns,
    and cracked tiles once it can charge.
    """
    def passable(tx, ty):
        if not (0 <= tx < WIDTH and top <= ty < top + STAGE_ROWS):
            return False
        bits = flags_of(grid[ty][tx])
        if not bits & tiles.SOLID or bits & (tiles.FLAMMABLE | tiles.BRITTLE):
            return True
        return bool(charge and bits & tiles.STONE)

    cells, queue = {start}, deque([start])
    while queue:
        tx, ty = queue.popleft()
        for step in ((tx + 1, ty), (tx - 1, ty), (tx, ty + 1), (tx, ty - 1)):
            if step not in cells and passable(*step):
                cells.add(step)
                queue.append(step)
    return cells


def check(grid, placed):
    """Raise unless everything in each stage can be reached; report each stage.

    The charge comes from the first legend, so the first stage must be
    finished without it.
    """
    report = []
    for stage, (name, _, _) in enumerate(stages.STAGES):
        top = stage * STAGE_ROWS
        cells = reachable(grid, (START[0], top + START[1]), top, charge=stage > 0)
        here = [(what, tx, ty) for what, tx, ty in placed if top <= ty < top + STAGE_ROWS]
        lost = [thing for thing in here if (thing[1], thing[2]) not in cells]
        assert not lost, "%s: nothing can reach %s" % (name, lost)
        legends = [what for what, _, _ in here if what in LEGENDS]
        assert legends == [LEGENDS[stage]], "%s should end with %s alone, not %s" % (
            name, LEGENDS[stage], legends)
        report.append("%s: %d placed, all reachable" % (name, len(here)))
    return report
