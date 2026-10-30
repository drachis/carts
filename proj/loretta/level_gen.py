"""level_gen.py - generates Loretta's everyday chunks and checks each can be crossed.

usage: py level_gen.py          prints the chunks and what the check found

gen_cart.py imports GENERATED (a dict of chunk name to 16 rows of 32
letters, the level text letters of gen_cart.py). Each generator below
builds one kind of Los Feliz piece from a seeded random choice; the seed
that gives a chunk passing the crossing check is kept, so the output is
fixed until a generator changes.

Slots, not props: K is a building, T a tree, d a piece of garden decor.
The game picks which building, tree or decor each slot shows, and its
colours, from where the slot is and which level it is in (things.lua
draw_slot), so a chunk used ten times looks different each time.

The crossing check models Loretta's moves in tiles: walk on, run up or
down a slope, jump up to RISE tiles higher onto anything within REACH
tiles (less the higher it is), fall any distance. It searches from the
chunk's left edge at its entry height to its right edge.
"""
import random

RISE = 5      # a held jump: about 46px, under 6 tiles
REACH = 7     # tiles across at the same height (about 70px held)
SOLID = "#_/\\"
STAND = SOLID + "=-^"


def empty():
    return [["."] * 32 for _ in range(16)]


def ground(rows, top, first=0, last=31, letter="#"):
    for x in range(first, last + 1):
        for y in range(top, 16):
            rows[y][x] = letter if y == top or letter == "#" else "#"


def pit(rows, first, last, top=12, water=True):
    for x in range(first, last + 1):
        for y in range(top, 16):
            rows[y][x] = "~" if water and y >= 13 else "."


def put(rows, x, y, letter):
    if 0 <= x < 32 and rows[y][x] == ".":
        rows[y][x] = letter


def coins(rows, x, y, count, step=1):
    for i in range(count):
        put(rows, x + i * step, y, "o")


def text(rows):
    return ["".join(row) for row in rows]


# everyday Los Feliz pieces --------------------------------------------

def shop_street(rnd):
    """Storefronts on a sidewalk, an awning to hop onto, a lamp."""
    rows = empty()
    ground(rows, 12, letter="_")
    shop = rnd.randint(2, 6)
    put(rows, shop, 11, "K")
    awning = rnd.randint(16, 20)
    for x in range(awning, awning + 8):
        rows[9][x] = "^"
    put(rows, awning, 11, "K")
    coins(rows, awning + 2, 8, 4)
    put(rows, rnd.choice([1, 13, 14]), 11, "Y")
    put(rows, rnd.randint(9, 12), 11, "s")
    put(rows, 30, 11, "d")
    return rows


def garden_street(rnd):
    """Bungalows behind front gardens, lush trees, a hydrant."""
    rows = empty()
    ground(rows, 12)
    put(rows, 2, 11, "h")
    put(rows, rnd.randint(9, 12), 11, "n")
    put(rows, rnd.randint(4, 6), 11, "K")
    put(rows, rnd.randint(18, 21), 11, "K")
    for x in rnd.sample(range(1, 31), 5):
        put(rows, x, 11, rnd.choice("fd,"))
    put(rows, rnd.choice([14, 15, 29]), 11, "T")
    put(rows, rnd.randint(24, 28), 11, "s")
    coins(rows, rnd.randint(8, 12), 9, 3, 2)
    return rows


def pond_yard(rnd):
    """A front yard with a garden pond to clear and a porch roof above it."""
    rows = empty()
    ground(rows, 12)
    start = rnd.randint(12, 16)
    width = rnd.randint(3, 5)
    pit(rows, start, start + width - 1)
    put(rows, rnd.randint(2, 5), 11, "K")
    for x in range(start - 2, start + width + 2):
        rows[8][x] = "="
    coins(rows, start - 1, 7, width + 2)
    put(rows, start + width + rnd.randint(2, 5), 11, "s")
    put(rows, 28, 11, "T")
    for x in rnd.sample(range(1, 11), 3):
        put(rows, x, 11, rnd.choice("fd"))
    return rows


