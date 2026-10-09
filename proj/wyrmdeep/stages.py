"""stages.py - the four stages, each one screen tall and eight screens long.

A stage is a script: a list of (column, stamp) laid along the ground from
left to right. A stamp is a small block of text (level.py explains the
characters) whose bottom row stands on the ground; a plain string is a stamp
one row tall. The last screen of each stage is left clear for its legend.

The map stores the stages one under the other, 16 rows each.
"""
WIDTH, ROWS, GROUND = 128, 16, 13  # the ground is rows 13..15

HUT = [" hhh ",
       "hhhhh",
       "w   w",
       "  H w"]
BARN = ["hhhhhhh",
        "w     w",
        "w C P w"]
SHED = ["wwww",
        "w+ w",
        "w  w"]
STORE = ["wwww",
         "w* w",
         "w  w"]
HAY = ["h", "h"]
# stone: a charge brings it down
TOWER = [" a  ",
         "XXX ",
         "XXX ",
         "XXX ",
         "XXXQ"]
CHURCH = ["  B  ",
          " BBB ",
          "BB,BB",
          "B,,,B",
          "B,m,X"]
# a curtain wall to the top of the sky: its gate is the only way on
WALL = ["BBB"] * 9 + ["XXX"] * 4
ALOFT = ["M"] + [" "] * 6
# the lair each stage starts in, its hoard heaped inside (main.lua draws that)
LAIR = ["#####",
        "#    ",
        "#    ",
        "#    "]

# (name, ground character, script)
STAGES = [
    ("the shire", "d", [
        (6, "g gT g S g"), (20, HUT), (27, "S gTg"), (34, HAY), (36, "g S S g"),
        (46, BARN), (55, "TgT s s"), (64, HUT), (70, HUT), (77, "g s T"),
        (82, SHED), (88, "TgTgT gSg"), (98, HUT), (104, "g g T"), (118, "K"),
    ]),
    ("the town", "d", [
        (6, "g s s T"), (14, HUT), (21, TOWER), (27, "s p g"), (32, HUT),
        (40, CHURCH), (47, "S g P"), (52, TOWER), (58, HUT), (64, "p p a"),
        (72, BARN), (80, TOWER), (85, STORE), (91, TOWER), (97, "g T g k"),
        (104, SHED), (118, "G"),
    ]),
    ("the castle", "=", [
        (6, "k p p"), (14, WALL), (20, "Q  k r"), (30, TOWER), (36, "l"),
        (40, WALL), (46, "m m Q"), (56, TOWER), (62, CHURCH), (70, "k k r"),
        (78, WALL), (84, "Q p p k"), (94, TOWER), (100, "r r"), (104, STORE),
        (116, ALOFT),
    ]),
    ("camelot", "=", [
        (6, "k k m"), (12, WALL), (18, "Q k Q"), (26, TOWER), (31, TOWER),
        (38, "m r m"), (44, WALL), (50, CHURCH), (58, "Q k k Q"), (68, WALL),
        (74, TOWER), (80, "l  r r"), (88, WALL), (94, "k m k Q"), (102, SHED),
        (118, "A"),
    ]),
]


def lines():
    """The whole map as 64 strings of 128 characters."""
    text = []
    for name, ground, script in STAGES:
        rows = [[" "] * WIDTH for _ in range(GROUND)]
        for column, stamp in [(0, LAIR)] + script:
            if isinstance(stamp, str):
                stamp = [stamp]
            top = GROUND - len(stamp)
            for y, row in enumerate(stamp):
                for x, char in enumerate(row):
                    if char != " ":
                        assert rows[top + y][column + x] == " ", "%s: stamps overlap at column %d" % (
                            name, column + x)
                        rows[top + y][column + x] = char
        text += ["".join(row) for row in rows] + [ground * WIDTH] * (ROWS - GROUND)
    return text
