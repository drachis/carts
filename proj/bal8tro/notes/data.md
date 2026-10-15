# data.lua

**data.lua:30** `hand_size=8`
Tuning as globals, set by parse_record into _ENV. step_frames is the pause between scoring steps at 60fps.

**data.lua:47** `hand_specs=parse_table[[`
Balatro's level-1 values. Order matters: evaluate() takes the last row whose name the hand contains, so rows run weakest to strongest.
Keep: names are the keys of evaluate()'s contains table and of a joker's need.

**data.lua:60** `joker_specs=parse_table[[`
when=card: fires once per scoring card that matches need (a suit number 1..4, or "face"). when=hand: fires once after the cards, if need is empty or the hand contains it. Empty chips/mult/xmult are nil. name, text and cond are the joker's three lines; cond "per" gets the suit sprite after it. cost is Balatro's price; it sells for half.
Keep: name, text and cond are at most 7 characters each, to fit the 31px joker that lets four sit across the screen.

**data.lua:78** `blind_specs=parse_table[[`
One ante: three blinds, with Balatro's goals and rewards ($3, $4, $5). Goals are plain numbers here and become 32-bit (>>16) in start_blind.
