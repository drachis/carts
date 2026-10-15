# draw.lua

**draw.lua:1** `function thing_position(thing)`
Where a pop appears: above a card, below a joker (above a joker it covered the hands line).

**draw.lua:18** `function glide(thing,x,y)`
Every card and joker eases a quarter of the way to where it is drawn each frame, so picking, sorting, playing, buying and selling all slide. The eased position lives on the thing (glide_x/y); x,y are the rounded pixel it was drawn at, which the pops and the cursor use. A thing seen for the first time appears where it is drawn. A thing with wait>0 holds still and counts down; the deal tick plays as it sets off. draw_card shows a waiting card face down (draw_back), so a dealt card sits on the deck, flips, and flies to the hand.
Keep: the easing runs in the draw, once a frame at 60fps; tests/test_boot.lua checks a picked card is part-way after one frame.

**draw.lua:39** `function draw_card(card,x,y)`
Cards are 15x21, sixteen pixels apart so eight fill the screen. A card or joker in the current step is lifted 3px. A debuffed card is dimmed with a light ░ grey and struck through in red, light enough that its rank still reads (▒ hid it).

**draw.lua:69** `function draw_panel()`
The panel is the top 42 rows: blind and goal, ante beside the score label, money left of the hand name, chips box (blue) x mult box (red), hands, discards, deck.
Keep: the ante sits right of the blind name because centred it met a six-digit goal and "small blind"; the money's row leaves room for "three of a kind" centred. The hand name is drawn after the flames and boxes, with a black shadow, because the flames covered it.

**draw.lua:94** `function draw_table()`
Felt green table. Four joker slots across at y44, empty ones outlined. The deck pile is at deck_x,deck_y, one to four backs by how many cards are left. Cards in flying glide to (150,80), off the right edge, and are dropped once past x127. Played cards sit mid-screen, those that score 4px higher. The hand sits in a shallow arc (outer cards 3px lower) and each card bobs under a pixel on its own phase; picked cards rise 7px; the cursor is a yellow frame round the card as drawn.
