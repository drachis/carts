"""art.py - unit sprites, sound effects and music, carried over from wyrmfire.

Terrain sprites are in tiles.py; gen_cart.py assembles the cart.
"""

SPRITES = {}  # id -> 8 rows of 8 hex digits
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
# what anything eaten becomes on its way to the growth gauge (units.lua)
SPRITES[74] = ["00000000","00888000","08e88800","08888800","08888200","00222670","00006777","00000770"]  # meat on the bone

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

# --- new for wyrmdeep ---
SPRITES[83] = ["00000000","50000005","55055055","55555555","05585850","00555500","00000000","00000000"]  # bat
SPRITES[95] = ["00000000","08800880","8e888888","88888888","08888880","00888800","00088000","00000000"]  # relic: heart
SPRITES[68] = ["00000000","000a0000","00a9a000","0a989a00","0a888a00","00a8a000","000a0000","00000000"]  # relic: brimstone
