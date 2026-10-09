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
CARTS = sys.argv[1:] or ["wyrmfire.p8", "tests/test_run.p8", "tests/test_title.p8"]
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
SPRITES[72] = ["00660007","00660070","0c667700","04444440","f4444444","04444440","04000040","04000040"]  # lancer (mounted)
SPRITES[73] = ["000c0000","00ccc000","0ccccc00","00fff0a0","00777040","0ccccc40","0ccccc40","0c000c40"]  # merlin
SPRITES[75] = ["00000600","00ff0600","00ff0600","05550400","5555f400","05550400","00500400","00505000"]  # pikeman
SPRITES[76] = ["00000000","00220000","02ff2000","002f0660","02222464","0f222660","00220000","00202000"]  # crossbowman
SPRITES[77] = ["00044000","004ff400","000ff000","04444070","44444777","04444070","04444000","04004000"]  # monk
SPRITES[78] = ["000aa000","00777007","00757007","aa777707","aa7777f0","0a777700","00707000","00a0a000"]  # paladin
SPRITES[79] = ["40000000","04000550","00404550","00044000","00444000","04444440","45444454","05000050"]  # trebuchet
SPRITES[80] = ["00020000","00222000","02222200","00fff0e0","00222020","02222220","02222220","02000220"]  # morgan le fay
SPRITES[81] = ["00000000","07747700","77447770","57777770","05777470","00777700","00505000","00000000"]  # cow
SPRITES[82] = ["00000000","00000000","00eeee00","0eeeeee0","2eeeeee0","0eeeeee0","00e00e00","00000000"]  # pig
# each legend's own look, in true colors (data.lua's `color` only recolors
# gold, color a, which these mostly avoid)
SPRITES[84] = ["00666000","00fff050","04999955","449999f0","44999900","04999900","00909000","00404000"]  # sir kay
SPRITES[85] = ["00b3b007","00fff007","03bbbb07","33b33bbf","33bbbb00","03bbbb00","00b0b000","00303000"]  # sir gawain
SPRITES[86] = ["00e7e000","00fff090","07eeee09","77e77eef","77eeee00","07eeee00","00e0e000","00202000"]  # sir percival
SPRITES[87] = ["09999007","00fff007","07777707","c77c777f","c7777700","c7777700","00707000","00606000"]  # sir galahad
SPRITES[88] = ["00585000","00555008","05555508","25555558","25555500","05555500","00505000","00101000"]  # the black knight
SPRITES[89] = ["00848000","00fff007","02888807","22888c8f","22888800","02888800","00808000","00202000"]  # sir tristan
SPRITES[90] = ["00c6c007","00fff007","01cccc07","11c66ccf","11cccc00","01cccc00","00c0c000","00101000"]  # sir lancelot
SPRITES[91] = ["00202008","00fff008","05222208","5528822f","55222200","05222200","00202000","00101000"]  # mordred
SPRITES[92] = ["09a9a00c","00fff00c","08aaaa0c","88a99aaf","88aaaa00","88aaaa00","00a0a000","00909000"]  # king arthur
SPRITES[93] = ["00b30040","0bffb004","00fb0704","0bbbb704","fbbb0704","00bb0004","00bb0040","00b0b000"]  # longbowman
SPRITES[94] = ["00000000","000d0000","00ddd000","00fff0e0","00ddd040","0ddddd40","0ddddd40","0d000d00"]  # apprentice
# more 1x1 buildings, in the free slots of the buildings row
SPRITES[40] = ["33333333","34444443","48888884","48877884","48877884","48888884","34444443","33333333"]  # barn
SPRITES[41] = ["33333333","34444443","44f4f4f4","4f4f4f44","44444444","45555554","34444443","33333333"]  # stable
SPRITES[42] = ["33333333","35555553","56666665","56c66c65","56666665","56c66c65","35555553","33333333"]  # barracks
SPRITES[43] = ["33333333","34444443","44999944","49955994","49955994","44999944","34444443","33333533"]  # workshop
SPRITES[44] = ["33111133","31cccc13","1cc22cc1","1c2ee2c1","1c2ee2c1","1cc22cc1","31cccc13","33111133"]  # wizard tower
SPRITES[45] = ["37333373","33733733","33677633","33766733","33677633","33733733","37333373","33333333"]  # windmill
SPRITES[46] = ["33333333","33666633","36daad63","36aaaa63","36daad63","36dddd63","33666633","33333333"]  # chapel
# what anything eaten becomes on its way to the growth gauge (units.lua)
SPRITES[74] = ["00000000","00888000","08e88800","08888800","08888200","00222670","00006777","00000770"]  # meat on the bone


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


