# gen_gfx.py - builds the __gfx__ + __gff__ sections of citysim.p8
# sprites are authored as 8 rows of 8 hex digits (pico-8 palette indices).
# roads (16..31) and the dashed zone-plot borders are generated procedurally.
# run:  py gen_gfx.py   (patches citysim.p8 in place)

import re, os

HERE = os.path.dirname(os.path.abspath(__file__))
CART = os.path.join(HERE, "citysim.p8")

S = {}  # id -> list of 8 strings

S[1] = [  # grass
    "33333333",
    "333b3333",
    "33333333",
    "33333333",
    "3333b333",
    "33333333",
    "3b333333",
    "33333333",
]
S[2] = [  # trees
    "33333333",
    "33bb3333",
    "3bbbb333",
    "3bbbb3b3",
    "334b3bbb",
    "33333bb3",
    "33333433",
    "33333333",
]
S[3] = [  # water
    "cccccccc",
    "cc1ccccc",
    "cccccc1c",
    "cccccccc",
    "c1cccccc",
    "cccc1ccc",
    "cccccccc",
    "cc1ccccc",
]

# roads 16..31: asphalt 5, curb 6 on unconnected sides, yellow dashes toward
# connected sides (mask n=1 e=2 s=4 w=8)
def road(mask):
    g = [["5"] * 8 for _ in range(8)]
    n, e, s, w = mask & 1, mask & 2, mask & 4, mask & 8
    if not n:
        for x in range(8): g[0][x] = "6"
    if not s:
        for x in range(8): g[7][x] = "6"
    if not w:
        for y in range(8): g[y][0] = "6"
    if not e:
        for y in range(8): g[y][7] = "6"
    if mask:
        g[3][3] = "a"
        if n: g[0][3] = "a"; g[2][3] = "a"
        if s: g[5][3] = "a"; g[7][3] = "a"
        if w: g[3][0] = "a"; g[3][2] = "a"
        if e: g[3][5] = "a"; g[3][7] = "a"
    return ["".join(r) for r in g]

for m in range(16):
    S[16 + m] = road(m)

# zone plots (density 0): grass + dashed border in zone color + letter
GLYPH = {
    "r": ["##.", "#.#", "##.", "#.#", "#.#"],
    "c": [".##", "#..", "#..", "#..", ".##"],
    "i": ["###", ".#.", ".#.", ".#.", "###"],
}
def plot(col, letter):
    g = [["3"] * 8 for _ in range(8)]
    for i in range(0, 8, 2):
        g[0][i] = col; g[7][i] = col; g[i][0] = col; g[i][7] = col
    for gy, row in enumerate(GLYPH[letter]):
        for gx, ch in enumerate(row):
            if ch == "#":
                g[2 + gy][2 + gx] = "7"
    return ["".join(r) for r in g]

S[32] = plot("b", "r")
S[36] = plot("c", "c")
S[40] = plot("a", "i")

S[33] = [  # r1: one house
    "33333333",
    "33333333",
    "33888833",
    "38888883",
    "33ffff33",
    "33fa4f33",
    "33ff4f33",
    "33333333",
]
S[34] = [  # r2: two houses
    "33333333",
    "38833883",
    "38833883",
    "3ff33ff3",
    "3f433f43",
    "33333333",
    "33b33b33",
    "33333333",
]
S[35] = [  # r3: apartment block
    "55555555",
    "66666666",
    "6a6a6a66",
    "66666666",
    "6a6a6a66",
    "66666666",
    "6a6a6a66",
    "66644666",
]
S[37] = [  # c1: shop with awning
    "33333333",
    "33333333",
    "36666663",
    "3c7c7c63",
    "36666663",
    "36aa6463",
    "36666663",
    "33333333",
]
S[38] = [  # c2: store with sign
    "33333333",
    "3aaaa333",
    "36666663",
    "3cc6cc63",
    "36666663",
    "3cc64463",
    "36666663",
    "33333333",
]
S[39] = [  # c3: glass office tower
    "31111113",
    "317c7c13",
    "31111113",
    "317c7c13",
    "31111113",
    "317c7c13",
    "31111113",
    "31144113",
]
S[41] = [  # i1: small factory
    "33333333",
    "33336633",
    "33334333",
    "35555553",
    "35555553",
    "35959553",
    "35555553",
    "33333333",
]
S[42] = [  # i2: sawtooth factory
    "33333333",
    "65656565",
    "55555555",
    "55555555",
    "59955995",
    "55555555",
    "55445555",
    "33333333",
]
S[43] = [  # i3: heavy plant
    "36333633",
    "34333433",
    "55555555",
    "59955995",
    "55555555",
    "59955995",
    "55555555",
    "a5a5a5a5",
]
S[48] = [  # power plant
    "33633363",
    "34333433",
    "55555555",
    "555aa555",
    "55aa5555",
    "5555a555",
    "55555555",
    "88888888",
]
# power lines 80..95: wire autotile, id = 80 + mask of conductive
# neighbors (n=1 e=2 s=4 w=8); wires visibly bend toward whatever they feed
def wire(mask):
    g = [["3"] * 8 for _ in range(8)]
    n, e, s, w = mask & 1, mask & 2, mask & 4, mask & 8
    if n:
        for y in range(0, 4): g[y][3] = "6"
    if s:
        for y in range(3, 8): g[y][3] = "6"
    if e:
        for x in range(3, 8): g[3][x] = "6"
    if w:
        for x in range(0, 4): g[3][x] = "6"
    if mask == 0:  # lone pole with crossbar
        for y in range(2, 7): g[y][3] = "4"
        for x in range(2, 6): g[2][x] = "6"
    else:          # support post beside the junction
        g[4][4] = "4"
        g[5][4] = "4"
    return ["".join(r) for r in g]

