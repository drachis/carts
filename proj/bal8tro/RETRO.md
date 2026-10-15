# bal8tro retros

# First retro: a faithful Balatro demake in one cart

From an empty folder on 2026-10-14 22:42 to a full cart on 2026-10-15
14:44: 68 commits on branch `bal8tro`, 2132 tokens at the first playable,
8192 of 8192 at the end. The game is Balatro's rules, rhythm and screens in
PICO-8: eight antes, nine bosses, 21 jokers, planets, packs, tarots,
enhancements, five decks, the shop, blind select, cash-out, game over and
win with Jimbo, and Balatro's splash. The user's verdict: "This looks and
feels like Balatro in demake form."

## What was built

| Stretch | Commits | Tokens | What |
|---|---|---|---|
| Rules | 840df8f..ed854e1 | 2132 → 4205 | hands, scoring, money, shop, eight antes, planets, bosses, music |
| Juice | 712fe7a..c922f21, 09994c0..c399978 | → 5075 | glide, deal and discard, score pops, flames, swirl, the VFX engine (particles as data, kick, timers, hitstop) |
| Balatro's layout | f6ef185..2ab4e6b, 4543e6d | → 5551 | a mock-up approved first, then the sidebar, joker row, shop panel |
| Content | 061b303..92f2a0c | → 7246 | jokers to 21 with sprites, packs, tarots, enhancements, decks, the info overlay, the controls pass |
| Measured against Balatro | 9946461, c6624d0..b609b19 | → 7964 | the reference harness, motion logs, rhythm, transitions, blind select |
| Compaction 1 | bd99a78..039fce4 | 7964 → 7612 | golden-checked, PICO-8 idioms (P8SCII, sspr, _ENV dispatch, data columns) |
| Ending and title | 520b7c7, 9de9115 | → 7959 | game over and win, Jimbo, the BAL8TRO hand |
| Compaction 2 | 1aa7792..622daf4 | 7951 → 7820 | test carts made lite, shop_offer, small inlines |
| Splash | 59aec39..0add9c0 | → 8192 | Balatro's intro, spiral, timing tuned to feel |

Tooling the project grew, all in the repository:

- `balatro_ref/`: builds a copy of the user's Balatro (own save folder,
  Steam check kept), injects `harness.lua` that plays a fixed script and
  logs every card, panel and HUD value each frame in card units, plus
  screenshots; `BAL8TRO_INTRO=1` captures the splash alone.
  `motion_metrics.py`, `compare_motion.py`, `transition_metrics.py`,
  `intro_spiral.py` turn the logs into numbers.
- `tests/motion.p8`: bal8tro played through the harness's sequence at the
  same moments, logging in the same format.
- `tests/golden.p8` + `golden_compare.py`: a 2700-frame deterministic run
  with a screen checksum per frame.
- `function_tokens.py`: tokens per function, from PICO-8's own count.
- `tests/make_lite.py`: per-cart copies of draw, shop and intro with
  unreached functions emptied; 12 test carts plus motion and golden.

## What went well

- **The reference was run, not remembered.** The user asked: "any reason
  not to launch Balatro from the executable with similar test harness
  work?" The harness made every later match a measurement: scoring steps
  109/156/215/274/372 frames against Balatro's 110/157/225/284/382; cash-out
  rise 619-639 against 609-640; shop 220-239 against 220-241; pack slide 20
  against 22; skip return 41-62 against 41-62; blind select 34 against 36;
  game over 126 frames after the total against 126, overshoot 0.14 against
  0.13 card heights, settle 19 against 19; splash cards on screen 2, 9, 34,
  78 at 4, 6, 8, 12 seconds, as logged.
- **Balatro's source gave formulas, the log checked them.** The juice
  pulse (sin 50.8t, cubic fade), the splash spawn schedule
  (max(1/i, 0.2(170-i)/500, 0.016)), the vortex shader's twist. Each formula
  was then compared with what the log showed, which caught two wrong
  readings (below).
- **Data, not plots, for many objects.** The user: "the data can be logged
  out to a data file rather than the image plot for the complex multi layer
  data". Tables of onsets, travel frames and overshoot found the
  played-card gap (20 frames against 70-77) and the hand bob (1.6px against
  under 0.2px) at once.
