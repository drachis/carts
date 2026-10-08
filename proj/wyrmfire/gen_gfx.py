# gen_gfx.py - builds __gfx__ + __sfx__ for wyrmfire.p8. run: py gen_gfx.py
# the dragon itself is drawn procedurally (wyrmfire.lua); this is tiles,
# buildings and the people sent to stop it.
import re, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
CARTS = sys.argv[1:] or ["wyrmfire.p8", "tests/test_run.p8"]
S = {}  # id -> 8 rows of 8 hex digits

# --- ground tiles (ids match tfl/tdur/tres in wyrmfire.lua) ---
S[1] = ["33333333","333b3333","33333333","33333b33","3333b333","b3333333","333333b3","33333333"]  # grass
S[2] = ["33333333","33a33333","3333b333","33333333","3b3333e3","33333333","333b3333","33333333"]  # grass + flowers
S[3] = ["333bb333","3bbabbb3","bbbbbbbb","bbbbbb3b","bbbb3b3b","3bb3b333","33333113","33333333"]  # tree
S[4] = ["44444444","444f4444","44444444","4f44444f","44444444","4444f444","44444444","f4444444"]  # dirt road
S[5] = ["cccccccc","ccc1cccc","cccccc1c","c1cccccc","cccc1ccc","1ccccccc","cccc1ccc","cc1ccccc"]  # water
S[6] = ["55055555","50555505","55552555","05555055","55505555","55555025","25055555","55555550"]  # scorched
S[7] = ["55055555","50500505","55044055","05044405","55044055","55500025","25055555","55555550"]  # burnt stump
S[8] = ["aa9aaa9a","9aaa9aaa","aaaaaaaa","44444444","a9aaa9aa","aaa9aaa9","aaaaaaaa","44444444"]  # wheat
S[9] = ["44444444","4f4f4f4f","44444444","45454545","44444444","4f4f4f4f","44444444","45454545"]  # bridge
S[10]= ["55655655","56d6d555","5d566d55","6d5d5d65","5566d556","5d565d55","55d55655","55555555"]  # rubble
S[12]= ["55555555","56565656","55555555","00000000","55565556","56555655","55555555","00000000"]  # ash field

# --- 1x1 buildings (roof view) ---
S[16]= ["33333333","33999933","39aa9993","39a99943","3999a943","39999443","33444433","33333333"]  # thatch hut
S[17]= ["33333333","36666663","68888886","68888886","62222226","68888886","68888886","36666663"]  # red-roof house
S[18]= ["33666633","36d6d663","6d6556d6","665dd566","665dd566","6d6556d6","36d6d663","33666633"]  # watchtower

# --- units (0 = transparent) ---
S[64]= ["00000606","00ff0666","00ff0040","04444f40","04444040","00440040","00440040","00404000"]  # serf + pitchfork
S[65]= ["00330400","03ff3040","00f30040","03333740","0f333040","00330040","00330400","00303000"]  # archer
S[66]= ["00088000","00666007","00656007","cc666607","cc6666f0","0c666600","00606000","00505000"]  # knight
S[67]= ["0aaaa0a0","00ff0aaa","07ff70a0","777777a0","7777f7a0","07777040","07777040","07070000"]  # holy champion
S[68]= ["00a9a007","00fff007","0caaaa07","cca99aaf","ccaaaa00","ccaaaa00","00a0a000","00909000"]  # legend
S[69]= ["00070000","66676660","60474060","00474000","04444400","40474040","00444000","00404000"]  # ballista
S[70]= ["00000550","00004550","00040000","00400000","44444440","45444540","44444440","05000500"]  # catapult
S[71]= ["00000000","00777700","07777770","55777770","05777770","00777700","00505000","00000000"]  # sheep

def church():  # cross-shaped slate roof, white walls, gold cross on the steeple end
    g=[["3"]*16 for _ in range(16)]
    for y in range(16):
        for x in range(16):
            if (5<=x<=10) or (1<=x<=14 and 4<=y<=9): g[y][x]="d"
    out=[r[:] for r in g]
    for y in range(16):
        for x in range(16):
            if g[y][x]!="d": continue
            for dx,dy in((1,0),(-1,0),(0,1),(0,-1)):
                nx,ny=x+dx,y+dy
                if not(0<=nx<16 and 0<=ny<16) or g[ny][nx]=="3":
                    out[y][x]="7"; break
    for y in range(1,15): out[y][7]="5"
    for x in range(2,14): out[6][x]="5"
    for y in range(1,5): out[y][8]="a"
    out[2][7]="a"; out[2][9]="a"
    return out

def keep():  # crenellated stone keep, corner turrets, red banner
    g=[["3"]*16 for _ in range(16)]
    for y in range(1,15):
        for x in range(1,15): g[y][x]="6"
    for i in range(1,15):
        c="5" if i%2 else "6"
        g[1][i]=c; g[14][i]=c; g[i][1]=c; g[i][14]=c
    for cx,cy in((0,0),(13,0),(0,13),(13,13)):
        for y in range(3):
            for x in range(3): g[cy+y][cx+x]="d"
        g[cy+1][cx+1]="5"
    for y in range(4,12):
        for x in range(4,12): g[y][x]="5"
    for y in range(5,11):
        for x in range(5,11): g[y][x]="d"
    for y in range(5,11): g[y][7]="4"
    for y in range(5,8):
        for x in range(8,11): g[y][x]="8"
    return g

rows=[["0"]*128 for _ in range(64)]
def blit(sid,art):
    sr,sc=(sid//16)*8,(sid%16)*8
    for y,r in enumerate(art):
        for x,c in enumerate(r): rows[sr+y][sc+x]=c
for sid,art in S.items():
    assert len(art)==8 and all(len(r)==8 for r in art), sid
    blit(sid,art)
blit(32,church())
blit(34,keep())
gfx="\n".join("".join(r) for r in rows)

# sfx: 8-hex header (mode,speed,loop) + notes of pitch(2) wave(1) vol(1) fx(1)
SFX = [
    "00030000"+"1c6301a640186401663014620",                       # 0 breath
    "00050000"+"0c2500e2500c2500a24008233",                       # 1 roar / charge
    "00040000"+"0c6700a670086600766006650056400463003625",        # 2 building falls
    "00030000"+"183501435010345",                                 # 3 dragon hurt
    "00030000"+"241301c13018125",                                 # 4 unit dies
    "00020000"+"306202c615",                                      # 5 arrow
    "00070000"+"183501c3501f350243502435024345",                  # 6 fanfare
    "00050000"+"0c4201042014415",                                 # 7 catapult
    "00030000"+"0c530085300c53008525",                            # 8 eat
]
sfx="\n".join((s+"0"*168)[:168] for s in SFX)

for c in CARTS:
    p=os.path.join(HERE,c)
    src=open(p,encoding="utf-8").read()
    src=re.split(r"\n__gfx__\n.*",src,flags=re.S)[0].rstrip("\n")
    src+="\n__gfx__\n"+gfx+"\n__sfx__\n"+sfx+"\n"
    open(p,"w",encoding="utf-8",newline="\n").write(src)
    print("patched",p)
