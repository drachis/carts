# draw.lua

The table follows Balatro's layout, at the user's request: a sidebar on the left (x0-38) with the run's numbers, and the right side (x40-127, centre table_centre) for jokers, played cards, the hand, the buttons and the deck.

**draw.lua:1** `function thing_position(thing)`
Where a pop appears: above a card, below a mini joker.

**draw.lua:26** `function print_centre(text,y,colour,centre)`
Centres text on centre (default 64). PICO-8's font is fixed width: each character advances 4 pixels, each glyph (characters 128 and up, like the button symbols) 8, so the width is summed, not measured.
Keep: never measure by printing off-screen: a print at y -99 came on screen when the banner and shop slid away under camera(0,-110), and the user saw the cash-out text garbled top left. tests/test_table.lua checks the top rows stay clean under that shift.
**draw.lua:45** `function glide(thing,x,y)`
Every card and joker moves to where it is drawn as a damped spring (velocity vx,vy; spring and damping in data.lua), its speed capped at glide_cap pixels a frame, so a pick snaps and a long move travels at Balatro's pace (measured: 0.4-0.5 card widths a frame, 6-7px at this size) then overshoots and settles (its played cards overshoot by a tenth to a third); a thing with hold>0 waits in place first (played cards set off play_stagger apart), so picking, sorting, playing, buying and selling all slide. The eased position lives on the thing (glide_x/y); x,y are the rounded pixel it was drawn at, which the pops and the cursor use. A thing seen for the first time appears where it is drawn. A thing with wait>0 holds still and counts down; the deal tick plays as it sets off. draw_card shows a waiting card face down (draw_back), so a dealt card sits on the deck, flips, and flies to the hand.
Keep: the easing runs in the draw, once a frame at 60fps; tests/test_boot.lua checks a picked card is part-way after one frame.

**draw.lua:72** `function draw_card(card,x,y)`
Cards are 15x21, grown or shrunk on every side by the card's swell (a kick's pulse, rounded), as Balatro's cards scale; mini jokers the same. A card or joker in the current step is lifted 3px. An enhanced card has a border in its enhancement's colour and the first letter of its name top right. A debuffed card is dimmed with a light ░ grey and struck through in red, light enough that its rank still reads (▒ hid it).

**draw.lua:105** `function draw_mini_joker(joker,x,y,focused)`
Every joker, on the table and in the shop, is this 20x20 card: its 8x8 portrait (joker.sprite, drawn by gen_cart.py) above its current worth in its colour (blue chips, red mult and xmult). The name and full text are in the tooltip, as Balatro shows them on hover.

**draw.lua:114** `function draw_tooltip(thing,y)`
A white box at y under the focused joker or planet, kept on the right side. A joker: name, effect, condition, and its sell price if owned. A planet: name, the hand it levels, the level before and after.

**draw.lua:122** `function draw_joker_row(focused)`
The owned jokers across the top, x42 and 21 apart, empty slots outlined: the table and the shop both draw it, so a joker keeps its place between them.

**draw.lua:136** `function draw_sidebar()`
Top to bottom: the blind on a strip coloured by kind (blue small, orange big, red boss), its name in two words; in the shop and packs the strip reads "the shop" and drops in from above as the shop opens and leaves upward when going to the next blind (sign, a glide thing; exiting is set only then), as Balatro's SHOP sign does; goal; round score; the hand's short name and level; chips and mult boxes (chips_x, mult_x, boxes_y, with flames behind them); hands and discards; money, double width; ante and round; deck count; the hint for the joker row.
Keep: everything is at most 8 characters to fit 37px, which is why hands use their short names ("3 kind") and the level is its own line. The panel is drawn 8px past the screen's edges so a shake never shows the felt.

**draw.lua:169** `function draw_hand(cards,centre,y,hovered)`
The hand's placement, shared by the table and the title (the user asked for the title's cards to move as the hand does): cards spread 10px apart from the middle of those that have landed (dealt cards wait face down on the deck), so the fan widens as each arrives, on a slight arc; picked cards sit 5px up, the hovered one 2px. centre is a card's left edge at the middle, so a hand centres on centre+7: the table passes 76 (table_centre 84), the title 57 (the screen's 64).
Keep: the title's x is 57, not 64; the user saw it off centre at 64.

