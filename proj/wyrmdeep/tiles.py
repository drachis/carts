"""tiles.py - terrain sprites and their flags.

Load-bearing for the Lua (see world.lua):
  * the flags below are the sprite flag bits the game tests;
  * what is left of a tile that burns or breaks is the sprite 16 ids later,
    so every destroyable tile lives in row 0 with its remains in row 1.
"""
SOLID, FLAMMABLE, BRITTLE, HAZARD = 1, 2, 4, 8
REMAINS = 16

SPRITES = {}  # id -> 8 rows of 8 hex digits
FLAGS = {}    # id -> flag bits
NAMES = {}    # name -> id, for level.py and for data.lua's tile_ constants


def tile(name, sprite_id, flags, art, remains=None):
    NAMES[name] = sprite_id
    SPRITES[sprite_id] = art
    FLAGS[sprite_id] = flags
    if flags & (FLAMMABLE | BRITTLE):
        SPRITES[sprite_id + REMAINS] = remains or ["00000000"] * 8


EMPTY = "00000000"

# --- row 0: what fire or a charge can destroy ---
tile("wood", 1, SOLID | FLAMMABLE,
     ["44f444f4", "44f444f4", "44f444f4", "22222222", "f444f444", "f444f444", "f444f444", "22222222"],
     [EMPTY] * 6 + ["00500000", "05150500"])
tile("bridge", 2, SOLID | FLAMMABLE,
     ["f4f4f4f4", "44444444", "22222222", "04200420", "00420420", "00042200", "00002000", EMPTY])
tile("thorns", 3, SOLID | FLAMMABLE,
     ["03000b30", "3b303003", "03b33b30", "30033003", "b3300b33", "03b33030", "3003b303", "0b300b30"],
     [EMPTY] * 6 + ["00050000", "50505050"])
tile("crate", 4, SOLID | FLAMMABLE | BRITTLE,
     ["44444444", "4f4444f4", "44f44f44", "444ff444", "444ff444", "44f44f44", "4f4444f4", "44444444"],
     [EMPTY] * 6 + ["00040200", "04f42440"])
tile("cracked rock", 5, SOLID | BRITTLE,
     ["55505555", "5d500515", "55055555", "50155d05", "55505055", "d5550551", "55515055", "55555505"],
     [EMPTY] * 6 + ["00050500", "05d55150"])
tile("cracked brick", 6, SOLID | BRITTLE,
     ["ddd5d0dd", "ddd50ddd", "55550555", "d5dd0dd5", "d5d0ddd5", "55505555", "dd05dddd", "d0d5dddd"],
     [EMPTY] * 6 + ["000d0500", "0d5dd5d0"])
tile("vine", 7, FLAMMABLE,
     ["00030000", "000b0000", "00030000", "0003b000", "00030000", "00b30000", "00030000", "00030000"])
tile("hay", 8, FLAMMABLE,
     ["a9aaa9aa", "9aaa9aaa", "aa9aaaa9", "aaaa9aaa", "a9aaaa9a", "aaa9aaaa", "9aaaa9aa", "aa9aaaaa"],
     [EMPTY] * 7 + ["05050505"])
tile("tree", 9, FLAMMABLE,
     ["003bb300", "03bbabb0", "3bbbbbb3", "3bbb3bb3", "03b3bb30", "00044000", "00044000", "00044000"],
     [EMPTY] * 5 + ["00044000", "00044000", "00444400"])
tile("grass", 10, FLAMMABLE,
     [EMPTY] * 5 + ["0b000b00", "b30b03b0", "3b3b3b3b"],
     [EMPTY] * 7 + ["50505050"])
# the three seals: colour c is theirs alone among the tiles, so main.lua can
# make them shimmer by remapping it. each falls with its legend (data.lua)
tile("ward kay", 12, SOLID,
     ["c0c0c0c0", "0c0c0c0c", "c0c99c0c", "0c9779c0", "c09779c0", "0c099c0c", "c0c0c0c0", "0c0c0c0c"])
tile("ward gawain", 13, SOLID,
     ["c0c0c0c0", "0c0c0c0c", "c0cbbc0c", "0cb77bc0", "c0b77bc0", "0c0bbc0c", "c0c0c0c0", "0c0c0c0c"])
tile("ward merlin", 14, SOLID,
     ["c0c0c0c0", "0c0c0c0c", "c0ceec0c", "0ce77ec0", "c0e77ec0", "0c0eec0c", "c0c0c0c0", "0c0c0c0c"])
tile("fire", 15, 0,
     [EMPTY] * 5 + ["00500050", "05050505", "50505050"])

# --- rows 2 and 3: terrain and scenery that never changes ---
tile("rock", 32, SOLID,
     ["55555555", "5d555515", "55555555", "55155d55", "55555555", "d5555551", "55515555", "55555555"])
tile("rock top", 33, SOLID,
     ["6d66d6d6", "d5555d55", "55555555", "55155555", "55555d55", "5d555551", "55515555", "55555555"])
tile("rock alt", 34, SOLID,
     ["55555555", "55511555", "55555555", "d5555555", "5555d555", "55555515", "51555555", "55555555"])
tile("dirt", 35, SOLID,
     ["44444444", "44244444", "44444f44", "44444444", "4f444424", "44444444", "44424444", "44444444"])
tile("turf", 36, SOLID,
     ["b3bb3b3b", "3b33b333", "43343443", "44444444", "4f444424", "44444444", "44424444", "44444444"])
tile("brick", 37, SOLID,
     ["ddd5dddd", "ddd5dddd", "55555555", "d5ddddd5", "d5ddddd5", "55555555", "ddd5dddd", "ddd5dddd"])
tile("brick top", 38, SOLID,
     ["67676767", "ddd5dddd", "55555555", "d5ddddd5", "d5ddddd5", "55555555", "ddd5dddd", "ddd5dddd"])
tile("brick back", 39, 0,
     ["11101111", "11101111", "00000000", "10111110", "10111110", "00000000", "11101111", "11101111"])
tile("spikes", 40, HAZARD,
     [EMPTY] * 3 + ["06000600", "06000600", "6d606d60", "6d606d60", "ddd6ddd6"])
tile("lava", 41, HAZARD,
     ["89989998", "98899889", "88988988", "98898898", "89889889", "88988998", "98899889", "89988988"])
tile("lava top", 42, HAZARD,
     [EMPTY, "a0000a00", "9a99a9a9", "89989998", "89889889", "88988998", "98899889", "89988988"])
tile("nest", 43, 0,
     [EMPTY] * 4 + ["40000004", "94a00a49", "49499494", "04444440"])
tile("torch", 44, 0,
     ["000a0000", "00a9a000", "00898000", "00040000", "00040000", "00040000", EMPTY, EMPTY])
tile("window", 45, 0,
     ["11101111", "11555511", "05111150", "15111151", "15111151", "05111150", "11555511", "11101111"])
tile("stalactite", 46, 0,
     ["55555555", "05555550", "05555500", "00555500", "00055000", "00055000", "00050000", EMPTY])
tile("mushroom", 47, 0,
     [EMPTY] * 4 + ["00e8e000", "0e888e00", "00070000", "00070000"])
tile("bones", 48, 0,
     [EMPTY] * 6 + ["07600670", "06777760"])
tile("banner", 49, 0,
     ["08888800", "08a8a800", "088a8800", "08a8a800", "08888800", "08808800", "08000800", EMPTY])
