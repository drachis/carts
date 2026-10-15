# main.lua

**main.lua:1** `function _init()`
mode is title, play, score, cleared, won or lost. tests/test_boot.lua reads it.

**main.lua:12** `function start_blind()`
Each blind gets a fresh shuffled 52-card deck and full hands and discards; jokers last the whole run.

**main.lua:65** `function update_play()`
Controls: left/right cursor, O pick (up to max_picked), X play, down discard, up toggle sort. While cards are picked, hand_label/chips/mult preview the base hand like Balatro.

**main.lua:90** `function update_score()`
Plays out steps one every step_frames, after a 30-frame pause; then one step of 45 frames adds chips*mult to score; then finish_hand.

**main.lua:118** `function finish_hand()`
A blind is won the moment score reaches goal, checked after each hand; losing is running out of hands below it.

**main.lua:134** `function _update60()`
shown_score counts up an eighth of the gap a frame (at least 1) so a big hand rolls up.
