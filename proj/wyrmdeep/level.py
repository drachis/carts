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
# rooms indoors: a space there is the back wall, and "." is open air
INTERIOR = {(6, 0), (7, 0), (6, 1), (7, 1), (6, 2)}

ROCK = ["################"]
SKY = ["                "]
WALL = ["      BBBBBB    "]

ROOMS = {
    # ---------------------------------------------------------- the heights
    (0, 0): SKY + [  # the eyrie: the top of the cliff over the forest
        "####            ",
        "###             ",
        "###             ",
        "###             ",
        "###             ",
        "###             ",
        "###             ",
        "###             ",
        "###             ",
        "###             ",
        "### N+          ",
        "#######         ",
        "###             ",
        "###             ",
        "###             ",
    ],
    (1, 0): SKY * 6 + [  # a rock adrift in the sky
        "       *        ",
        "     #####      ",
        "      ###       ",
    ] + SKY * 7,
    (2, 0): SKY * 2 + [  # merlin's chamber, at the top of his tower
        "  BBBBBBBBBBBB  ",
        "  B,,,,,,,,,,B  ",
        "  B,,f,,,,f,,B  ",
        "  B,,,,,M,,,,B  ",
        "  B,,,,,,,,,,B  ",
        "  B,,,,,,,,,,B  ",
        "  B,,,,,,,,,,B  ",
        "  B,,,,,,,,,,B  ",
        "  B,,,,,,,,,,B  ",
        "  B,,,,,,,,,,B  ",
        "  BBBBBBB,,BBB  ",
        "    B,,,,,,B    ",
        "    B,,,,,,B    ",
        "    B,,,,,,B    ",
    ],
    (3, 0): SKY * 16,
    (4, 0): WALL * 16,  # camelot's curtain wall
    (5, 0): [  # the wall walk over the courtyard
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "   r    l     BB",
        "BBBBB  BBBB   BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
    ],
    (6, 0): [  # the upper hall
        "BBBBBBBBBBBBBBBB",
        "BB            BB",
        "BB  f      f  BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB   m    m   BB",
        "BB  BBB  BBB  BB",
        "BB            BB",
        "BB              ",
        "BB              ",
        "BB              ",
        "BB  r      r    ",
        "BB BBB    BBB   ",
        "BBBBBBB  BBBBBBB",
    ],
    (7, 0): [  # the throne room
        "BBBBBBBBBBBBBBBB",
        "BB            BB",
        "BB            BB",
        "BB f   f   f  BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "              BB",
        "              BB",
        "         A    BB",
        "       BBBBB  BB",
        "      BBBBBBB BB",
        "BBBBBBBBBBBBBBBB",
    ],
    # ---------------------------------------------------------- the surface
    (0, 1): [  # the forest, under the cliff: gawain's glade
        "########        ",
        "####            ",
        "####            ",
        "####            ",
        "####            ",
        "#######         ",
        "####            ",
        "####            ",
        "####            ",
        "####   T        ",
        "#########       ",
        "####            ",
        "####  G gTggTgtT",
        "dddddddddddddddd",
        "dddddddddddddddd",
        "dddddddddddddddd",
    ],
    (1, 1): SKY * 11 + [  # the mine shaft comes up here
        "tt              ",
        "ttgTs     N SgTs",
        "ddddd    ddddddd",
        "ddddd      ddddd",
        "ddddd    ddddddd",
    ],
    (2, 1): [  # the wizard's tower: its only door is a balcony
        "    BBBB,,,B    ",
        "    B,,,,,,B    ",
        "    B,,,,,,B    ",
        "    B,,,,,,B    ",
        "    B,,,BBBB    ",
        "    B,,,,,,B    ",
        "     ,,,,,,B    ",
        "     ,,,,,,B    ",
        "  BBBBBBBBBB    ",
        "    BBBBBBBB    ",
        "    BBBBBBBB    ",
        "    BBBBBBBB    ",
        "sgT BBBBBBBB gaS",
        "dddddddddddddddd",
        "dddddddddddddddd",
        "dddddddddddddddd",
    ],
    (3, 1): SKY * 2 + [  # the village and its church
        "           BB   ",
        "          BBBB  ",
        "         BBBBBB ",
        "         B,,+,B ",
        "         B,,,,B ",
        "         B,,,,B ",
        "  hhh    BBBB,B ",
        " hhhhh   B,,,,B ",
        " w   w   B,,,,B ",
        " w   w    ,,,,B ",
        " w s w S  ,m,,BP",
        "dddddddddddddddd",
        "dddddddddddddddd",
        "dddddddddddddddd",
    ],
    (4, 1): WALL * 11 + [  # camelot's gate, under three seals
        "   k  112233    ",
        " p  r 112233    ",
        "ddddddBBBBBBBBBB",
        "ddddddBBBBBBBBBB",
        "ddddddBBBBBBBBBB",
    ],
    (5, 1): [  # the courtyard
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "              BB",
        "       l      BB",
        "      BBB     BB",
        "      BBB     BB",
        "   k  BBB  r    ",
        " s    BBB    k  ",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
    ],
    (6, 1): [  # the great hall
        "BBBBBBB  BBBBBBB",
        "BB            BB",
        "BB  f      f  BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB  i      i  BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "                ",
        "   N  k    L  k ",
        "BBBBBBB  BBBBBBB",
        "BBBBBBB  BBBBBBB",
        "BBBBBBB  BBBBBBB",
    ],
    (7, 1): [  # the armoury
        "BBBBBBBBBBBBBBBB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB  +      *  BB",
        "BB BBB    BBB BB",
        "BB            BB",
        "              BB",
        "    k    k    BB",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
    ],
    # ---------------------------------------------------------- the under
    (1, 2): [  # the mine shaft, up to the surface
        "#####      #####",
        "#######    #####",
        "#####      #####",
        "#####    #######",
        "#####      #####",
        "#######    #####",
        "#####      #####",
        "#####    #######",
        "#####      #####",
        "#######    #####",
        "#####      #####",
        "#####    ##     ",
        "#####           ",
    ] + ROCK * 3,
    (2, 2): ROCK * 6 + [  # the mines
        "####        ####",
        "###          ###",
        "###   +      ###",
        "### ----     ###",
        "###  w       ###",
        "   x w  c  p    ",
        "   x w  cc ss s ",
    ] + ROCK * 3,
    (3, 2): ROCK * 4 + [  # the crypt door, at the top of the shaft from the deep
        "################",
        "####        ####",
        "###          ###",
        "##            ##",
        "##            ##",
        "##   i    i   ##",
        "##            ##",
        "                ",
        "     N    n     ",
        "############  ##",
        "###########   ##",
        "###########  ###",
    ],
    (4, 2): ROCK * 4 + [  # sir kay's crypt
        "################",
        "##            ##",
        "##            ##",
        "##  i  f   i  ##",
        "##            ##",
        "##            ##",
        "##            ##",
        "    ###   ### ##",
        "    n     K   ##",
    ] + ROCK * 3,
    (6, 2): [  # the dungeon under the great hall
        "BBBBBBB  BBBBBBB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB            BB",
        "BB  *      +  BB",
        "BB BBB    BBB BB",
        "BB            BB",
        "BB            BB",
        "BB  k   n  k  BB",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBB",
    ],
    # ---------------------------------------------------------- the deep
    (0, 3): ROCK * 3 + [  # behind the lair's back wall
        "#####     ######",
        "###         ####",
        "##     *     ###",
        "##    ###     ##",
        "##   #####      ",
        "##  #######     ",
    ] + ROCK * 7,
    (1, 3): ROCK * 2 + [  # the lair
        "####        ####",
        "###          ###",
        "##            ##",
        "##            ##",
        "##           w  ",
        "xx           w  ",
        "xx ND     u  w  ",
    ] + ROCK * 7,
    (2, 3): ROCK * 2 + [  # the first caverns
        "########      ##",
        "######          ",
        "#####       a   ",
        "####        ####",
        "          ######",
        "    v   ########",
        "  s v s ########",
    ] + ROCK * 7,
    (3, 3): [  # the chasm, and the shaft up to the crypt
        "###########   ##",
        "############  ##",
        "##            ##",
        "    b        ###",
        "              xx",
        "#####     ######",
        "#####     ######",
        "#######   ######",
        "#####     ######",
        "#####   ########",
        "#####     ######",
        "#######   ######",
        "#####^^   ######",
    ] + ROCK * 3,
    (4, 3): ROCK * 2 + [  # the lava cavern
        "###          ###",
        "##            ##",
        "              ##",
        "####          ##",
        "####          ##",
        "####  ##      ##",
        "####     b    ##",
        "####      ##    ",
        "####   +        ",
        "####  ###    ###",
        "####~~~~~~~~~###",
        "####~~~~~~~~~###",
    ] + ROCK * 2,
    (5, 3): ROCK * 2 + [  # the lava lake and its pillar
        "##            ##",
        "##            ##",
        "##            ##",
        "##     *      ##",
        "##    ####    ##",
        "##    ####    ##",
        "##    ####    ##",
        "      ####      ",
        "      ####      ",
        "####~~####~~####",
        "####~~####~~####",
    ] + ROCK * 3,
    (6, 3): ROCK * 3 + [  # the old hoard
        "####       #####",
        "###    +     ###",
        "##    ###     ##",
        "##            ##",
        "##  b      b  ##",
        "##            ##",
        "        N     ##",
        "    n  ###  u ##",
    ] + ROCK * 5,
}


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
# A walk over the tiles with a deliberately weak dragon: if this one can get
# somewhere, a player can. A jump rises JUMP tiles, each flap FLAP more, and
# the dragon may drift one tile sideways per tile it rises, plus a little at
# the top and two tiles for each tile it glides down. tests/test_run.p8
# measures the real jump (about 2.6 tiles) and glide.
JUMP, FLAP = 2, 2
# the legends in the order they must fall, with what each one's fall gives
STAGES = [
    ("sir kay", {"charge": True, "ward": "ward kay"}),
    ("sir gawain", {"flaps": 2, "ward": "ward gawain"}),
    ("merlin", {"flight": True, "ward": "ward merlin"}),
    ("king arthur", {}),
]
AGE_NAMES = ["whelp", "drake", "wyrm", "great wyrm"]


