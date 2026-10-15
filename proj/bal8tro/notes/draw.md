# draw.lua

**draw.lua:1** `function thing_position(thing)`
Where a pop appears: above a card, below a joker (above a joker it covered the hands line).

**draw.lua:18** `function draw_card(card,x,y)`
Cards are 15x21, sixteen pixels apart so eight fill the screen. A card or joker in the current step is lifted 3px. draw_card stores x,y on the card for the pops.

**draw.lua:40** `function draw_panel()`
The panel is the top 42 rows: blind and goal, score, hand name, chips box (blue) x mult box (red), hands, discards, deck.

**draw.lua:58** `function draw_table()`
Felt green table. Played cards sit mid-screen, those that score 4px higher. Picked hand cards rise 7px; the cursor is a yellow frame.
