# bal8tro

A faithful demake of Balatro in PICO-8. You are dealt eight cards and play up
to five as a poker hand; the hand scores chips × mult, built up card by card
and joker by joker so the numbers visibly climb. Beat each blind's goal
before your hands run out. Jokers bend the scoring, and the run snowballs
from a few good ones. The fun is Balatro's, and so is the feel (the juice,
the layout); the challenge is fitting it in one cart.

## Rules of the build

1. Tuning and content are data strings parsed at boot (`data.lua`): a new
   joker, boss, pack, tarot, particle effect or sidebar box is a line of
   data, and behaviour is named by columns (`when`, `need`, `per`, `act`),
   not code. Every table has a `name` first column.
2. Scores and goals are 32-bit integers stored as `n>>16` and printed with
   `tostr(n,2)`, so they can pass 32767 (PICO-8's number limit).
3. No comments in the Lua; notes are in `notes/<module>.md` (see
   `CODE_NOTES.md`).
4. PICO-8 is the only token counter: `py count_tokens.py bal8tro.p8`, and
   `py function_tokens.py bal8tro.p8 40` per function.
5. The game is one cart. Test carts may split, and the rules-only ones
   leave out `draw.lua`.
6. Rules, values and layout come from Balatro (the user's own copy:
   `balatro_ref/`); the art and code are bal8tro's own.

## Memory map

| Where | Holds |
|---|---|
| Sprites 1..4 | big suits (spade, heart, club, diamond) |
| Sprites 17..20 | small suits |
| Sprites 32..52 | joker portraits, 8x8, in joker_specs order (gen_cart.py JOKER_ART) |
| SFX 0..1 | unused (the first chips and mult ticks) |
| SFX 2..4 | pick card, hand total, card dealt |
| SFX 5..12, 13..20 | chips and mult ticks, rising a major scale per scoring step |
| SFX 21..26 | the tune: bass, pad and lead, two halves each (gen_cart.py) |
| SFX 27 | cursor move |
| Music 0..1, 2..3 | calm loop (bass, pad: title, shop, packs), table loop (with lead) |
| `cartdata` | unused |

## The game

- **A run:** title, then Balatro's eight antes of three blinds each
  (small, big, boss at 1, 1.5 and 2 times the ante's base of 300, 800,
  2000, 5000, 11000, 20000, 35000, 50000). Clearing ante 8's boss
  (100000) wins; running out of hands loses; O restarts.
- **The deck** lasts the whole run (`run_deck`): each blind shuffles the
  same cards, so tarots and standard packs change it for good. Each blind
  deals 8 cards, 4 hands, 3 discards.
- **Bosses:** each ante's boss is one of nine Balatro bosses, named in the
  shop beforehand: the club, goad, head and window debuff a suit (greyed,
  struck through, still count towards the hand's type, score nothing);
  the wall is 4x the base; the needle is 1x with one hand; the water has
  no discards; the psychic needs five cards; the flint halves the base.
- **Scoring** is Balatro's: the hand's base (with its planet level), then
  each scoring card's chips and its enhancement, card jokers on their
  cards, steel cards held in hand, then hand jokers left to right.
- **Jokers:** a run starts with $4 and none. Four slots (Balatro has five;
  four fit across the screen); twenty-one jokers at Balatro's prices: flat,
  per-suit, per-face, hand-type bonuses and x2s, and the growing and
  situational ones (abstract, banner, mystic summit, half, supernova,
  green joker, ride the bus). Each has an 8x8 portrait and shows its
  current worth.
- **Enhancements** (Balatro's values): bonus +30 chips, mult +4 mult, wild
  any suit, glass x2 mult (1 in 4 shatters), steel x1.5 held, gold $3
  held at round end, lucky 1 in 5 +20 mult. Stone is left out.
- **Cash out** after each blind: the blind's $3/$4/$5, $1 per hand left,
  $1 interest per $5 held (at most $5), $3 per gold card held.
- **The shop** (after every blind), laid out like Balatro's: the sidebar
  (its strip reading "the shop") and the joker row stay; a red-edged
  panel holds next blind and reroll ($5, +$1 a reroll), two cards for
  sale with price tags (a planet one time in three, otherwise a joker
  never owned), and two booster packs. Up to the joker row to sell for
  half; a tooltip names whatever the cursor is on. Planets level a hand
  and are used as soon as bought (Balatro keeps them in a slot first).
- **Packs**, $4, Balatro's normal sizes, choose 1 or skip; the felt turns
  the pack's colour. Arcana: 3 tarots, and a hand dealt from the deck to
  pick their targets in. Celestial: 3 planets. Buffoon: 2 jokers.
  Standard: 3 playing cards that join the deck.
- **Tarots:** magician, empress, hierophant, lovers, chariot, justice,
  devil enhance cards; star, moon, sun, world change up to 3 suits;
  strength raises 2 ranks; the hanged man destroys 2; the hermit doubles
  money up to $20. No tarots in the shop's card slots (Balatro keeps them
  in consumable slots, which bal8tro does not have).
- **Layout** like Balatro's: a sidebar on the left (blind strip, goal,
  round score, hand and level, chips × mult, hands, discards, money,
  ante, round, deck), jokers across the top, played cards in the middle,
  an overlapping hand with play, discard and sort buttons, deck bottom
  right.
- **Controls**, one model on every screen (`steer`): up/down between rows,
  left/right along a row and wrap, O acts on what the cursor is on, X
  plays from anywhere; held arrows repeat quickly; moves tick.
- **Juice** on a small VFX engine (`effects.lua`: particle presets as
  data, kick, turn_over, timers, hitstop, flash): cards glide, sit in an
  arc and bob; dealt one by one, face down, turning over in flight;
  discards fly off; each scoring step pops, sparks, kicks its card or
  joker, swells its box and ticks a note higher; the total pops big,
  showers, shakes, holds the game for a beat and flashes on a win. While
  the hand on screen is worth the goal the boxes burn (Balatro's rule);
  at 2x the sidebar's foot and edge burn, at 3x the bottom of the screen,
  at 4x embers rise across the table. The felt waves.
- **Music:** an original slow lounge loop in A minor, calm without its
  lead on the title, shop and packs.

## Tests

    py run_tests.py --no-comments
    py count_tokens.py bal8tro.p8

- `test_boot` (the real, whole cart): the title, a scripted pair of
  kings (480 with joker and sly), motion, dealing, kicks, flames and the
  hitstop, the cash-out, the shop (buys, a refusal, a sale, a reroll),
  the joker row and buttons, a discard, a lost blind, a boss leading
  through the shop and an opened arcana pack to ante 2, a won run at ante
  8, and a hand five times the goal setting the floor alight; dumps each
  screen. Endings are reached by setting the ante, hands and score, not
  by play.
- `test_hands` (rules, no drawing): every hand type and how many cards it
  scores, joker combinations, growing jokers, bosses, levels, 32-bit
  totals, sorts, blind goals.
- `test_shop` (rules, no drawing): enhancements, every kind of tarot,
  the three other packs, the run deck, the VFX engine, shop offers and
  sell prices.
- `balatro_ref/run_balatro_ref.py`: screenshots of the user's own Balatro
  for reference (not a test).

## Not built yet, or not checked

- The user played up to the juice build. Music, bosses, the new layout,
  controls, shop, packs and tarots have not been played or heard.
- No vouchers, tags, skipping blinds, consumable slots, editions, seals,
  joker rarities, stone cards, spectral packs; nine of Balatro's bosses.
- No deck choice, deck view or run-info screen yet.
- Whether the late antes are reachable is not measured with a bot.