def reachable(grid, start, charge=False, flaps=0, flight=False, wards=()):
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

    def stands(tx, ty):
        return ty + 1 < HEIGHT and bool(flags_of(grid[ty + 1][tx]) & tiles.SOLID)

    rise, drift = JUMP + FLAP * flaps, 5 if charge else 1
    first = (start[0], start[1], rise, drift)
    seen, queue, cells = {first}, deque([first]), set()
    while queue:
        tx, ty, up, side = queue.popleft()
        cells.add((tx, ty))
        steps = []
        if flight:
            steps = [(tx + dx, ty + dy, 0, 0) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        else:
            if stands(tx, ty):
                up, side = rise, drift
                steps += [(tx + dx, ty, rise if stands(tx + dx, ty) else FLAP * flaps, drift)
                          for dx in (1, -1)]
            elif side:
                steps += [(tx + dx, ty, up, side - 1) for dx in (1, -1)]
            if up:
                steps.append((tx, ty - 1, up - 1, side))
                for dx in (1, -1):
                    if passable(tx, ty - 1) or passable(tx + dx, ty):
                        steps.append((tx + dx, ty - 1, up - 1, side))
            steps.append((tx, ty + 1, min(up, FLAP * flaps), 2))
        for step in steps:
            if passable(step[0], step[1]) and step not in seen:
                seen.add(step)
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
