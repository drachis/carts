"""tiles.py - terrain sprites and their flags.

Load-bearing for the Lua (see world.lua):
  * the flags below are the sprite flag bits the game tests;
  * what is left of a tile that burns or breaks is the sprite 16 ids later.
"""
# flammable burns; brittle falls to any charge; stone only to the ram that
# the first legend gives
SOLID, FLAMMABLE, BRITTLE, HAZARD, STONE = 1, 2, 4, 8, 16
REMAINS = 16

SPRITES = {}  # id -> 8 rows of 8 hex digits
FLAGS = {}    # id -> flag bits
NAMES = {}    # name -> id, for level.py and gen_cart.py

EMPTY = "00000000"
RUBBLE = [EMPTY] * 6 + ["000d0500", "0d5dd5d0"]
CINDERS = [EMPTY] * 6 + ["00500000", "05150500"]


def tile(name, sprite_id, flags, art, remains=None):
    NAMES[name] = sprite_id
    SPRITES[sprite_id] = art
    FLAGS[sprite_id] = flags
    if flags & (FLAMMABLE | BRITTLE | STONE):
        assert sprite_id + REMAINS not in SPRITES, "the remains of %s land on another sprite" % name
        SPRITES[sprite_id + REMAINS] = remains or ["00000000"] * 8


# --- row 0: timber, thatch and greenery; their remains are row 1 ---
tile("wood", 1, SOLID | FLAMMABLE | BRITTLE,
     ["44f444f4", "44f444f4", "44f444f4", "22222222", "f444f444", "f444f444", "f444f444", "22222222"],
     CINDERS)
tile("bridge", 2, SOLID | FLAMMABLE | BRITTLE,
     ["f4f4f4f4", "44444444", "22222222", "04200420", "00420420", "00042200", "00002000", EMPTY])
tile("thorns", 3, SOLID | FLAMMABLE | BRITTLE,
     ["03000b30", "3b303003", "03b33b30", "30033003", "b3300b33", "03b33030", "3003b303", "0b300b30"],
     [EMPTY] * 6 + ["00050000", "50505050"])
tile("crate", 4, SOLID | FLAMMABLE | BRITTLE,
     ["44444444", "4f4444f4", "44f44f44", "444ff444", "444ff444", "44f44f44", "4f4444f4", "44444444"],
     [EMPTY] * 6 + ["00040200", "04f42440"])
tile("cracked brick", 6, SOLID | STONE,
     ["ddd5d0dd", "ddd50ddd", "55550555", "d5dd0dd5", "d5d0ddd5", "55505555", "dd05dddd", "d0d5dddd"],
     RUBBLE)
tile("vine", 7, FLAMMABLE,
     ["00030000", "000b0000", "00030000", "0003b000", "00030000", "00b30000", "00030000", "00030000"])
tile("hay", 8, SOLID | FLAMMABLE | BRITTLE,
     ["a9aaa9aa", "9aaa9aaa", "aa9aaaa9", "aaaa9aaa", "a9aaaa9a", "aaa9aaaa", "9aaaa9aa", "aa9aaaaa"],
     [EMPTY] * 7 + ["05050505"])
tile("tree", 9, FLAMMABLE,
     ["003bb300", "03bbabb0", "3bbbbbb3", "3bbb3bb3", "03b3bb30", "00044000", "00044000", "00044000"],
     [EMPTY] * 5 + ["00044000", "00044000", "00444400"])
tile("grass", 10, FLAMMABLE,
     [EMPTY] * 5 + ["0b000b00", "b30b03b0", "3b3b3b3b"],
     [EMPTY] * 7 + ["50505050"])
tile("fire", 15, 0,
     [EMPTY] * 5 + ["00500050", "05050505", "50505050"])

# --- row 2: ground, masonry and scenery; masonry's rubble is row 3 ---
tile("rock", 32, SOLID,
     ["55555555", "55555555", "555d5555", "55555555", "55555555", "55555155", "55555555", "55555555"])
tile("dirt", 35, SOLID,
     ["44444444", "44244444", "44444f44", "44444444", "4f444424", "44444444", "44424444", "44444444"])
tile("turf", 36, SOLID,
     ["b3bb3b3b", "3b33b333", "43343443", "44444444", "4f444424", "44444444", "44424444", "44444444"])
tile("brick", 37, SOLID | STONE,
     ["ddd5dddd", "ddd5dddd", "55555555", "d5ddddd5", "d5ddddd5", "55555555", "ddd5dddd", "ddd5dddd"],
     RUBBLE)
tile("brick top", 38, SOLID | STONE,
     ["67676767", "ddd5dddd", "55555555", "d5ddddd5", "d5ddddd5", "55555555", "ddd5dddd", "ddd5dddd"],
     RUBBLE)
tile("brick back", 39, 0,
     ["11101111", "11101111", "00000000", "10111110", "10111110", "00000000", "11101111", "11101111"])
tile("paving", 40, SOLID,
     ["67676767", "ddd5dddd", "55555555", "d5ddddd5", "d5ddddd5", "55555555", "ddd5dddd", "ddd5dddd"])
tile("paving deep", 41, SOLID,
     ["ddd5dddd", "ddd5dddd", "55555555", "d5ddddd5", "d5ddddd5", "55555555", "ddd5dddd", "ddd5dddd"])
tile("torch", 44, 0,
     ["000a0000", "00a9a000", "00898000", "00040000", "00040000", "00040000", EMPTY, EMPTY])
tile("banner", 49, 0,
     ["08888800", "08a8a800", "088a8800", "08a8a800", "08888800", "08808800", "08000800", EMPTY])
# an unseen lid and end walls on each stage
tile("cap", 51, SOLID, [EMPTY] * 8)