- **The golden run made compaction safe.** It was broken on purpose once
  (one colour in the shop panel: 229 frames differ) before being trusted.
  Seventeen compaction commits were then each shown identical, or different
  only where intended, with the differing frames grouped by mode ("2 differ
  in modes ['title']", "327 differ, all lost").
- **A mock-up before the layout rebuild.** tests/mock_layout.p8 was
  approved, then the table was rebuilt once.
- **Measure, then cut.** `function_tokens.py` aimed every sweep; the
  biggest wins were never the ones guessed.
- **Lite test carts.** Emptying unreached screens per cart gave test_boot
  1004 free tokens where it had 17, so the game could grow to 8192.

## What went badly

- **A gap reported instead of fixed.** I reported "played cards settle in
  about 20 frames against Balatro's 70-77" as a remaining gap. The user:
  "why did you leave this when it wasn't what I asked for? fix that up."
  Fixed in 7fe7c4c by making every card a damped spring. The request was to
  match; a known mismatch was unfinished work, not a caveat.
- **A symptom patched, then the cause fixed.** Garbled text appeared top
  left at cash-out. Cause: print_centre measured text by printing it at
  y -99, and the banner's 110px camera slide brought that print on screen.
  My first fix moved it to -999 (ccc7899). The user: "what the hell is
  this... in pico 8 drawing directly to the screen with fixed width pixel
  characters is already a calculatable width". Fixed properly in b609b19:
  4px a character, 8px a glyph. The off-screen print was a big-engine habit
  carried into PICO-8.
- **Non-PICO-8 techniques throughout.** The user asked "how many other
  non pico8 techniques are in use?" The audit found shapes drawn as
  rectfill-and-rect pairs, cards built from rectangles, several prints
  where one P8SCII string would do, if-chains over modes, and layout
  numbers in code. Replacing them was most of compaction 1.
- **Heredoc backslashes, again.** The rule is in memory and in two skills.
  It still broke four times this session. The scripts held `\\n`, `\\2`,
  `\\60` and `\\6`, meant as Lua's `\n`, `\2`, `\60` and `\6`: the first
  became a real newline in main.lua, the second byte 0x02 in draw.lua, the
  third the digit 0, and the last search text never matched. Each time the
  content had been written as an inline `py - <<'EOF'` script; each time a
  script file written with the Write tool, or the Edit tool, worked first
  time. It happened a fifth time while writing this retro's memory update
  about it, through a heredoc, and was caught by reading the file back.
- **Guessed units, twice, in the splash.** The cards were first drawn
  2-4 card widths wide and full size until 80% of their path, from a
  reading of the source; the log showed 2-2.8 at the ring shrinking
  steadily, and the first frames were wall-to-wall card. The spiral's
  falloff was first set at 19 card widths; Balatro's shader works out to
  about 10. Both were fixed from the log or the shader maths, after the
  first picture showed them wrong.
- **What the log does not show.** The splash cards' logged paths are
  straight; Balatro's vortex shader bends them only when drawn. My first
  comparison of turn per card read 0 degrees for Balatro, because it
  measured the log. The fix was to apply the shader's maths to the logged
  paths (`intro_spiral.py`).
- **The harness ran the splash late.** The splash began 2.2s after the
  harness loaded and the run's `start_run` at 10s cut it; the card logger's
  visible filter logged no splash cards. A second run in an intro-only mode
  fixed both.
- **Test carts were the binding budget.** The game had 241 free tokens
  when test_boot, the whole game plus a tiny script, had 17. Every test cart
  was split or halved three times (4 replay carts, then 8, then 12, then
  lite copies). The lasting fix came late: test_boot empties the screens
  its boot never reaches and keeps the real code on the boot path.
- **Smaller incidents.** A global named `flip` replaced PICO-8's flip()
  and froze the cart. parse_table needs a `name` column. PICO-8's inverted
  sin made the juice shrink first. A boss's hands and discards did not
  apply when its blind began from the shop (start_blind set the mode after
  checking it; a test was added). panel_at in draw.lua broke the rules
  carts, which have no draw.lua. The title hand was off centre because the
  layout's centre is a card's left edge. A "lookup" rewrite of the info
  grid cost 7 tokens instead of saving any and was reverted.
- **Balatro's timing was not always right for the demake.** The splash
  held white as long as Balatro's does; the user: "The white flash feels
  like a freeze with how long it lasts". Balatro's white has a shader
  moving under it; ours had nothing moving. Shortened from about 200 frames
  of white to under 60, and the title's deal moved after the white so it is
  seen.

## Measured results

Compaction, each golden-checked:

| Change | Tokens | Kind |
|---|---|---|
| box() for twelve filled-and-bordered shapes, outline() for three | -125 | shared helper |
| shop_offer(): message and press from one (cost, words, action) | -56 | merge describe and do |
| test_boot without dump_screen | -81 (test cart) | include split |
| _update60 and _draw dispatch by name through _ENV | -58 | names as data |
| shop buys through take_choice | -33 | reuse |
| turn_over, flash inlined; jiggle one return; pull() for the spring | -34 | trim |
| card face as an sspr sprite | -26 | engine idiom |
| tooltip as one P8SCII string | -25 | engine idiom |
| joker_scale lookup, blind_name(which,field), pop() for the total | -33 | data, reuse |
| blind colours as a data column, print_words | -21 | data |
| table button names are the functions they call | -12 | names as data |
| panel slide helpers | -34 | shared helper |
| tarot sets a named field | -9 | data |
| draw_item, merged shop rows | -13 | reuse |
| info grid indexed once | +7, reverted | guess that failed |

Additions: game over, win and Jimbo +347; the splash +365 at first (153
over the cart), about +370 once written; the spiral +22.

Estimates against measurements: a card-face sprite was expected to save
about 30 and saved 26; draw_item was expected to save about 15 and saved
5; the shop merge was expected to save about 50 and saved 56.

## What did not pay, or was rejected

- An indexed deck grid in the info overlay: cost tokens.
- The card back as a sprite: its fillp pattern is aligned to the screen,
  a sprite's to itself, so pixels would move.
- Measuring text with an off-screen print (above).
- Exact reference timing where the demake has less on screen (the splash
  white).
- Plots for many-object motion: unreadable at eight cards (the user).

## What is still not known

- Sound: no one has heard the music, the scoring ticks, Jimbo's ticks or
  the intro.
- CPU at the peaks: stat(1) was measured once early (17% with stripes and
  flames) and never at the inferno, a full shop, or 200 intro cards. Every
  timing match assumes PICO-8 holds 60fps; the user asked whether frames
  take the same wall-clock time as Balatro's, and the answer depends on it.
- The splash in motion: judged from single frames and numbers, not watched
  by me; the user watched it and asked for the timing change.
- A whole run by a person to ante 8: the user plays a copy, but no report.
- The web export: not built.

## Lessons

1. When the work is to match a reference, run the reference with a
   harness and log both games in the same format and units; compare
   numbers, not impressions.
2. Read the reference's source for formulas, then check each against its
   log or its screen: the source says what is computed, not what is drawn.
3. A log records state, not what a shader draws. When the reference bends
   things in a shader, apply the shader's maths before comparing.
4. Fit the reference's timing to what the demake shows: a beat that holds
   still works when something moves underneath it.
5. A known mismatch with what was asked is unfinished work: fix it in the
   same turn or ask; do not report it as a caveat.
6. Fix the cause a user saw, not the number that hid it.
7. Use the engine's own idioms; a technique from a bigger engine (an
   off-screen measuring draw) can be a bug in a small one.