for m in range(16):
    S[80 + m] = wire(m)

S[64] = [  # fire station
    "33333333",
    "88888888",
    "87788778",
    "88888888",
    "87777778",
    "87777778",
    "88888888",
    "33333333",
]
S[65] = [  # police station
    "33333333",
    "cccccccc",
    "c1c11c1c",
    "cccccccc",
    "cca77acc",
    "cc7117cc",
    "cccccccc",
    "33333333",
]
S[66] = [  # school
    "33a43333",
    "33343333",
    "44444444",
    "47477474",
    "44444444",
    "44477444",
    "44477444",
    "33333333",
]
S[44] = [  # park: bushes, a flower, a bird?  just a nice green spot
    "33333333",
    "3bb33b33",
    "3bbb3bb3",
    "33b33bb3",
    "333333e3",
    "38333333",
    "333b3b33",
    "33333333",
]
S[55] = [  # fire
    "00000000",
    "00090000",
    "00990900",
    "09a99900",
    "9aaa9990",
    "9aaaa990",
    "89aaa980",
    "08888800",
]
S[56] = [  # rubble
    "00000000",
    "05606450",
    "56655065",
    "05446550",
    "50655406",
    "06554650",
    "55065565",
    "00000000",
]

S[59] = [  # bridge, road runs e-w
    "cccccccc",
    "66666666",
    "44444444",
    "45444544",
    "44544454",
    "44444444",
    "cc6cc6cc",
    "cccccccc",
]
S[60] = ["c6444" + ("5" if y % 3 == 1 else "4") + "6c" for y in range(8)]  # n-s bridge
S[61] = [  # power pylon standing in water
    "ccc6cccc",
    "ccc6cccc",
    "ccc6cccc",
    "cc464ccc",
    "ccc6cccc",
    "ccc6cccc",
    "cc444ccc",
    "cccccccc",
]

# road/powerline crossings: line passes perpendicular over a straight road
g = road(10)  # e+w road
S[53] = [r[:3] + "6" + r[4:] for r in g]
g = road(5)   # n+s road
S[54] = [("66666666" if y == 2 else r) for y, r in enumerate(g)]

S[52] = [  # "no power" bolt overlay (black=transparent)
    "00000000",
    "000aaa00",
    "00aaa000",
    "0aaaaa00",
    "000aa000",
    "00aa0000",
    "0aa00000",
    "00000000",
]

# compose sheet: sprites 0..95 -> 48 pixel rows of 128 hex chars
rows = [["0"] * 128 for _ in range(48)]
for sid, art in S.items():
    assert len(art) == 8 and all(len(r) == 8 for r in art), sid
    sr, sc = (sid // 16) * 8, (sid % 16) * 8
    for y in range(8):
        for x in range(8):
            rows[sr + y][sc + x] = art[y][x]
gfx = "\n".join("".join(r) for r in rows)

# flags: 1 road, 2 zone, 4 conducts, 8 buildable
flags = [0] * 256
flags[1] = flags[2] = 8
for i in range(16, 32): flags[i] = 1
for i in range(32, 44): flags[i] = 6
flags[48] = 4
flags[53] = flags[54] = 5  # road + conducts
flags[59] = flags[60] = 1  # bridges are roads
flags[61] = 4              # water pylon conducts
for i in range(64, 67): flags[i] = 4  # services join the power grid
for i in range(80, 96): flags[i] = 4  # wire autotiles conduct
gff = "\n".join(
    "".join("%02x" % f for f in flags[line * 128 : (line + 1) * 128])
    for line in range(2)
)

with open(CART, "r", encoding="utf-8") as f:
    src = f.read()
# sfx: header(mode,speed,loopstart,loopend) + 32 notes of pitch(2)wave(1)vol(1)fx(1)
def sfx(speed, notes):
    body = "".join(notes) + "00000" * (32 - len(notes))
    return "00%02x0000%s" % (speed, body)

sfx_lines = [
    sfx(8, ["1e150", "24150"]),                    # 0: place blip
    sfx(8, ["0c650", "0a650", "08650"]),           # 1: deny / bulldoze crunch
    sfx(8, ["24130", "30130"]),                    # 2: month chime
    sfx(12, ["18250", "1e250", "18250", "1e250"]), # 3: fire alarm
    sfx(6, ["2c130", "30130"]),                    # 4: zone growth pop
    "" , "", "",                                   # 5-7 reserved
]
# 8: bass loop, 9: melody loop (background music, costs no code tokens)
bass = []
for n in (0x18, 0x13, 0x15, 0x11):
    bass += ["%02x520" % n] * 8
mel_seq = [0x24, 0, 0x27, 0x29, 0x2b, 0, 0x29, 0x27,
           0x24, 0, 0x27, 0, 0x29, 0, 0, 0,
           0x2b, 0, 0x2e, 0, 0x30, 0, 0x2e, 0x2b,
           0x29, 0, 0x27, 0x29, 0x24, 0, 0, 0]
mel = ["%02x220" % n if n else "00000" for n in mel_seq]
sfx_lines[5] = sfx(24, bass)   # use slots 8/9 via padding below
sfx_lines[6] = sfx(24, mel)
sfx_lines = sfx_lines[:5] + [sfx(8, [])] * 3 + [sfx_lines[5], sfx_lines[6]]

music_lines = ["03 08094344"]

src = re.split(r"\n__gfx__\n.*", src, flags=re.S)[0].rstrip("\n")
src += ("\n__gfx__\n" + gfx + "\n__gff__\n" + gff +
        "\n__sfx__\n" + "\n".join(sfx_lines) +
        "\n__music__\n" + "\n".join(music_lines) + "\n")
with open(CART, "w", encoding="utf-8", newline="\n") as f:
    f.write(src)
print("patched", CART)