MINSTER, BARRACKS, WIZARD_TOWER = 96, 98, 100  # 2x2, in rows 6 and 7


def minster():
    """A great cross of a church with twin west towers and a gold cross."""
    roof = [["3"] * 16 for _ in range(16)]
    for y in range(16):
        for x in range(16):
            if 4 <= x <= 11 or 3 <= y <= 10:
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
        art[y][7] = art[y][8] = "5"
    for x in range(1, 15):
        art[6][x] = art[7][x] = "5"
    for cx in (4, 9):  # the towers
        for y in range(12, 15):
            for x in range(cx, cx + 3):
                art[y][x] = "6"
        art[13][cx + 1] = "1"
    for y in range(4, 10):
        art[y][7] = art[y][8] = "a"
    for x in range(5, 11):
        art[6][x] = art[7][x] = "a"
    return art


def barracks():
    """A long slate hall with blue banners and a wooden door."""
    art = [["3"] * 16 for _ in range(16)]
    for y in range(2, 14):
        for x in range(1, 15):
            art[y][x] = "5"
    for y in range(3, 13):
        for x in range(2, 14):
            art[y][x] = "6"
    for x in range(2, 14):
        art[7][x] = art[8][x] = "d"
    for bx, by in ((3, 4), (11, 4), (3, 10), (11, 10)):
        art[by][bx] = art[by][bx + 1] = art[by + 1][bx] = "c"
    for x in range(7, 9):
        art[12][x] = art[13][x] = "4"
    return art


def wizard_tower():
    """A round blue tower seen from above, with a glowing eye of a roof."""
    art = [["3"] * 16 for _ in range(16)]
    for y in range(16):
        for x in range(16):
            reach = (x - 7.5) ** 2 + (y - 7.5) ** 2
            if reach < 7.5 ** 2:
                art[y][x] = "1"
            if reach < 6 ** 2:
                art[y][x] = "c"
            if reach < 4 ** 2:
                art[y][x] = "2"
            if reach < 2 ** 2:
                art[y][x] = "e"
    for x, y in ((7, 2), (8, 13), (2, 8), (13, 7)):  # stars on the roof
        art[y][x] = "a"
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
    blit(MINSTER, minster())
    blit(BARRACKS, barracks())
    blit(WIZARD_TOWER, wizard_tower())
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
    # 3 hurt: one low square-wave note that fades out (effect 5). its second
    # byte is 0x50 + 2 * volume, which dragon.lua pokes to match the blow
    "000c0000" + "0c355",
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
    # 12 on: the voices of the shots, named by number in data.lua's shot table
    "00020000" + "286201c610",                                # 12 quarrel: a dry snap
    "00040000" + "341403b135",                                # 13 holy: a high chime
    "00080000" + "185301f53024535",                           # 14 smite: a rising organ chord
    "00040000" + "207301a73020725",                           # 15 hex: a phaser warble
]
# sfx 16..21 and 26..28 are the music (below); these sit between and after
MORE_SFX = {
    22: "00030000" + "2c740307402c735",                       # arcane: a bright zap
    23: "00030000" + "30340373403c335",                       # excalibur: a ringing blade
    24: "00080000" + "086400664004635",                       # boulder: a low groan of timber
    25: "00020000" + "3035024345",                            # rebuke: a clang
    # three of each, one picked at random (units.lua): data.lua names the first
    29: "00030000" + "241301c13018125",                       # die: a falling cry
    30: "00030000" + "1c1301813014125",                       #      a lower one
    31: "00030000" + "18130241301c125",                       #      a yelp
    32: "00030000" + "0c530085300c53008525",                  # eat: a crunch
    33: "00030000" + "0a530065300a53006525",                  #      a deeper one
    34: "00040000" + "0e5300a5300e525",                       #      a gulp
}

