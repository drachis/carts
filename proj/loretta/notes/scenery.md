# scenery.lua

**scenery.lua:1** `screen_palette=split"0,129,130,3,4,141,6,7,8,9,10,11,12,13,1`
The display palette: slots 1, 2, 5 and 15 show the extra colours 129 navy, 130 plum, 141 mauve and 143 salmon. png.py draws test screenshots with the same colours. pget reads the slot, not the colour.

**scenery.lua:5** `haze_ramp=split"15,14,13,5,2,1"`
Haze from most (salmon, the sky near the horizon) to least (navy). Each hill layer starts at a place on this ramp and moves along it as she nears the observatory, blending two steps with a checkerboard.
**Keep:** the user asked for haze that clears as she nears the observatory, as a sign of progress.

**scenery.lua:17** `function haze_fill(layer_near,top_fn,parallax,cam_x)`
Every fill pattern is drawn with the camera at 0, so the checkerboard is fixed to the screen and does not crawl as the view scrolls.
**Keep:** the user asked for screen-locked dither; test_moves checks it.

**scenery.lua:57** `function draw_backdrop(cam_x)`
Dusk deepens with progress: the sky bands slide down, stars come out, the sun sets.

**scenery.lua:99** `function draw_far_observatory(cam_x,colour)`
On the title it is big, dark and lit on the hill below the START panel (the reference has it right, but the player card and her head cover that side here).
The observatory far off on the hills, growing as she nears it; a light comes on past halfway.

**Finale**
Winning the last level pans the view up 80px (main.lua _draw): night sweeps down the sky with a dithered edge, stars fill it (draw_stars), the moon rises. test carts with plain_sky have an empty draw_night.
**Keep:** a star's position never depends on anything that changes: scaling it by the sky's height made every star jump each frame of the pan (the user saw noise). Night reveals fixed stars with clip.
The finale's banner leaves after 150 frames and the moon takes ten seconds to rise: the night sky is the player's reward (the user). O still returns to the title, with no prompt on screen.
