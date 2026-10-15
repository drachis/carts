# main.lua

**main.lua:1** `function _init()`
The cart starts in the intro (intro.lua), or on the title when a test cart has set skip_intro. mode is intro, title, play, score, cashout, shop, pack, info, won or lost. tests/test_boot.lua reads it. deck_choice is the title's deck (left/right wrap through deck_specs; the arithmetic adds the count before % because % on negatives is not in the manual); the title sets deck_spec with it, whose hands, discards and money start_run and start_blind add. title_cards is the title's hand, 8 A J A T 9 Q (it reads BAL8TRO, as the user asked), dealt face down from the deck pile one every deal_frames after 30 frames, turning over as each lands.
Keep: tests/test_boot.lua presses start at frame 120, after the deal.

**main.lua:17** `function open_select()`
Balatro's blind select, before every blind (the run's first included): picks the ante's boss when its small blind comes up, so the boss shows ahead; sets the goal and the sidebar's numbers; then the select screen (draw_select) slides up. skip_select (a test-only global the replay carts set) starts the blind directly.

**main.lua:25** `function update_select()`
Rows: the jokers (tooltip) and the select button. O on select slides the screen away (leaving) and starts the blind select_wait frames later. No skip: Balatro's skip rewards tags, which bal8tro does not have.

**main.lua:35** `function start_blind()`
Starts play itself (mode play first, so boss_on applies the boss's hands and discards: it was missing them when started from the shop). Each blind shuffles the run's own deck (run_deck, made in start_run and kept all run, as Balatro's is, so a card changed by a tarot or added by a pack stays) and gives full hands and discards; jokers last the whole run too.

**main.lua:46** `function draw_up()`
Each card drawn starts on the deck pile, waiting deal_frames longer than the one before, so the hand is dealt one card at a time. The hand is sorted at once; the cards glide to their sorted places as they leave the deck.
Keep: tests/test_boot.lua expects 7 of 8 cards still on the deck one frame into a blind.

**main.lua:74** `function fly_away(cards)`
Discarded cards, and played cards once scored, go into flying, which the table draws flying up and off the right edge, each held play_stagger frames after the one before (Balatro's discards leave about 9 frames apart).

**main.lua:106** `function steer(focus,sizes)`
The one cursor model for every screen, from the user's controls pass: rows of things (sizes gives each row's count), up/down move between rows skipping empty ones, left/right move within a row and wrap at the ends, and each row remembers its own column. A move ticks (snd_move). _init sets btnp to repeat after 16 frames, then every 4 (pokes at 0x5f5c/d, counted in 30fps frames per the manual), so a held arrow runs along the hand.

**main.lua:123** `function button_ready(name,picked)`
Whether a table button would do anything; the button greys out when not.

**main.lua:138** `function update_play()`
The table's rows are jokers (tooltip), hand, buttons (play, discard, sort). O acts on what the cursor is on: picks a card (up to max_picked, with a kick) or presses a button. X is play from any row. While cards are picked, hand_label/hand_level/chips/mult preview the base hand like Balatro.
Keep: tests/test_boot.lua drives the rows, the wrap and every button.

**main.lua:164** `function update_score()`
Plays out the steps at Balatro's measured pace (see data.md's tuning note): the wait after a step is set by what comes next (a card, a joker, or the total). At the total the boxes clear and, score_wait frames later (after()), the hand is added to score and shown_score counts up evenly by roll a frame; then finish_hand. Each step pops its number, emits sparks, kicks its card or joker (a joker that fired on a card kicks that card too), swells its box and plays a tick one note higher than the last (sfx snd_chips+k or snd_mult+k, k up to 7). The total pops big mid-table, showers from both boxes, shakes the screen by 2 plus 4 per goal it is worth (at most 8), holds the game for 4 plus 4 frames per goal (at most 12), and flashes if the blind is beaten.
Keep: tests/test_boot.lua checks the card kick, the joker shake and the hitstop on the scripted pair of kings.

**main.lua:204** `function finish_hand()`
Starts a new banner panel 110px below the screen each hand (banner, a thing glide moves), so the cash-out banner slides up as Balatro's does; end_run restarts it 67px down. A blind is won the moment score reaches goal, checked after each hand; losing is running out of hands below it. A played glass card shatters one time in four: it leaves run_deck for good.

**main.lua:236** `function cash_out()`
Balatro's payout: the blind's reward, $1 per hand left, and $1 interest per $5 held before the payout, at most $5. earnings is the list the banner draws. Coins fly from the sidebar's money box. Gold cards still in hand pay $3 each on a fourth line.

**main.lua:256** `function play_music(pattern)`
Starts a pattern only when it changes, fading in over 500ms (manual: FADE_LEN is in ms), on channels 0-2 (mask 7) so sound effects keep the fourth. _update60 asks every frame: music_calm (bass and pad) on the title and in the shop, music_table (with the lead) everywhere else.
Keep: tests/test_boot.lua replaces music() and checks the pattern on the title, the table and the shop.

**main.lua:295** `function _update60()`
Each mode has its own update, found by name: update_ plus the mode (update_won is update_lost). A new mode needs one, or _update60 errors. shown_score counts up an eighth of the gap a frame (at least 1) so a big hand rolls up.

**main.lua:224** `function end_run(result)`
The game over (lost) or win (won) screen, as Balatro's: the run's stats as rows for draw_banner (best hand, most played hand with its count, cards played and discarded, ante, round, and the blind lost to), a quip for Jimbo picked from end_specs with _ for a line break, and the banner restarted 67px down (Balatro's overlay rises about 3.2 card heights, 67px here, in 8 frames, overshoots 0.13 of a card and settles by 19; ours rises in 12 at glide_cap, overshoots 0.14, settles by 19). best_hand, cards_played and cards_discarded are counted in update_score, play_hand and discard_hand from start_run.
Keep: tests/motion.lua forces the loss and win at the reference harness's times and logs the panel as ui overlay.
