# main.lua

**main.lua:1** `function _init()`
mode is title, play, score, cashout, won or lost. tests/test_boot.lua reads it.

**main.lua:16** `function start_blind()`
Each blind gets a fresh shuffled 52-card deck and full hands and discards; jokers last the whole run.

**main.lua:35** `function draw_up()`
Each card drawn starts on the deck pile, waiting deal_frames longer than the one before, so the hand is dealt one card at a time. The hand is sorted at once; the cards glide to their sorted places as they leave the deck.
Keep: tests/test_boot.lua expects 7 of 8 cards still on the deck one frame into a blind.

**main.lua:63** `function fly_away(cards)`
Discarded cards, and played cards once scored, go into flying, which the table draws sliding off the right edge.

**main.lua:88** `function steer(focus,sizes)`
The one cursor model for every screen, from the user's controls pass: rows of things (sizes gives each row's count), up/down move between rows skipping empty ones, left/right move within a row and wrap at the ends, and each row remembers its own column. A move ticks (snd_move). _init sets btnp to repeat after 16 frames, then every 4 (pokes at 0x5f5c/d, counted in 30fps frames per the manual), so a held arrow runs along the hand.

**main.lua:105** `function button_ready(name,picked)`
Whether a table button would do anything; the button greys out when not.

**main.lua:111** `function update_play()`
The table's rows are jokers (tooltip), hand, buttons (play, discard, sort). O acts on what the cursor is on: picks a card (up to max_picked, with a kick) or presses a button. X is play from any row. While cards are picked, hand_label/hand_level/chips/mult preview the base hand like Balatro.
Keep: tests/test_boot.lua drives the rows, the wrap and every button.

**main.lua:142** `function update_score()`
Plays out steps one every step_frames, after a 30-frame pause; then one step of 45 frames adds chips*mult to score; then finish_hand. Each step pops its number, emits sparks, kicks its card or joker (a joker that fired on a card kicks that card too), swells its box and plays a tick one note higher than the last (sfx snd_chips+k or snd_mult+k, k up to 7). The total pops big mid-table, showers from both boxes, shakes the screen by 2 plus 4 per goal it is worth (at most 8), holds the game for 4 plus 4 frames per goal (at most 12), and flashes if the blind is beaten.
Keep: tests/test_boot.lua checks the card kick, the joker shake and the hitstop on the scripted pair of kings.

**main.lua:176** `function finish_hand()`
A blind is won the moment score reaches goal, checked after each hand; losing is running out of hands below it.

**main.lua:189** `function cash_out()`
Balatro's payout: the blind's reward, $1 per hand left, and $1 interest per $5 held before the payout, at most $5. earnings is the list the banner draws. Coins fly from the sidebar's money box.

**main.lua:202** `function play_music(pattern)`
Starts a pattern only when it changes, fading in over 500ms (manual: FADE_LEN is in ms), on channels 0-2 (mask 7) so sound effects keep the fourth. _update60 asks every frame: music_calm (bass and pad) on the title and in the shop, music_table (with the lead) everywhere else.
Keep: tests/test_boot.lua replaces music() and checks the pattern on the title, the table and the shop.

**main.lua:211** `function _update60()`
shown_score counts up an eighth of the gap a frame (at least 1) so a big hand rolls up.
