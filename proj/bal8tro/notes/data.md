# data.lua

**data.lua:30** `hand_size=8`
Tuning as globals, set by parse_record into _ENV. step_frames is the pause between scoring steps at 60fps.

**data.lua:59** `hand_specs=parse_table[[`
Balatro's level-1 values, and each hand's planet with what a level adds (level_chips, level_mult). short is the hand's name on the planet card, at most 7 characters. Order matters: evaluate() takes the last row whose name the hand contains, so rows run weakest to strongest.
Keep: names are the keys of evaluate()'s contains table and of a joker's need.

**data.lua:72** `joker_specs=parse_table[[`
when=card: fires once per scoring card that matches need (a suit number 1..4, or "face"). when=hand: fires once after the cards, if need is empty or the hand contains it. Empty chips/mult/xmult are nil. name, text and cond are the shop joker's three lines and the tooltip's; cond "per" gets the suit sprite after it. tag is the table's mini joker's second line. cost is Balatro's price; it sells for half.
Keep: name, text and cond are at most 7 characters each (the 31px shop joker); tag at most 4 (the 20px mini joker).

**data.lua:90** `blind_specs=parse_table[[`
The three blinds of every ante, with Balatro's rewards ($3, $4, $5). factor is the blind's goal multiplier in halves (Balatro's 1, 1.5, 2) so it stays whole; blind_goal uses it.

**data.lua:97** `ante_bases=split"3,8,20,50,110,200,350,500"`
Balatro's eight ante base scores, in hundreds, because 50000 is past PICO-8's 32767. A run is won by clearing the boss of the last ante.

**data.lua:99** `boss_specs=parse_table[[`
Nine of Balatro's bosses, one drawn at random when an ante's small blind starts. factor is the goal in halves of the ante base (Balatro's 2x, the wall 4x, the needle 1x). debuff is a suit; hands and discards replace the blind's; must is the fewest cards a hand may have; halve halves the base chips and mult. text is shown on the panel when no cards are picked, at most 25 characters.