8. When a screen shows the same kind of thing as the game, draw it with
   the game's code: the title's hand got the deal and fan for free.
9. Merge a function that describes an action with the one that performs
   it: one function returning (cost, words, action).
10. Dispatch by name (modes, buttons) and put the differences in data.
11. Test carts that include the whole game are the real budget; give each
    a copy with the code it never reaches emptied, and keep the boot test
    real along the boot path only.
12. Group a golden run's differing frames by a recorded state field to
    show a difference is confined to where it was intended.
13. A scripted edit carrying a backslash goes in a file written with the
    Write tool, never an inline heredoc (recurred four times, and a fifth
    during this retro): the habit outlives the rule, so the check is to
    read back every line with a backslash after any scripted write.

## Sorting the lessons

- **To skills.** game-playtest-loop: 5, 6, 8. motion-log-plot (matching a
  reference game): 1, 2, 3, 4. golden-refactor: 12, and stashing feature
  work to compact against the old baseline. pico8-game: 7 (PICO-8 idioms
  into pico8-facts), 9, 10 and 11 (token-economy), 13 (strengthened in
  SKILL.md). project-retro: extracting the user's messages from the
  session transcript.
- **Stays here.** Balatro's values and timings (data.lua and the notes),
  the harness's specifics (BAL8TRO_INTRO, the save folder, the Steam
  check), the Jimbo quips, the BAL8TRO hand, the splash numbers.
- **To memory.** The project's state (full at 8192, the splash, the lite
  test carts); the user's preferences: engine-native techniques; a known
  gap is fixed, not reported; the user's feel overrides exact reference
  timing.
- **Already known, recurred.** Heredoc backslashes (memory
  no-patch-scripts-for-lua and pico8-game SKILL.md): made more concrete.
- **Left out on purpose.** A separate reference-harness skill: offered,
  not built.
