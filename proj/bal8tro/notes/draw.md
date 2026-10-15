# draw.lua

**draw.lua:1** `function thing_position(thing)`
Where a pop appears: above a card, below a joker (above a joker it covered the hands line).

**draw.lua:18** `function draw_card(card,x,y)`
Cards are 15x21, sixteen pixels apart so eight fill the screen. A card or joker in the current step is lifted 3px. draw_card stores x,y on the card for the pops.

**draw.lua:41** `function draw_panel()`
The panel is the top 42 rows: blind and goal, ante beside the score label, money left of the hand name, chips box (blue) x mult box (red), hands, discards, deck.
Keep: the ante sits right of the blind name because centred it met a six-digit goal and "small blind"; the money's row leaves room for "three of a kind" centred.

**draw.lua:60** `function draw_table()`
Felt green table. Four joker slots across at y44, empty ones outlined. Played cards sit mid-screen, those that score 4px higher. Picked hand cards rise 7px; the cursor is a yellow frame.
