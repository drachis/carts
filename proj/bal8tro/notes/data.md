# data.lua

**data.lua:30** `hand_size=8`
Tuning as globals, set by parse_record into _ENV. step_frames is the pause between scoring steps at 60fps.

**data.lua:53** `hand_specs=parse_table[[`
Balatro's level-1 values, and each hand's planet with what a level adds (level_chips, level_mult). short is the hand's name on the planet card, at most 7 characters. Order matters: evaluate() takes the last row whose name the hand contains, so rows run weakest to strongest.
Keep: names are the keys of evaluate()'s contains table and of a joker's need.

**data.lua:66** `joker_specs=parse_table[[`
when=card: fires once per scoring card that matches need (a suit number 1..4, or "face"). when=hand: fires once after the cards, if need is empty or the hand contains it. Empty chips/mult/xmult are nil. name, text and cond are the joker's three lines; cond "per" gets the suit sprite after it. cost is Balatro's price; it sells for half.
Keep: name, text and cond are at most 7 characters each, to fit the 31px joker that lets four sit across the screen.

**data.lua:84** `blind_specs=parse_table[[`
The three blinds of every ante, with Balatro's rewards ($3, $4, $5). factor is the blind's goal multiplier in halves (Balatro's 1, 1.5, 2) so it stays whole; blind_goal uses it.

**data.lua:91** `ante_bases=split"3,8,20,50,110,200,350,500"`
Balatro's eight ante base scores, in hundreds, because 50000 is past PICO-8's 32767. A run is won by clearing the boss of the last ante.
