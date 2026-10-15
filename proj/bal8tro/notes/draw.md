# draw.lua

The table follows Balatro's layout, at the user's request: a sidebar on the left (x0-38) with the run's numbers, and the right side (x40-127, centre table_centre) for jokers, played cards, the hand, the buttons and the deck.

**draw.lua:1** `function thing_position(thing)`
Where a pop appears: above a card, below a mini joker.

**draw.lua:18** `function glide(thing,x,y)`
Every card and joker eases a quarter of the way to where it is drawn each frame, so picking, sorting, playing, buying and selling all slide. The eased position lives on the thing (glide_x/y); x,y are the rounded pixel it was drawn at, which the pops and the cursor use. A thing seen for the first time appears where it is drawn. A thing with wait>0 holds still and counts down; the deal tick plays as it sets off. draw_card shows a waiting card face down (draw_back), so a dealt card sits on the deck, flips, and flies to the hand.
Keep: the easing runs in the draw, once a frame at 60fps; tests/test_boot.lua checks a picked card is part-way after one frame.

**draw.lua:43** `function draw_card(card,x,y)`
Cards are 15x21. A card or joker in the current step is lifted 3px. A debuffed card is dimmed with a light ░ grey and struck through in red, light enough that its rank still reads (▒ hid it).

**draw.lua:73** `function draw_joker(joker,x,y,focused)`
The full 31x20 joker, with name, effect and condition: the shop only.

**draw.lua:84** `function draw_mini_joker(joker,x,y,focused)`
The table's 20x20 joker: its 8x8 portrait (joker.sprite, drawn by gen_cart.py) above its current worth in its colour (blue chips, red mult and xmult). The name and full text are in the tooltip, as Balatro shows them on hover. The tag column is no longer drawn here.

**draw.lua:94** `function draw_tooltip(joker)`
Under the focused joker, kept on the right side: name, effect, condition and sell price.

**draw.lua:112** `function draw_sidebar()`
Top to bottom: the blind on a strip coloured by kind (blue small, orange big, red boss), its name in two words; goal; round score; the hand's short name and level; chips and mult boxes (chips_x, mult_x, boxes_y, with flames behind them); hands and discards; money, double width; ante and round; deck count; the hint for the joker row.
Keep: everything is at most 8 characters to fit 37px, which is why hands use their short names ("3 kind") and the level is its own line. The panel is drawn 8px past the screen's edges so a shake never shows the felt.

**draw.lua:146** `function draw_table()`
Four mini joker slots across the top (x42, 21 apart), empty ones outlined. The boss's rule shows under them when there is no tooltip and nothing played. Played cards sit at y44 (scoring ones 4px higher), centred. The hand overlaps, 10px apart from x41, in a shallow arc, each card bobbing on its own phase; picked cards rise 7px and the card under the cursor 3px more; the cursor's frame is drawn after the whole hand so the next card does not cover it. Play, discard and sort buttons (table_buttons) under the hand grey out when they would do nothing, rise and frame in yellow under the cursor, and jump when pressed; the line under them says what O does on the cursor's row. The deck pile is bottom right; cards in flying glide off the right edge and are dropped past x127.
