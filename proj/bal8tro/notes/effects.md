# effects.lua

**effects.lua:1** `sparks,shake,chips_bump,mult_bump,heat={},0,0,0,0`
The juice state: sparks (particles, flames among them), shake (pixels of screen shake), how many pixels the chips and mult boxes are swollen by, and heat. All decay or are recomputed in update_effects, called every frame from _update60.

**effects.lua:4** `function burst(x,y,colour,count)`
Throws count sparks out from a point, up-biased, falling under gravity. A scoring step throws 8 in its colour (blue chips, red mult) from its pop; the hand total throws 40 yellow and orange from the boxes.

**effects.lua:11** `function draw_flames()`
Balatro's flames: while heat is 1 or more, a flickering band of red, orange and yellow two-pixel columns along the top of both boxes, taller with heat (up to 10px at heat 4). Drawn before the boxes so it licks up from behind them.

**effects.lua:23** `function fan_flames()`
heat is how many times over the blind's goal the score plus the hand on screen would be, while a hand is scoring, else 0. At 1 or more it adds flame sparks rising off both boxes, more and faster with heat; they ignore gravity and colour by life (flame_colours, white hottest).
Keep: tests/test_boot.lua checks the scripted pair of kings has no flames at 30x6 and flames at 80x6 against a goal of 300.

**effects.lua:46** `function shake_camera()`
Offsets the camera by up to shake pixels for the table only; _draw resets it before the banners.
Keep: the panel is drawn 8px past every edge so a shake never shows the felt above it.

**effects.lua:50** `function draw_sparks()`
Each spark is a short streak along its motion, so it reads at 128x128; it greys out in its last frames.
