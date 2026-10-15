# scoring.lua

**scoring.lua:1** `function deal_jokers(count,owned)`
Deals distinct jokers from joker_specs, never one already in owned (Balatro offers no duplicates without Showman); fewer if the pool runs out. Each is an empty table whose metatable is its spec row, so a joker can later carry its own state; getmetatable(joker) is its spec.

**scoring.lua:13** `function reset_levels()`
hand_levels maps a hand's name to its level, all 1 at the start of a run. hand_base is the level's chips and mult, halved (rounded up) under the flint; hand_title is the sidebar's short name and the level. hand_plays counts each hand type played this run, for nova.

**scoring.lua:18** `function joker_scale(joker,spec,owned)`
What a joker's amount is multiplied by, from its per column; 1 for a plain joker. A scale of 0 makes no step (a green joker at 0, banner with no discards). The mini joker shows the scaled amount, so a growing joker's card shows what it is worth now.

**scoring.lua:27** `function grow_jokers(event,scoring)`
Balatro's growing jokers, on "play" (before the hand scores, so the hand counts) and "discard": green +1 a hand and -1 a discard, not below 0; bus +1 a hand with no scoring face card, else back to 0. A change pops over the joker and kicks it.
Keep: tests/test_hands.lua checks every per and grow rule.

**scoring.lua:42** `function boss_on()`
The current boss while the boss blind is being played (mode play or score), else false, so the shop and packs after a boss show nothing debuffed. is_debuffed: a card of the boss's debuffed suit; it still counts towards the hand's type but adds no chips and sets off no card jokers (Balatro's rule). can_play: the psychic wants five cards, every other blind one.
Keep: tests/test_hands.lua checks the club, the flint, the psychic and the wall.

**scoring.lua:71** `function score_steps(played,jokers)`
The order of steps is Balatro's: each scoring card left to right, with the card-triggered jokers right after the card that set them off, then every hand joker left to right. A step names its thing (and under, the card a joker fired on) so the drawing can lift both.
Keep: xmult is applied after that step's +mult (apply_step), so a joker's own +mult is multiplied.

**scoring.lua:98** `function hand_total(chips,mult)`
Scores are 32-bit integers: a value n is stored as n>>16, so they reach about 2 billion instead of 32767. chips and mult stay plain numbers below 32767.
Keep: big_text prints with tostr(n,2) (manual: "write VAL as a signed 32-bit integer by shifting it left by 16 bits"). Compare and add scores only with other >>16 values.

**scoring.lua:102** `function blind_goal(ante,which)`
Turns the base (hundreds) into 32-bit first, then multiplies by 50 and the factor (halves), so 100000 never passes through a plain number. The boss blind uses its boss's factor (the wall 8, the needle 2). next_blind, below it, gives the ante and blind after the current one; an ante past #ante_bases means the run is won. blind_name gives the boss's own name for the boss blind.
Keep: tests/test_hands.lua checks goals from 300 to 100000, and 200000 for the wall at ante 8.
