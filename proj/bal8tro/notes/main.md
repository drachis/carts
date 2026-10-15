# main.lua

**main.lua:1** `function _init()`
mode is title, play, score, cashout, won or lost. tests/test_boot.lua reads it.

**main.lua:14** `function start_blind()`
Each blind gets a fresh shuffled 52-card deck and full hands and discards; jokers last the whole run.

**main.lua:28** `function draw_up()`
Each card drawn starts on the deck pile, waiting deal_frames longer than the one before, so the hand is dealt one card at a time. The hand is sorted at once; the cards glide to their sorted places as they leave the deck.
Keep: tests/test_boot.lua expects 7 of 8 cards still on the deck one frame into a blind.

**main.lua:56** `function fly_away(cards)`
Discarded cards, and played cards once scored, go into flying, which the table draws sliding off the right edge.

**main.lua:77** `function update_play()`
Controls: left/right cursor, O pick (up to max_picked), X play, down discard, up toggle sort. While cards are picked, hand_label/chips/mult preview the base hand like Balatro.

**main.lua:102** `function update_score()`
Plays out steps one every step_frames, after a 30-frame pause; then one step of 45 frames adds chips*mult to score; then finish_hand. Each step pops its number, bursts sparks, swells its box and plays a tick one note higher than the last (sfx snd_chips+k or snd_mult+k, k up to 7). The total pops big mid-table and shakes the screen by 2 plus 4 per goal it is worth, at most 8.

**main.lua:132** `function finish_hand()`
A blind is won the moment score reaches goal, checked after each hand; losing is running out of hands below it.

**main.lua:145** `function cash_out()`
Balatro's payout: the blind's reward, $1 per hand left, and $1 interest per $5 held before the payout, at most $5. earnings is the list the banner draws.

**main.lua:161** `function _update60()`
shown_score counts up an eighth of the gap a frame (at least 1) so a big hand rolls up.
