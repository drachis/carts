# shop.lua

**shop.lua:1** `function deal_shop()`
Each sale slot is a planet one time in three, for a random hand; otherwise a joker. A planet item is {hand,name,cost}, told from a joker by item.hand. Balatro weights planets 4 in 24 and adds celestial packs; with no packs here they come up more often.

**shop.lua:11** `function open_shop()`
Opens after every cash-out, the bosses' included; only the last ante's boss ends the run instead. Its foot names the next ante, blind and goal. Two jokers for sale, reroll at $5 rising $1 a reroll, back to $5 next shop. The cursor starts on the first joker for sale.

**shop.lua:18** `function sell_price(joker)`
Balatro's sell value: half the cost, at least $1.

**shop.lua:26** `function move_shop_row(step)`
Rows are 1 owned jokers (sell), 2 jokers for sale (buy), 3 the reroll and next-blind buttons. Up and down skip empty rows; the column is clamped to the row.

**shop.lua:50** `function update_shop()`
O acts on what the cursor is on. A planet is used the moment it is bought (Balatro puts it in a consumable slot first) and needs only the money; a joker needs a free slot (joker_slots) and the money; a refused buy or reroll does nothing, and shop_message says why. Emptying a row moves the cursor down a row.
Keep: tests/test_boot.lua drives this with scripted presses and checks money and jokers after each.
