# data.lua

**data.lua:30** `hand_size=8`
Tuning as globals, set by parse_record into _ENV. step_frames is the pause between scoring steps at 60fps.

**data.lua:60** `hand_specs=parse_table[[`
Balatro's level-1 values, and each hand's planet with what a level adds (level_chips, level_mult). short is the hand's name on the planet card, at most 7 characters. Order matters: evaluate() takes the last row whose name the hand contains, so rows run weakest to strongest.
Keep: names are the keys of evaluate()'s contains table and of a joker's need.

**data.lua:73** `joker_specs=parse_table[[`
when=card: fires once per scoring card that matches need (a suit number 1..4, or "face"). when=hand: fires once after the cards, if need is empty or the hand contains it. Empty chips/mult/xmult are nil. name, text and cond are the shop joker's three lines and the tooltip's; cond "per" gets the suit sprite after it. tag is the table's mini joker's second line. cost is Balatro's price; it sells for half. per multiplies the chips or mult (joker_scale): jokers owned, discards left, times this hand type was played, or the joker's own count. grow names how the count changes (grow_jokers). need also takes "small" (3 cards or fewer) and "nodisc" (no discards left), which score_steps adds to contains.
Keep: name, text and cond are at most 7 characters each (the 31px shop joker); tag at most 4 (the 20px mini joker).
Each spec's sprite is 31 plus its row number, set just below the sidebar table; a new joker needs its portrait added to JOKER_ART in gen_cart.py in the same position.

**data.lua:98** `blind_specs=parse_table[[`
The three blinds of every ante, with Balatro's rewards ($3, $4, $5). factor is the blind's goal multiplier in halves (Balatro's 1, 1.5, 2) so it stays whole; blind_goal uses it.

**data.lua:105** `ante_bases=split"3,8,20,50,110,200,350,500"`
Balatro's eight ante base scores, in hundreds, because 50000 is past PICO-8's 32767. A run is won by clearing the boss of the last ante.

**data.lua:107** `sidebar_boxes=parse_table[[`
The sidebar's number boxes as data: name is the global the box shows (read through _ENV, so ante_label and round_number are kept as globals by start_blind), big prints it as a 32-bit score. Each box is 13px tall. A new number in the sidebar is a new row.
Keep: parse_table indexes rows by their name column, so every table needs one first; without it the cart fails before its first frame.

**data.lua:119** `table_buttons=parse_table[[`
The buttons under the hand, in cursor order; update_play acts by name, so a new button is a row here and a branch there.

**data.lua:126** `vfx_specs=parse_table[[`
The VFX engine's particle presets (emit in effects.lua): how many, how fast, how hard they rise, gravity, life in frames, a colour ramp from coldest to hottest ("/"-separated, split into a list just below), and the width they spawn across. spark: a scoring step's, in the step's colour. shower: the hand total's. flame: the boxes' embers. coin: the cash-out's. A new effect is a new row.

**data.lua:137** `boss_specs=parse_table[[`
Nine of Balatro's bosses, one drawn at random when an ante's small blind starts. factor is the goal in halves of the ante base (Balatro's 2x, the wall 4x, the needle 1x). debuff is a suit; hands and discards replace the blind's; must is the fewest cards a hand may have; halve halves the base chips and mult. text is shown on the panel when no cards are picked, at most 25 characters.
