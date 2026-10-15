# draw.lua

**draw.lua:1** `function thing_position(thing)`
Where a pop appears: above a card, below a joker (above a joker it covered the hands line).

**draw.lua:18** `function glide(thing,x,y)`
Every card and joker eases a quarter of the way to where it is drawn each frame, so picking, sorting, playing, buying and selling all slide. The eased position lives on the thing (glide_x/y); x,y are the rounded pixel it was drawn at, which the pops and the cursor use. A thing seen for the first time appears where it is drawn.
Keep: the easing runs in the draw, once a frame at 60fps; tests/test_boot.lua checks a picked card is part-way after one frame.

**draw.lua:26** `function draw_card(card,x,y)`
Cards are 15x21, sixteen pixels apart so eight fill the screen. A card or joker in the current step is lifted 3px.

**draw.lua:49** `function draw_panel()`
The panel is the top 42 rows: blind and goal, ante beside the score label, money left of the hand name, chips box (blue) x mult box (red), hands, discards, deck.
Keep: the ante sits right of the blind name because centred it met a six-digit goal and "small blind"; the money's row leaves room for "three of a kind" centred.

**draw.lua:68** `function draw_table()`
Felt green table. Four joker slots across at y44, empty ones outlined. Played cards sit mid-screen, those that score 4px higher. The hand sits in a shallow arc (outer cards 3px lower) and each card bobs under a pixel on its own phase; picked cards rise 7px; the cursor is a yellow frame round the card as drawn.
