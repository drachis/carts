"""gen_gfx.py - writes __gfx__, __gff__ and __sfx__ into the carts.

usage: py gen_gfx.py [cart ...]

Two conventions here are load-bearing for the Lua (see world.lua):
  * a ground tile's burnt form is the sprite 16 ids later (one row down);
  * a ground tile's sprite flags byte is its fuel: the high nibble is how
    many fire visits it burns for, the low nibble its chance in 16 of
    catching from a burning neighbour.
The dragon is drawn procedurally, so it has no sprites.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CARTS = sys.argv[1:] or ["wyrmfire.p8", "tests/test_run.p8"]
BURNT = 16  # sprite id offset from a tile to its burnt form

SPRITES = {}  # id -> 8 rows of 8 hex digits
FUEL = {}     # id -> (burn visits, catch chance in 16)

# --- ground: row 0, with burnt forms directly below in row 1 ---
GRASS, FLOWERS, TREE, WHEAT, ROAD, WATER, BRIDGE = 1, 2, 3, 4, 5, 6, 7
SCORCHED = ["55055555","50555505","55552555","05555055","55505555","55555025","25055555","55555550"]

SPRITES[GRASS]   = ["33333333","333b3333","33333333","33333b33","3333b333","b3333333","333333b3","33333333"]
SPRITES[FLOWERS] = ["33333333","33a33333","3333b333","33333333","3b3333e3","33333333","333b3333","33333333"]
SPRITES[TREE]    = ["333bb333","3bbabbb3","bbbbbbbb","bbbbbb3b","bbbb3b3b","3bb3b333","33333113","33333333"]
SPRITES[WHEAT]   = ["aa9aaa9a","9aaa9aaa","aaaaaaaa","44444444","a9aaa9aa","aaa9aaa9","aaaaaaaa","44444444"]
SPRITES[ROAD]    = ["44444444","444f4444","44444444","4f44444f","44444444","4444f444","44444444","f4444444"]
SPRITES[WATER]   = ["cccccccc","ccc1cccc","cccccc1c","c1cccccc","cccc1ccc","1ccccccc","cccc1ccc","cc1ccccc"]
SPRITES[BRIDGE]  = ["44444444","4f4f4f4f","44444444","45454545","44444444","4f4f4f4f","44444444","45454545"]

SPRITES[GRASS + BURNT]   = SCORCHED
SPRITES[FLOWERS + BURNT] = SCORCHED
SPRITES[TREE + BURNT]    = ["55055555","50500505","55044055","05044405","55044055","55500025","25055555","55555550"]  # stump
SPRITES[WHEAT + BURNT]   = ["55555555","56565656","55555555","00000000","55565556","56555655","55555555","00000000"]  # ash
SPRITES[ROAD + BURNT]    = ["55655655","56d6d555","5d566d55","6d5d5d65","5566d556","5d565d55","55d55655","55555555"]  # rubble

FUEL[GRASS] = (3, 3)
FUEL[FLOWERS] = (3, 3)
FUEL[TREE] = (8, 6)
FUEL[WHEAT] = (4, 13)

# --- buildings (roof view): row 2, the 2x2 ones spill into row 3 ---
SPRITES[32] = ["33333333","33999933","39aa9993","39a99943","3999a943","39999443","33444433","33333333"]  # hut
SPRITES[33] = ["33333333","36666663","68888886","68888886","62222226","68888886","68888886","36666663"]  # house
SPRITES[34] = ["33666633","36d6d663","6d6556d6","665dd566","665dd566","6d6556d6","36d6d663","33666633"]  # tower
CHURCH, KEEP = 36, 38

# --- units: row 4 (0 = transparent) ---
SPRITES[64] = ["00000606","00ff0666","00ff0040","04444f40","04444040","00440040","00440040","00404000"]  # serf
SPRITES[65] = ["00330400","03ff3040","00f30040","03333740","0f333040","00330040","00330400","00303000"]  # archer
SPRITES[66] = ["00088000","00666007","00656007","cc666607","cc6666f0","0c666600","00606000","00505000"]  # knight
SPRITES[67] = ["0aaaa0a0","00ff0aaa","07ff70a0","777777a0","7777f7a0","07777040","07777040","07070000"]  # champion
SPRITES[68] = ["00a9a007","00fff007","0caaaa07","cca99aaf","ccaaaa00","ccaaaa00","00a0a000","00909000"]  # legend
SPRITES[69] = ["00070000","66676660","60474060","00474000","04444400","40474040","00444000","00404000"]  # ballista
SPRITES[70] = ["00000550","00004550","00040000","00400000","44444440","45444540","44444440","05000500"]  # catapult
SPRITES[71] = ["00000000","00777700","07777770","55777770","05777770","00777700","00505000","00000000"]  # sheep


def church():
    """Cross-shaped slate roof, white walls, gold cross on the steeple end."""
    roof = [["3"] * 16 for _ in range(16)]
    for y in range(16):
        for x in range(16):
            if 5 <= x <= 10 or (1 <= x <= 14 and 4 <= y <= 9):
                roof[y][x] = "d"
    art = [row[:] for row in roof]
    for y in range(16):
        for x in range(16):
            if roof[y][x] != "d":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < 16 and 0 <= ny < 16) or roof[ny][nx] == "3":
                    art[y][x] = "7"
                    break
    for y in range(1, 15):
        art[y][7] = "5"
    for x in range(2, 14):
        art[6][x] = "5"
    for y in range(1, 5):
        art[y][8] = "a"
    art[2][7] = art[2][9] = "a"
    return art


def keep():
    """Crenellated stone keep, corner turrets, red banner."""
    art = [["3"] * 16 for _ in range(16)]
    for y in range(1, 15):
        for x in range(1, 15):
            art[y][x] = "6"
    for i in range(1, 15):
        stone = "5" if i % 2 else "6"
        art[1][i] = art[14][i] = art[i][1] = art[i][14] = stone
    for cx, cy in ((0, 0), (13, 0), (0, 13), (13, 13)):
        for y in range(3):
            for x in range(3):
                art[cy + y][cx + x] = "d"
        art[cy + 1][cx + 1] = "5"
    for y in range(4, 12):
        for x in range(4, 12):
            art[y][x] = "5"
    for y in range(5, 11):
        for x in range(5, 11):
            art[y][x] = "d"
    for y in range(5, 11):
        art[y][7] = "4"
    for y in range(5, 8):
        for x in range(8, 11):
            art[y][x] = "8"
    return art


def build_gfx():
    sheet = [["0"] * 128 for _ in range(64)]

    def blit(sprite_id, art):
        top, left = (sprite_id // 16) * 8, (sprite_id % 16) * 8
        for y, row in enumerate(art):
            for x, pixel in enumerate(row):
                sheet[top + y][left + x] = pixel

    for sprite_id, art in SPRITES.items():
        assert len(art) == 8 and all(len(row) == 8 for row in art), sprite_id
        blit(sprite_id, art)
    blit(CHURCH, church())
    blit(KEEP, keep())
    return "\n".join("".join(row) for row in sheet)


def build_gff():
    flags = [0] * 256
    for sprite_id, (visits, chance) in FUEL.items():
        assert SPRITES.get(sprite_id + BURNT), "no burnt form for %d" % sprite_id
        flags[sprite_id] = visits << 4 | chance
    text = "".join("%02x" % flag for flag in flags)
    return text[:256] + "\n" + text[256:]


# 8-hex header (editor mode, speed, loop start, loop end), then notes of
# pitch(2) waveform(1) volume(1) effect(1). ids are named in data.lua.
SFX = [
    "00030000" + "1c6301a640186401663014620",                 # 0 breath
    "00050000" + "0c2500e2500c2500a24008233",                 # 1 roar
    "00040000" + "0c6700a670086600766006650056400463003625",  # 2 crash
    "00030000" + "183501435010345",                           # 3 hurt
    "00030000" + "241301c13018125",                           # 4 die
    "00020000" + "306202c615",                                # 5 arrow
    "00070000" + "183501c3501f350243502435024345",            # 6 fanfare
    "00050000" + "0c4201042014415",                           # 7 catapult
    "00030000" + "0c530085300c53008525",                      # 8 eat
    "00060000" + "2415024140000002415024130",                 # 9 alarm bell
    # 10 coin: one triangle-wave note, so its first byte is just its pitch,
    # which main.lua pokes to make each coin ring higher than the last
    "00040000" + "30055",
    "00060000" + "046200662004610",                           # 11 wingbeat
]

# --- music: two bass patterns over one drum loop, in d minor ---
# main.lua pokes the speed byte of these sfx to raise the tempo with wrath.
MUSIC_FIRST_SFX = 16
BASS_A = [14, 14, 26, 14, 14, 26, 14, 14,  14, 14, 26, 14, 14, 26, 24, 21,
          10, 10, 22, 10, 10, 22, 10, 10,  12, 12, 24, 12, 12, 24, 21, 19]
BASS_B = [14, 14, 26, 14, 17, 17, 29, 17,  19, 19, 31, 19, 21, 21, 33, 21,
          10, 10, 22, 10, 12, 12, 24, 12,  14, 26, 14, 26, 14, 26, 21, 24]
KICK, SNARE, HAT = "04655", "1e645", "30615"
DRUMS = [KICK, HAT, SNARE, HAT, KICK, KICK, SNARE, HAT] * 4
MUSIC_HEADER = "010e0000"
# flags (1 = loop start, 2 = loop end) then one sfx per channel; 0x41+ is silent
MUSIC = ["01 10124344", "02 11124344"]


def bass(pitches):
    return MUSIC_HEADER + "".join("%02x130" % pitch for pitch in pitches)


def build_sfx():
    slots = SFX + [""] * (MUSIC_FIRST_SFX - len(SFX))
    slots += [bass(BASS_A), bass(BASS_B), MUSIC_HEADER + "".join(DRUMS)]
    return "\n".join((notes + "0" * 168)[:168] for notes in slots)


def main():
    data = "\n__gfx__\n%s\n__gff__\n%s\n__sfx__\n%s\n__music__\n%s\n" % (
        build_gfx(), build_gff(), build_sfx(), "\n".join(MUSIC))
    for cart in CARTS:
        path = os.path.join(HERE, cart)
        source = open(path, encoding="utf-8").read()
        source = re.split(r"\n__gfx__\n.*", source, flags=re.S)[0].rstrip("\n")
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(source + data)
        print("patched", cart)


if __name__ == "__main__":
    main()
