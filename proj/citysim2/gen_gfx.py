# gen_gfx.py - builds __gfx__ + __gff__ for citysim2.p8 from the tile encoding.
# sprite id == tile id, so map() renders the city directly. run: py gen_gfx.py
import re, os
HERE = os.path.dirname(os.path.abspath(__file__))
CART = os.path.join(HERE, "citysim2.p8")
S = {}  # id -> 8 rows of 8 hex digits

S[0] = ["1111111c","11c11111","1111111c","111c1111","c1111111","1111c111","11111111","c111111c"]  # water
S[1] = ["33333333","333b3333","33333333","33333b33","3333b333","b3333333","333333b3","33333333"]  # grass
S[2] = ["33355333","3357d533","355ddd53","55d6d6d5","5d6d6d65","dddddddd","5d5dd5d5","55555555"]  # mountain

# roads 16..31: grey asphalt, yellow centre dashes toward connected sides
def road(m):
    g=[["5"]*8 for _ in range(8)]
    n,e,s,w=m&1,m&2,m&4,m&8
    if not n:
        for x in range(8): g[0][x]="6"
    if not s:
        for x in range(8): g[7][x]="6"
    if not w:
        for y in range(8): g[y][0]="6"
    if not e:
        for y in range(8): g[y][7]="6"
    g[3][3]="a"; g[4][4]="a"
    if n: g[1][3]="a"
    if s: g[6][4]="a"
    if w: g[3][1]="a"
    if e: g[4][6]="a"
    return ["".join(r) for r in g]
for m in range(16): S[16+m]=road(m)

# power lines 32..47: dark wire on grass, poles at junctions
def wire(m):
    g=[["3"]*8 for _ in range(8)]
    n,e,s,w=m&1,m&2,m&4,m&8
    if n:
        for y in range(0,4): g[y][3]="0"
    if s:
        for y in range(4,8): g[y][3]="0"
    if w:
        for x in range(0,4): g[3][x]="0"
    if e:
        for x in range(4,8): g[3][x]="0"
    g[3][3]="0"; g[4][3]="4" if m else "0"
    return ["".join(r) for r in g]
for m in range(16): S[32+m]=wire(m)

# zones 48..59 : R(48-51) C(52-55) I(56-59), density 0..3. d0 = dashed plot,
# d1..3 = a building of growing height in the zone colour (R grn,C blu,I yel).
ZC={0:("b","3"),1:("c","1"),2:("a","4")}  # (accent, body) per kind index
def zone(ki,d):
    acc,body=ZC[ki]
    g=[["3"]*8 for _ in range(8)]
    if d==0:  # empty plot: dashed border in the zone colour
        for i in range(0,8,2):
            g[0][i]=acc; g[7][i]=acc; g[i][0]=acc; g[i][7]=acc
        return ["".join(r) for r in g]
    h=1+d*2  # building height grows with density
    for y in range(8-h,8):
        for x in range(1,7):
            g[y][x]=body
    for y in range(8-h,8,2):
        for x in range(2,6,2):
            g[y][x]="7"  # lit windows
    for x in range(8): g[7][x]=acc  # coloured base strip
    return ["".join(r) for r in g]
for ki in range(3):
    for d in range(4):
        S[48+ki*4+d]=zone(ki,d)

S[60] = [  # power plant: grey block, smokestacks, orange core
    "36333633","34333433","55555555","559a9555",
    "55aaa555","55595555","55555555","88888888",
]
S[61] = [  # park: bushes, a flower, a path
    "33333333","3bb33bb3","3bbb3bb3","33b3eb33",
    "3433b333","333bb3b3","33b333b3","33333333",
]
S[62] = [  # fire station: red house, white bay door, "ladder" roof
    "33333333","36666663","68888886","68822886",
    "68822886","68888886","67777776","37777773",
]
S[63] = [  # rubble: charred grey debris over scorched ground
    "33533533","55656555","56555655","65555565",
    "55656556","53565555","55555655","55555555",
]

rows=[["0"]*128 for _ in range(64)]
for sid,art in S.items():
    sr,sc=(sid//16)*8,(sid%16)*8
    for y in range(8):
        for x in range(8):
            rows[sr+y][sc+x]=art[y][x]
gfx="\n".join("".join(r) for r in rows)

# flags unused by sim (map.lua predicates are id-range based) but harmless
gff="\n".join("0"*256 for _ in range(2))

# sound effects (reused from citysim1). slot -> short blip; padded to 168 hex
# (8-hex header + 32 notes x 5 hex). sound.lua names the slots.
SFX = [
    "000800001e15024150",                  # 0 deny  : two-note low blip
    "000800000c6500a65008650",             # 1 doze  : descending clear
    "000800002413030130",                  # 2 place : rising confirm
    "000c0000182501e250182501e250",        # 3 fire  : alternating alarm
    "000600002c13030130",                  # 4 boom  : high blip
]
sfx="\n".join((s+"0"*168)[:168] for s in SFX)

src=open(CART,encoding="utf-8").read()
src=re.split(r"\n__gfx__\n.*",src,flags=re.S)[0].rstrip("\n")
src+="\n__gfx__\n"+gfx+"\n__gff__\n"+gff+"\n__sfx__\n"+sfx+"\n"
open(CART,"w",encoding="utf-8",newline="\n").write(src)
print("patched",CART)
