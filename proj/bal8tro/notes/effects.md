# effects.lua

**effects.lua:1** `sparks,shake,chips_bump,mult_bump={},0,0,0`
The juice state: sparks (particles), shake (pixels of screen shake), and how many pixels the chips and mult boxes are swollen by. All decay in update_effects, called every frame from _update60.

**effects.lua:3** `function burst(x,y,colour,count)`
Throws count sparks out from a point, up-biased, falling under gravity. A scoring step throws 8 in its colour (blue chips, red mult) from its pop; the hand total throws 40 yellow and orange from the boxes.

**effects.lua:22** `function shake_camera()`
Offsets the camera by up to shake pixels for the table only; _draw resets it before the banners.
Keep: the panel is drawn 8px past every edge so a shake never shows the felt above it.

**effects.lua:26** `function draw_sparks()`
Each spark is a short streak along its motion, so it reads at 128x128; it greys out in its last frames.
