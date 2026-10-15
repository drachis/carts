# bal8tro

A faithful demake of Balatro in PICO-8. You are dealt eight cards and play up
to five as a poker hand; the hand scores chips × mult, built up card by card
and joker by joker so the numbers visibly climb. Beat each blind's goal
before your hands run out. Jokers bend the scoring, and the run snowballs
from a few good ones. The fun is Balatro's; the challenge is fitting it in
the cart.

## Rules of the build

1. Tuning and content are data strings parsed at boot (`data.lua`): a new
   joker or blind is a line of data, and a joker's behaviour is its `when`,
   `need` and effect columns, not code.
2. Scores are 32-bit integers stored as `n>>16` and printed with
   `tostr(n,2)`, so they can pass 32767 (PICO-8's number limit).
3. No comments in the Lua; notes are in `notes/<module>.md` (see
   `CODE_NOTES.md`).
4. PICO-8 is the only token counter (`py count_tokens.py bal8tro.p8`).

## Memory map

| Where | Holds |
|---|---|
| Sprites 1..4 | big suits (spade, heart, club, diamond) |
| Sprites 17..20 | small suits |
| SFX 0..1 | unused (the first chips and mult ticks) |
| SFX 2..4 | pick card, hand total, card dealt |
| SFX 5..12, 13..20 | chips and mult ticks, rising a major scale per scoring step |
| SFX 21..26 | the tune: bass, pad and lead, two halves each (gen_cart.py) |
| Music 0..1, 2..3 | calm loop (bass, pad: title, shop), table loop (with lead) |
| `cartdata` | unused |

## The game

- Title screen, then a run: Balatro's eight antes of three blinds each
  (small, big, boss at 1, 1.5 and 2 times the ante's base of 300, 800,
  2000, 5000, 11000, 20000, 35000, 50000). Clearing ante 8's boss
  (100000) wins. Goals are 32-bit like scores.
- A run starts with $4 and no jokers, as in Balatro. There are four joker
  slots (Balatro has five; four is what fits across the screen) and
  fourteen jokers, each with Balatro's price.
- Each blind: a fresh shuffled deck, 8-card hand, 4 hands, 3 discards.
- Left/right moves the cursor, O picks a card (up to five), X plays,
  down discards, up sorts by rank or suit. Picking shows the hand's name
  and base chips × mult.
- A played hand scores like Balatro: base chips and mult for the hand
  type, then each scoring card adds its chips, card jokers fire on their
  cards, then hand jokers fire left to right. Each step pops its number
  over its card or joker; the total rolls into the score.
- Juice (Balatro's feel is half the game): cards and jokers glide
  rather than jump; the hand sits in an arc and bobs; cards are dealt
  one by one face down off a deck pile and flip as they fly in;
  discarded and played cards fly off the right edge. Each scoring step
  throws sparks, swells its box and ticks a note higher than the last;
  the total pops up big, showers sparks and shakes the screen. While the
  hand on screen would clear the blind, the chips and mult boxes burn.
  The felt, title and shop have slowly waving dithered stripes.
- Every ante's boss blind is one of nine Balatro bosses, drawn when
  the ante starts and named in the shop beforehand: the club, goad, head
  and window debuff a suit (greyed, struck through, still count towards
  the hand's type, score nothing); the wall is 4x the base; the needle
  is 1x with one hand; the water has no discards; the psychic needs five
  cards; the flint halves base chips and mult.
- Reaching the goal clears the blind; clearing ante 8's boss wins. Running out
  of hands loses. O restarts.
- Clearing a blind cashes out: the blind's $3/$4/$5, $1 per hand left, and
  $1 interest per $5 held, at most $5.
- Planets level up a hand type, with Balatro's nine planets and what each
  level adds; the panel shows the hand's level ("pair lv2"). A planet
  costs $3, needs no slot and is used as soon as it is bought (Balatro
  keeps it in a consumable slot first).
- Then the shop (after every blind, bosses included): two items, each a
  planet one time in three, otherwise a joker (no duplicates of owned
  jokers) for sale; sell an owned joker for half its price, reroll for $5 (+$1 each reroll), or go on to the next blind.
  Up/down pick the row (owned, for sale, buttons), left/right the item, O
  acts; the bottom line says what O will do or why it cannot.

## Tests

    py run_tests.py --no-comments
    py count_tokens.py bal8tro.p8

- `test_boot`: the real cart from the title through a scripted pair of
  kings (checks 480 with joker and sly), the cash-out ($10), the shop
  (a buy, a refused buy with the slots full, a sale, a reroll, next
  blind), a discard, a lost blind, ante 1's boss paying $5 and leading
  through the shop to ante 2 (goal 800), and a won run at ante 8,
  dumping each screen. Endings are reached by setting the ante, hands
  and score, not by play.
- `test_hands`: every hand type and how many cards it scores, wheel and
  wrap-around straights, royal flush label, six joker combinations,
  scores past 32767, both sorts, the shop never offering an owned
  joker, sell prices, blind goals from 300 to 100000.

## Not built yet, or not checked

- The user has played up to the juice build ("feels more like
  balatro"). Music and boss blinds have not been played or heard.
- No tarot cards, booster packs, vouchers, consumable slots, skipping
  blinds, joker rarities; only nine of Balatro's bosses.
- The late antes may be out of reach: before planets, by
  arithmetic, a flush with the four best jokers here scores a few
  thousand, and ante 5's boss wants 22000 in four hands. Not measured
  with a bot.
- No deck view, no run info screen, no joker reorder.
