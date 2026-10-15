# scoring.lua

**scoring.lua:1** `function deal_jokers(count)`
Deals distinct jokers from joker_specs; each is an empty table whose metatable is its spec row, so a joker can later carry its own state.

**scoring.lua:16** `function score_steps(played,jokers)`
The order of steps is Balatro's: each scoring card left to right, with the card-triggered jokers right after the card that set them off, then every hand joker left to right. A step names its thing (and under, the card a joker fired on) so the drawing can lift both.
Keep: xmult is applied after that step's +mult (apply_step), so a joker's own +mult is multiplied.

**scoring.lua:39** `function hand_total(chips,mult)`
Scores are 32-bit integers: a value n is stored as n>>16, so they reach about 2 billion instead of 32767. chips and mult stay plain numbers below 32767.
Keep: big_text prints with tostr(n,2) (manual: "write VAL as a signed 32-bit integer by shifting it left by 16 bits"). Compare and add scores only with other >>16 values.
