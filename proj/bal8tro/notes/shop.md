# shop.lua

The shop follows Balatro's layout (reference/shop.png from balatro_ref): the sidebar stays, its strip reading "the shop"; the joker row stays on top; a dark panel with a red edge holds the next and reroll buttons on the left, the cards for sale with price tags on the right, and the booster packs under them.

**shop.lua:1** `function planet_item()`
A planet for a random hand: {hand,name,cost}, told from a joker by item.hand. Used by the shop's slots and celestial packs.

**shop.lua:6** `function deal_shop()`
Each sale slot is a planet one time in three, otherwise a joker never owned. Balatro weights planets 4 in 24 (its source: joker_rate 20, tarot_rate 4, planet_rate 4); with no tarots in the slots yet they come up more often here.

**shop.lua:13** `function open_pack(pack)`
Balatro's normal packs (its source: all $4; celestial and standard show 3, buffoon 2; choose 1). pack_choices are planets, jokers never owned, or random plain playing cards. An arcana pack also deals hand_size cards from a shuffle of run_deck into pack_hand, the same card tables, so a tarot's change lasts. The pack screen has the cursor model too: row 1 the jokers, row 2 the choices then skip, row 3 the dealt hand (O picks up to 3).

**shop.lua:29** `function use_tarot(tarot)`
Applies a tarot to the picked cards of pack_hand, as Balatro does: refused (nothing returned, the pack stays open) unless 1 to tarot.most cards are picked; the hermit needs none. The hanged man takes cards out of run_deck and pack_hand.
Keep: tests/test_shop.lua checks every act and a refusal.

**shop.lua:54** `function take_choice(index)`
Uses the choice: a planet levels its hand, a playing card joins run_deck for the rest of the run, a joker needs a free slot (returns nothing if refused, and the pack stays open).
Keep: tests/test_hands.lua checks all three kinds and the refusal.

**shop.lua:85** `function open_shop()`
Opens after every cash-out, the bosses' included; only the last ante's boss ends the run instead. Reroll starts at $5 and rises $1 a reroll within the shop; it rerolls the cards, not the two packs, as in Balatro. The cursor starts on the first card for sale (row 2, column 3).

**shop.lua:94** `function sell_price(joker)`
Balatro's sell value: half the cost, at least $1.

**shop.lua:112** `function update_shop()`
While leaving is set (a pack opening, the next blind starting) input is ignored and the panel slides away; the action follows on a timer (after). Rows (steer): 1 owned jokers, O sells; 2 next, reroll, then the cards for sale; 3 the packs, O opens one. A planet is used the moment it is bought (Balatro puts it in a consumable slot first) and needs only the money; a joker needs a free slot and the money. A refused action does nothing and shop_message says why. After an action the row's column is clamped so the cursor stays on something.
Keep: tests/test_boot.lua drives this with scripted presses and checks money, jokers and levels after each, and opens and skips a pack.

**shop.lua:159** `function draw_mini_planet(item,x,y,focused)`
A planet: a lavender card with a ringed planet (its colour from the hand) and the level it would bring.

**shop.lua:168** `function draw_mini_tarot(tarot,x,y,focused)`
A tarot: a purple card with a star and the first four letters of its name; the tooltip gives the rest, its third line saying to pick cards in the dealt hand.

**shop.lua:176** `function draw_pack(pack,x,y,focused)`
A booster: a card-sized packet in the pack's colour with its name's first four letters.

**shop.lua:184** `function draw_pack_screen()`
The open pack: the felt turns the pack's colour (Balatro does the same), the choices sit centred under the joker row, the pack's name and "choose 1" under them, then skip; the tooltip names a planet or joker, kept clear of the label.

**shop.lua:215** `function draw_shop()`
Draws the shop over the same felt and sidebar as the table, its panel, everything in it and the tooltip shifted by shop_panel's glide (so it slides up on opening and down when leaving, about 20 frames at the speed cap, as Balatro's does), then the tooltip for whatever the cursor is on (under the cards it may cover the packs, as Balatro's hover does), the deck pile, particles and the message line.
