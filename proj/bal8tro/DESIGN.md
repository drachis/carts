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
| SFX 0..3 | chips tick, mult tick, pick card, hand total |
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
- Reaching the goal clears the blind; clearing ante 8's boss wins. Running out
  of hands loses. O restarts.
- Clearing a blind cashes out: the blind's $3/$4/$5, $1 per hand left, and
  $1 interest per $5 held, at most $5.
- Then the shop (after every blind, bosses included): two jokers for sale, sell an owned joker for half its
  price, reroll for $5 (+$1 each reroll), or go on to the next blind.
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

- Nobody has played this build. The sounds have never been heard.
- No planet or tarot cards, booster packs, vouchers, hand levels, boss
  blind effects, skipping blinds, joker rarities.
- Without hand levels the late antes are probably out of reach: by
  arithmetic, a flush with the four best jokers here scores a few
  thousand, and ante 5's boss wants 22000 in four hands. Not measured
  with a bot.
- No deck view, no run info screen, no joker reorder.
