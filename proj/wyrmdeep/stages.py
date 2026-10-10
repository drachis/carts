"""stages.py - the ground the four stages are built on.

The map stores the stages one under the other, 16 rows each. All that is
drawn ahead of time is each stage's ground and the lair it starts in: the
towns, castles and keeps are built by the game as it goes (build_block in
world.lua), from the stamps in data.lua.
"""
WIDTH, ROWS, GROUND = 128, 16, 13  # the ground is rows 13..15

# the lair each stage starts in, its hoard heaped inside (main.lua draws that)
LAIR = ["########",
        "#       ",
        "#       ",
        "#       ",
        "#       ",
        "#       "]

# (name, ground character)
STAGES = [("the shire", "d"), ("the town", "d"), ("the castle", "="), ("camelot", "=")]


def lines():
    """The whole map as 64 strings of 128 characters."""
    text = []
    for name, ground in STAGES:
        rows = [[" "] * WIDTH for _ in range(GROUND)]
        top = GROUND - len(LAIR)
        for y, row in enumerate(LAIR):
            rows[top + y][:len(row)] = row
        text += ["".join(row) for row in rows] + [ground * WIDTH] * (ROWS - GROUND)
    return text
