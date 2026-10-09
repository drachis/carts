"""bosses.py - the mounted legends' 16x16 sprites and the spawn points' 8x8 ones.

People in this game are five pixels tall, and a legend is no bigger: what
makes one loom is the warhorse under it. The three knights share one drawing
of letters, each supplying its colours, and one more of the same horse with
the lance lowered, which the game shows while a legend gathers itself to
strike (units.lua). A 16x16 sprite is four ordinary sprites, its id the
top-left one. Merlin is not here: he is an ordinary small sprite inside an
aura the game draws.

The drawings face left, as that is easier to read in text, and are flipped.
"""
MOUNTED = [
    "..W...PP........",
    "..W..AAAA.......",
    "..W..AFFA.......",
    "..W..AAAA.......",
    "..WFAAAASS......",
    "..W.AAAASSS.....",
    ".HH.TAATSS......",
    "HHHHHHHHHHHH....",
    "H0HHHHHHHHHHHH..",
    "HHHHHHCCCHHHHHH.",
    ".HHHHHCCCHHHH.H.",
    "..HHHHHHHHHHH.H.",
    "..HH.H...H.HH...",
    "..HH.H...H.HH...",
    "..H..H...H..H...",
    ".HH.HH..HH.HH...",
]
MOUNTED_WINDUP = [
    "......PP........",
    ".....AAAA.......",
    ".....AFFA.......",
    ".....AAAA.......",
    "WWWWFAAAASS.....",
    "....AAAASSS.....",
    "HH..TAATSS......",
    "HHHHHHHHHHHH....",
    "H0HHHHHHHHHHHH..",
    ".HHHHHCCCHHHHHH.",
    ".HHHHHCCCHHHH.H.",
    "..HHHHHHHHHHH.H.",
    ".HH..H...H.HH...",
    "HH...H....H.HH..",
    "H....H.....H.H..",
    ".....HH....HH...",
]
WINDUP = 8  # sprite id offset from a legend to its wind-up frame
# A armour, T its shadow, P plume, W weapon, S shield, H horse, C its cloth
COLOURS = {
    96: dict(A="9", T="4", P="6", W="6", S="5", H="4", C="9"),    # sir kay
    98: dict(A="b", T="3", P="7", W="6", S="3", H="6", C="b"),    # sir gawain
    102: dict(A="a", T="9", P="8", W="c", S="8", H="7", C="8"),   # king arthur
}
SPAWNERS = {
    55: ["04444440", "44222244", "42222224", "42200224", "42200224", "4220a224", "42200224", "42200224"],  # hovel
    56: ["0dddddd0", "dd1111dd", "d115511d", "d151151d", "d155551d", "d151151d", "d155551d", "d155551d"],  # barracks
    57: ["55555555", "05000050", "05011050", "00500500", "00055000", "00000000", "00000000", "00000000"],  # roost
}


def sprites():
    """id -> 8 rows of 8 hex digits, the 16x16 ones cut into their four parts."""
    found = dict(SPAWNERS)
    for sprite_id, colours in COLOURS.items():
        colours = dict(colours, F="f")
        for offset, template in ((0, MOUNTED), (WINDUP, MOUNTED_WINDUP)):
            art = ["".join(colours.get(letter, letter).replace(".", "0") for letter in row[::-1])
                   for row in template]
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
                found[sprite_id + offset + dx + dy * 16] = [
                    row[dx * 8:dx * 8 + 8] for row in art[dy * 8:dy * 8 + 8]]
    return found