# --- music, in d minor ---
# roaming (music 0..3): four soft triangle bass lines on every other step,
#   by turns over a sparse drum loop and under a slow melody, for the open
#   country.
# battle (music 4..7): the same four as driving saw lines over a full drum
#   loop.
# main.lua switches between the two by their first pattern, 0 and 4.
BASS_A = [14, 14, 26, 14, 14, 26, 14, 14,  14, 14, 26, 14, 14, 26, 24, 21,
          10, 10, 22, 10, 10, 22, 10, 10,  12, 12, 24, 12, 12, 24, 21, 19]
BASS_B = [14, 14, 26, 14, 17, 17, 29, 17,  19, 19, 31, 19, 21, 21, 33, 21,
          10, 10, 22, 10, 12, 12, 24, 12,  14, 26, 14, 26, 14, 26, 21, 24]
BASS_C = [17, 17, 29, 17, 17, 29, 17, 17,  12, 12, 24, 12, 12, 24, 12, 12,
          14, 14, 26, 14, 14, 26, 14, 14,  21, 21, 33, 21, 21, 33, 19, 21]
BASS_D = [10, 10, 22, 10, 10, 22, 10, 10,  12, 12, 24, 12, 12, 24, 12, 12,
          14, 14, 26, 14, 17, 17, 29, 17,  21, 21, 33, 21, 21, 33, 21, 21]
# a note every fourth step: d f g a g f d c d
MELODY = {0: 38, 4: 41, 8: 43, 12: 45, 14: 43, 16: 41, 20: 38, 24: 36, 28: 38}
# and its answer: a g f d c d f d
MELODY_2 = {0: 45, 4: 43, 8: 41, 12: 38, 16: 36, 20: 38, 24: 41, 28: 38}
REST = "00000"
KICK, SNARE, HAT = "04655", "1e645", "30615"
SPARSE_DRUMS = [KICK, REST, REST, REST, HAT, REST, REST, REST] * 4
FULL_DRUMS = [KICK, HAT, SNARE, HAT, KICK, KICK, SNARE, HAT] * 4
MUSIC_HEADER = "010e0000"


def soft_bass(pitches):
    """Triangle wave, quiet, with a rest on every other step."""
    return MUSIC_HEADER + "".join(
        "%02x025" % pitch if step % 2 == 0 else REST for step, pitch in enumerate(pitches))


def driving_bass(pitches):
    """Saw wave on every step."""
    return MUSIC_HEADER + "".join("%02x130" % pitch for pitch in pitches)


def melody(notes):
    """Organ, quiet and fading, on the steps given."""
    return MUSIC_HEADER + "".join(
        "%02x525" % notes[step] if step in notes else REST for step in range(32))


MUSIC_SFX = {
    16: soft_bass(BASS_A), 17: soft_bass(BASS_B), 18: MUSIC_HEADER + "".join(SPARSE_DRUMS),
    19: driving_bass(BASS_A), 20: driving_bass(BASS_B), 21: MUSIC_HEADER + "".join(FULL_DRUMS),
    26: driving_bass(BASS_C), 27: driving_bass(BASS_D), 28: melody(MELODY),
    35: soft_bass(BASS_C), 36: soft_bass(BASS_D), 37: melody(MELODY_2),
}
# flags (1 = loop start, 2 = loop end) then one sfx (in hex) per channel;
# 0x41 and up is a silent channel
MUSIC = ["01 10124344", "00 111c4344", "00 23124344", "02 24254344",    # roaming
         "01 13154344", "00 14154344", "00 1a154344", "02 1b154344"]    # battle


def build_sfx():
    slots = dict(enumerate(SFX))
    slots.update(MORE_SFX)
    slots.update(MUSIC_SFX)
    return "\n".join((slots.get(i, "") + "0" * 168)[:168] for i in range(max(slots) + 1))


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
