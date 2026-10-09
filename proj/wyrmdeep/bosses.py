"""bosses.py - the legends' 16x16 sprites and the spawn points' 8x8 ones.

A legend is drawn from a template of letters, each legend supplying the
colours, so three knights share one drawing. The game draws them at 24
pixels (units.lua); a 16x16 sprite is four ordinary sprites, its id the
top-left one.
"""
KNIGHT = [
    "......PP........",
    ".....PPPP.....W.",
    "....AAAAAA....W.",
    "...AAAAAAAA...W.",
    "...AT0FF0TA...W.",
    "...AATTTTAA...W.",
    "....AAAAAA...GGG",
    ".SSTAAAAAATT..G.",
    "SSSSAAAAAAAAFFG.",
    "SSCSAAATTAAA....",
    "SSSSAAAAAAAA....",
    ".SS.TAAAAAAT....",
    "....AAA..AAA....",
    "....AAA..AAA....",
    "....TTT..TTT....",
    "...TTTT..TTTT...",
]
WIZARD = [
    ".......A........",
    "......AAA.....C.",
    ".....AAAAA...CWC",
    "....AAACAAA...C.",
    "...AAAAAAAAA..G.",
    "....FFFFFF....G.",
    "....F0FF0F....G.",
    "....77FF77....G.",
    "...A777777AFF.G.",
    "..AAA7777AAA..G.",
    "..AAAA77AAAA..G.",
    "..AAAAAAAAAA..G.",
    "..AAACAAACAA..G.",
    ".AAAAAAAAAAAA.G.",
    ".AAAAAAAAAAAA...",
    ".TTTTTTTTTTTT...",
]
# the same two, winding up: the knight's blade drawn back over his head, the
# wizard's staff raised with its orb swollen. the game shows these while a
# legend gathers itself to strike (units.lua)
KNIGHT_WINDUP = [
    "................",
    ".W....PP........",
    ".W...PPPP.......",
    ".W..AAAAAA......",
    ".G.AAAAAAAA.....",
    "GGGAT0FF0TA.....",
    ".GFAATTTTAA.....",
    "..FFAAAAAA......",
    "..TAAAAAAATTSS..",
    "...AAAAAAAASSSS.",
    "...AAATTAAASSCS.",
    "...AAAAAAAASSSS.",
    "...TAAAAAAT.SS..",
    "..AAAA..AAAA....",
    "..TTT....TTT....",
    ".TTTT....TTTT...",
]
WIZARD_WINDUP = [
    ".......A....CCC.",
    "......AAA..CWWWC",
    ".....AAAAA.CWWWC",
    "....AAACAAA.CCC.",
    "...AAAAAAAAA.G..",
    "....FFFFFF...G..",
    "....F0FF0F..FG..",
    "....77FF77.AFG..",
    "...A777777AA.G..",
    "..AAA7777AA..G..",
    "..AAAA77AAA.....",
    "..AAAAAAAAAA....",
    "..AAACAAACAA....",
    ".AAAAAAAAAAAA...",
    ".AAAAAAAAAAAA...",
    ".TTTTTTTTTTTT...",
]
WINDUP = 8  # sprite id offset from a legend to its wind-up frame
COLOURS = {
    96: dict(A="9", T="4", P="6", W="6", G="5", S="5", C="9"),    # sir kay
    98: dict(A="b", T="3", P="7", W="6", G="4", S="3", C="a"),    # sir gawain
    100: dict(A="c", T="1", C="a", W="e", G="4"),                 # merlin
    102: dict(A="a", T="9", P="8", W="c", G="9", S="8", C="a"),   # king arthur
}
# sprite id -> (template, {letter: colour}); F is always skin
LEGENDS = {}
for _id, _colours in COLOURS.items():
    _wizard = "P" not in _colours
    LEGENDS[_id] = (WIZARD if _wizard else KNIGHT, _colours)
    LEGENDS[_id + WINDUP] = (WIZARD_WINDUP if _wizard else KNIGHT_WINDUP, _colours)
SPAWNERS = {
    54: ["05555550", "55000055", "50000005", "50000005", "50000005", "54000045", "54000045", "54000045"],  # mine mouth
    55: ["04444440", "44222244", "42222224", "42200224", "42200224", "4220a224", "42200224", "42200224"],  # hovel
    56: ["0dddddd0", "dd1111dd", "d115511d", "d151151d", "d155551d", "d151151d", "d155551d", "d155551d"],  # barracks
    57: ["55555555", "05000050", "05011050", "00500500", "00055000", "00000000", "00000000", "00000000"],  # roost
}


def sprites():
    """id -> 8 rows of 8 hex digits, the 16x16 ones cut into their four parts."""
    found = dict(SPAWNERS)
    for sprite_id, (template, colours) in LEGENDS.items():
        colours = dict(colours, F="f")
        art = ["".join(colours.get(letter, letter).replace(".", "0") for letter in row)
               for row in template]
        for part, (dx, dy) in enumerate(((0, 0), (1, 0), (0, 1), (1, 1))):
            found[sprite_id + dx + dy * 16] = [row[dx * 8:dx * 8 + 8] for row in art[dy * 8:dy * 8 + 8]]
    return found
