# shop.lua

The shop follows Balatro's layout (reference/shop.png from balatro_ref): the sidebar stays, its strip reading "the shop"; the joker row stays on top; a dark panel with a red edge holds the next and reroll buttons on the left and the cards for sale with price tags on the right.

**shop.lua:1** `function deal_shop()`
Each sale slot is a planet one time in three, for a random hand; otherwise a joker. A planet item is {hand,name,cost}, told from a joker by item.hand. Balatro weights planets 4 in 24 and adds celestial packs; with no packs yet they come up more often here.

**shop.lua:11** `function open_shop()`
Opens after every cash-out, the bosses' included; only the last ante's boss ends the run instead. Reroll starts at $5 and rises $1 a reroll within the shop. The cursor starts on the first card for sale (row 2, column 3).

**shop.lua:18** `function sell_price(joker)`
Balatro's sell value: half the cost, at least $1.

**shop.lua:32** `function update_shop()`
Rows (steer): 1 owned jokers, O sells; 2 next, reroll, then the cards for sale, O acts. A planet is used the moment it is bought (Balatro puts it in a consumable slot first) and needs only the money; a joker needs a free slot and the money. A refused action does nothing and shop_message says why. After an action the row's column is clamped so the cursor stays on something.
Keep: tests/test_boot.lua drives this with scripted presses and checks money, jokers and levels after each.

**shop.lua:65** `function draw_mini_planet(item,x,y,focused)`
A planet for sale: a lavender card with a ringed planet (its colour from the hand) and the level it would bring.

**shop.lua:74** `function draw_shop()`
Draws the shop over the same felt and sidebar as the table, then the tooltip for whatever the cursor is on, the deck pile, particles and the message line.
