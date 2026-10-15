# data.lua

**data.lua:30** `hand_size=8`
Tuning as globals, set by parse_record into _ENV. The pace is Balatro's at its default game speed, measured with balatro_ref (motion_metrics.py on its motion.log, frames at 60fps from pressing play): score_delay 110 before the first step, step_frames 47 between card steps, joker_frames 59 before a joker, total_gap 98 from the last step to the total (the boxes clear), score_wait 52 then score_roll 30 frames of the score counting up evenly, total_hold 237 until the hand finishes (Balatro's cash-out panel rises 609 frames after play); shop_wait 220 from pressing cash out to the shop rising (Balatro's rises 220 later, after its cards return to the deck); exit_wait 35 from leaving the shop to the next blind; pack_wait 22 for the shop to slide away before a pack opens, pack_hold 111 more before its cards come out (Balatro's appear 133 after opening); shop_return 41 before the shop slides back after a pack; select_wait 108 from pressing select to the first card dealt (Balatro's 107); deal_frames 7 between dealt cards; play_delay 28 frames before played cards leave the hand, then play_stagger 8 between them; lift_wait: scoring cards lift once the wait before the first score is below it (frame 72 after play, as Balatro's); spring and damping make every card and joker move as a damped spring (about 15% overshoot, Balatro's cards overshoot too).
Keep: tests/boot_script.lua pins the older, faster pace for its frame-timed checks; tests/motion.p8 runs this pace and is the one compared with Balatro.

**data.lua:79** `hand_specs=parse_table[[`
Balatro's level-1 values, and each hand's planet with what a level adds (level_chips, level_mult). short is the hand's name on the planet card, at most 7 characters. Order matters: evaluate() takes the last row whose name the hand contains, so rows run weakest to strongest.
Keep: names are the keys of evaluate()'s contains table and of a joker's need.

**data.lua:92** `joker_specs=parse_table[[`
when=card: fires once per scoring card that matches need (a suit number 1..4, or "face"). when=hand: fires once after the cards, if need is empty or the hand contains it. Empty chips/mult/xmult are nil. name, text and cond are the shop joker's three lines and the tooltip's; cond "per" gets the suit sprite after it. tag is the table's mini joker's second line. cost is Balatro's price; it sells for half. per multiplies the chips or mult (joker_scale): jokers owned, discards left, times this hand type was played, or the joker's own count. grow names how the count changes (grow_jokers). need also takes "small" (3 cards or fewer) and "nodisc" (no discards left), which score_steps adds to contains.
Keep: name, text and cond are at most 7 characters each (the 31px shop joker); tag at most 4 (the 20px mini joker).
Each spec's sprite is 31 plus its row number, set just below the sidebar table; a new joker needs its portrait added to JOKER_ART in gen_cart.py in the same position.

**data.lua:117** `blind_specs=parse_table[[`
The three blinds of every ante, with Balatro's rewards ($3, $4, $5). factor is the blind's goal multiplier in halves (Balatro's 1, 1.5, 2) so it stays whole; blind_goal uses it. colour is the sidebar sign and select chip (blue, orange, red).

**data.lua:124** `ante_bases=split"3,8,20,50,110,200,350,500"`
Balatro's eight ante base scores, in hundreds, because 50000 is past PICO-8's 32767. A run is won by clearing the boss of the last ante.

**data.lua:126** `sidebar_boxes=parse_table[[`
The sidebar's number boxes as data: name is the global the box shows (read through _ENV, so ante_label and round_number are kept as globals by start_blind), big prints it as a 32-bit score. Each box is 13px tall. A new number in the sidebar is a new row.
Keep: parse_table indexes rows by their name column, so every table needs one first; without it the cart fails before its first frame.


**data.lua:176** `pack_specs=parse_table[[`
Balatro's four normal packs: kind is what pack_choices holds, choices how many are shown, colour the pack and its screen's felt. A shop's two pack slots are each a random row.

**data.lua:184** `table_buttons=parse_table[[`
The buttons under the hand, in cursor order; update_play acts by name, so a new button is a row here and a branch there. Four buttons 17px wide fit between the hand's left edge and the deck pile (deck_x 113); info opens draw_info.

**data.lua:192** `vfx_specs=parse_table[[`
The VFX engine's particle presets (emit in effects.lua): how many, how fast, how hard they rise, gravity, life in frames, a colour ramp from coldest to hottest ("/"-separated, split into a list just below), and the width they spawn across. spark: a scoring step's, in the step's colour. shower: the hand total's. flame: the boxes' embers. coin: the cash-out's. A new effect is a new row.

**data.lua:203** `boss_specs=parse_table[[`
Nine of Balatro's bosses, one drawn at random when an ante's small blind starts. factor is the goal in halves of the ante base (Balatro's 2x, the wall 4x, the needle 1x). debuff is a suit; hands and discards replace the blind's; must is the fewest cards a hand may have; halve halves the base chips and mult. text is shown on the panel when no cards are picked, at most 25 characters.

**data.lua:138** `enhancement_specs=parse_table[[`
Balatro's enhancements with its values (game.lua m_bonus..m_lucky): chips and mult and xmult added when the card scores, held_xmult while it stays in hand (steel), colour for the card's border and corner letter. gold pays in cash_out and lucky's 1-in-5 is in score_steps, by name. Stone is left out (it needs rankless, suitless cards).

**data.lua:149** `tarot_specs=parse_table[[`
Fourteen of Balatro's tarots. act names what use_tarot does: enhance (to enhancement), suit (to suit), rank (+1, ace to 2), destroy, money (hermit: double, at most +$20). most is how many picked cards it takes (0: none). text and cond are the tooltip's lines.

**data.lua:167** `deck_specs=parse_table[[`
Five of Balatro's starting decks (its source: b_red discards 1, b_blue hands 1, b_yellow dollars 10, b_abandoned remove_faces, b_checkered), chosen on the title. hands, discards and money add to a run's; faces 0 leaves out jacks, queens and kings; suits 2 makes every card a spade or a heart; colour is the card backs'. Black and painted are left out: an extra joker slot or two more cards in hand do not fit across 128 pixels as laid out.
