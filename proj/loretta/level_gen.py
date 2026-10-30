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
SOLID = "#_/\\g"
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


def text(rows):
    return ["".join(row) for row in rows]


# everyday Los Feliz pieces --------------------------------------------

# a squirrel hops every 5 tiles (squirrel_arc, 40px): hedges on that beat
# make its leaps land in rhythm. each chunk has a job in a chase: START has a
# squirrel and no escape, RUN keeps it going, FINISH ends it at an escape and
# sets off the next squirrel just past it. chases are judged by check_levels.
BEAT = 5


def beat_hedges(rows, first, count, rnd, top=12):
    """Hedges on the squirrel's beat, some skipped, up to `count`."""
    x = first
    for _ in range(count):
        for y in (top - 2, top - 1):
            rows[y][x] = rows[y][x + 1] = "g"
        x += BEAT * rnd.choice([2, 3])
        if x > 29:
            break


def shop_street(rnd):
    """START. Storefronts on a sidewalk, a squirrel, then a clear run."""
    rows = empty()
    ground(rows, 12, letter="_")
    put(rows, rnd.randint(2, 6), 11, "K")
    awning = rnd.randint(16, 20)
    for x in range(awning, awning + 8):
        rows[9][x] = "^"
    put(rows, awning, 11, "K")
    put(rows, rnd.choice([1, 13, 14]), 11, "Y")
    put(rows, rnd.randint(9, 12), 11, "s")
    beat_hedges(rows, 28, 1, rnd)
    return rows


def garden_street(rnd):
    """RUN then FINISH. Bungalows, front hedges, a neighbour, a tree to end on."""
    rows = empty()
    ground(rows, 12)
    put(rows, 2, 11, "h")
    put(rows, rnd.randint(9, 12), 11, "n")
    put(rows, rnd.randint(4, 6), 11, "K")
    put(rows, rnd.randint(18, 21), 11, "K")
    beat_hedges(rows, 14, 2, rnd)
    for x in rnd.sample(range(1, 26), 4):
        put(rows, x, 11, rnd.choice("f,"))
    put(rows, 27, 11, "T")
    put(rows, 30, 11, "s")
    return rows


def pond_yard(rnd):
    """FINISH in a bush. A garden pond to clear, then roses to dive into."""
    rows = empty()
    ground(rows, 12)
    start = rnd.randint(8, 12)
    width = rnd.randint(3, 4)
    pit(rows, start, start + width - 1)
    put(rows, rnd.randint(2, 5), 11, "K")
    beat_hedges(rows, start + width + 3, 1, rnd)
    put(rows, 25, 11, "d")
    put(rows, 26, 11, "s")
    return rows


def fork(rnd):
    """RUN. Terraces: a stepped rise and fall for big arcs against the sky."""
    rows = empty()
    ground(rows, 12)
    x = rnd.randint(5, 7)
    for step, height in enumerate((1, 2, 3, 2, 1)):
        for column in range(x + step * 4, x + step * 4 + 4):
            for y in range(12 - height, 12):
                rows[y][column] = "#"
    put(rows, 2, 11, "f")
    put(rows, 28, 11, "T")
    put(rows, 30, 11, "s")
    return rows


def fern_dell(rnd):
    """RUN. The stream: banks and ferns, water to hop over, a sycamore last."""
    rows = empty()
    ground(rows, 12)
    x = rnd.randint(5, 7)
    while x < 22:
        width = rnd.randint(3, 4)
        pit(rows, x, x + width - 1)
        put(rows, x + width + 1, 11, "F")
        x += width + BEAT
    put(rows, 1, 11, "F")
    put(rows, 2, 11, "W")
    put(rows, 28, 11, "T")
    put(rows, 30, 11, "s")
    return rows


def trail(rnd):
    """START and FINISH on the high trail: a ravine or two, chaparral."""
    rows = empty()
    ground(rows, 8)
    start = rnd.randint(9, 12)
    width = rnd.randint(4, 5)
    pit(rows, start, start + width - 1, top=8)
    put(rows, 2, 7, "h")
    put(rows, rnd.randint(4, 7), 7, "Q")
    put(rows, 6, 7, "s")
    beat_hedges(rows, start + width + 2, 1, rnd, top=8)
    put(rows, 28, 7, "T")
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