def fork(rnd):
    """Two ways on: over planks for coins, or across a pit below."""
    rows = empty()
    ground(rows, 12)
    start = rnd.randint(11, 14)
    width = rnd.randint(5, 7)
    pit(rows, start, start + width - 1)
    left, middle, right = rnd.randint(3, 5), start, start + width + 2
    for x in range(left, left + 7):
        rows[9][x] = "="
    for x in range(middle, middle + 8):
        rows[7][x] = "="
    for x in range(right, min(right + 7, 31)):
        rows[9][x] = "="
    coins(rows, middle + 1, 6, 6)
    put(rows, 2, 11, "T")
    put(rows, right + 2, 11, "s")
    return rows


def fern_dell(rnd):
    """The stream: planks with rails, ferns, a sycamore."""
    rows = empty()
    ground(rows, 12, 0, 3)
    ground(rows, 12, 28, 31)
    pit(rows, 4, 27)
    gap = rnd.randint(12, 15)
    for x in range(5, gap):
        rows[10][x] = "="
    for x in range(gap + 4, 27):
        rows[10][x] = "="
    put(rows, 5, 9, "R")
    put(rows, gap + 4, 9, "R")
    coins(rows, gap, 7, 4)
    put(rows, 1, 11, "F")
    put(rows, 2, 11, "W")
    put(rows, 28, 11, "F")
    put(rows, 30, 11, "T")
    return rows


def trail(rnd):
    """The high trail: a ravine to jump, chaparral, a hiker resting."""
    rows = empty()
    ground(rows, 8)
    start = rnd.randint(9, 12)
    width = rnd.randint(4, 6)
    pit(rows, start, start + width - 1, top=8)
    put(rows, 2, 7, "h")
    put(rows, rnd.randint(4, 7), 7, "Q")
    put(rows, start + width + 3, 7, "T")
    put(rows, start + width + 7, 7, "s")
    coins(rows, start, 5, width)
    put(rows, 29, 7, "d")
    return rows


GENERATORS = {
    "shop_street": shop_street, "garden_street": garden_street,
    "pond_yard": pond_yard, "fork": fork, "fern_dell": fern_dell, "trail": trail,
}


def surfaces(rows, x):
    """Heights (rows) a dog can stand on in column x."""
    tops = []
    for y in range(1, 16):
        if rows[y][x] in STAND and rows[y - 1][x] not in SOLID:
            tops.append(y)
    return tops


def crossable(rows):
    """Can she get from the left edge to the right edge? (and how)"""
    start = surfaces(rows, 0)
    if not start:
        return False
    seen = {(0, start[-1])}
    todo = [(0, start[-1])]
    while todo:
        x, y = todo.pop()
        if x == 31:
            return True
        for dx in range(1, REACH + 2):
            if x + dx > 31:
                break
            for top in surfaces(rows, x + dx):
                rise = y - top
                ok = (dx == 1 and abs(rise) <= 1) or (rise <= RISE and dx <= REACH - max(rise, 0) + (1 if rise < 0 else 0))
                if ok and (x + dx, top) not in seen:
                    seen.add((x + dx, top))
                    todo.append((x + dx, top))
    return False


def generate(name, first_seed=1):
    for seed in range(first_seed, first_seed + 200):
        rows = GENERATORS[name](random.Random(seed * 101 + len(name)))
        if crossable(rows):
            return text(rows), seed
    raise ValueError("no crossable %s in 200 seeds" % name)


GENERATED = {name: generate(name)[0] for name in GENERATORS}


def main():
    for name in GENERATORS:
        rows, seed = generate(name)
        print("%s (seed %d)" % (name, seed))
        for row in rows:
            print("  " + row)


if __name__ == "__main__":
    main()
