# scenery.lua

**scenery.lua:1** `screen_palette=split"0,129,130,3,4,141,6,7,8,9,10,11,12,13,1`
The display palette: slots 1, 2, 5 and 15 show the extra colours 129 navy, 130 plum, 141 mauve and 143 salmon. png.py draws test screenshots with the same colours. pget reads the slot, not the colour.

**scenery.lua:5** `haze_ramp=split"15,14,13,5,2,1"`
Haze from most (salmon, the sky near the horizon) to least (navy). Each hill layer starts at a place on this ramp and moves along it as she nears the observatory, blending two steps with a checkerboard.
**Keep:** the user asked for haze that clears as she nears the observatory, as a sign of progress.

**scenery.lua:15** `function haze_fill(layer_near,top_fn,parallax,cam_x)`
Every fill pattern is drawn with the camera at 0, so the checkerboard is fixed to the screen and does not crawl as the view scrolls.
**Keep:** the user asked for screen-locked dither; test_moves checks it.

**scenery.lua:37** `function draw_backdrop(cam_x)`
Dusk deepens with progress: the sky bands slide down, stars come out, the sun sets.

**scenery.lua:70** `function draw_far_observatory(cam_x,colour)`
The observatory far off on the hills, growing as she nears it; a light comes on past halfway.
