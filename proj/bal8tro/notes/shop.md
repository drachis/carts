# shop.lua

**shop.lua:1** `function open_shop()`
Opens after every cash-out, the bosses' included; only the last ante's boss ends the run instead. Its foot names the next ante, blind and goal. Two jokers for sale, reroll at $5 rising $1 a reroll, back to $5 next shop. The cursor starts on the first joker for sale.

**shop.lua:8** `function sell_price(joker)`
Balatro's sell value: half the cost, at least $1.

**shop.lua:16** `function move_shop_row(step)`
Rows are 1 owned jokers (sell), 2 jokers for sale (buy), 3 the reroll and next-blind buttons. Up and down skip empty rows; the column is clamped to the row.

**shop.lua:40** `function update_shop()`
O acts on what the cursor is on. A buy needs a free slot (joker_slots) and the money; a refused buy or reroll does nothing, and shop_message says why. Emptying a row moves the cursor down a row.
Keep: tests/test_boot.lua drives this with scripted presses and checks money and jokers after each.