**draw.lua:179** `function draw_table()`
Four mini joker slots across the top (x42, 21 apart), empty ones outlined. The boss's rule shows under them when there is no tooltip and nothing played. Played cards sit at y48, centred; scoring ones lift 4px from frame 72 after play (lift_wait), as Balatro's do. The hand overlaps, 10px apart, centred on x76 over only the cards that have arrived from the deck, so it opens like a fan during the deal and closes up as cards leave (Balatro re-spreads its hand the same way), in a shallow arc (middle 2px above the ends; Balatro's is about 1.5px at this size), still at rest as Balatro's is (it moves under a fifth of a pixel at this size, so the old bob was removed); picked cards rise 7px and the card under the cursor 3px more; the cursor's frame is drawn after the whole hand so the next card does not cover it. Play, discard and sort buttons (table_buttons) under the hand grey out when they would do nothing, rise and frame in yellow under the cursor, and jump when pressed; the line under them says what O does on the cursor's row. The deck pile is bottom right; cards in flying glide off the right edge and are dropped past x127.

The card backs (draw_back) take the chosen deck's colour, on the table, the title's deck chooser and the shop's deck pile.

**draw.lua:254** `function draw_select()`
Balatro's blind select (reference/blind_select.png): three tall panels across the right side for the ante's small, big and boss blinds, each with its state (select on the current one, done, next), its name, a chip in its colour, its goal and its reward in dollar signs; the whole slides with select_panel's glide.

**draw.lua:275** `function draw_info()`
The info overlay, drawn over the table it draws first, from the info button: two tabs (left/right swap, O, X or down close). hands: like Balatro's run info, strongest first, each hand's level, short name, chips x mult at its level, and times played this run. deck: the run deck as a 4x13 grid of suit rows and rank columns, a white cell for each card held (grey if none, an enhancement's colour as its border), then each suit's count and the total. On dark grey (Balatro's panel), because the spade's dark blue vanished on dark blue.

**draw.lua:335** `function _draw()`
A mode with a draw_ function of its own name (title, shop, pack, select, info) is drawn by it alone; the rest (play, score, cashout, won, lost) are the shaken table and the banner. draw_pack is the pack screen; draw_booster is a pack's picture in the shop.

**draw.lua:36** `function slide(panel)`
The cash-out banner, select screen and shop panel slide the same way: up from 110px below to 0, and back down while leaving is set; camera shifts everything drawn after it until camera() (the tooltip rides along). panel_at (effects.lua) makes a fresh panel at a start height.

**draw.lua:223** `function draw_banner(title,line,colour,lines,big)`
One panel for the cash-out and the end screens, centred on its number of rows. Each row is a label, a value already a string or number, and an optional colour (default yellow). big prints the title wide and tall (8px a character, centred by that). cash_out turns its amounts into "$" strings after summing them.

**draw.lua:242** `function draw_jimbo()`
Jimbo, the joker who mocks the player on the game over and win screens (the user's idea; the quips are bal8tro's own, not Balatro's): the card face sprite and joker portrait 32 stretched with sspr, no new art, gliding in from the left over the sidebar, with the quip typed out a letter every 2 frames in a bubble under him, a jiggle and tick every 8 frames while he talks. _draw tints the table under the end screens by pal() with end_specs' tint (red for game over, green for a win), as Balatro washes its screen.

**draw.lua:52** `thing.flip=0`
A dealt card turns over as it lands: draw_card narrows it with clip to its centre through zero and back over 16 frames, showing the back for the first half and the face for the second.
Keep: never name a global flip. It replaced PICO-8's own flip(), and the cart stopped after its first frame with no error.

**draw.lua:237** `function draw_joker_card(x,y,scale)`
The Joker as a card: the card face sprite and joker portrait 32 stretched together with sspr, scale in card widths. The intro's splash Joker (1.2) and Jimbo (1.75) are both this.

**draw.lua:327** `local fade=(intro_t-intro_end)`
The title fades in out of the intro's white, as Balatro's menu does out of its flash (Balatro holds it, then clears it over 4s; the user found that long white a freeze): white through fillp patterns, solid, then dense, half and sparse, 12 frames each, so the title shows within 48 frames. intro_t counts on in update_title (capped at 2000, which is also where skip_intro starts it, past the fade).
