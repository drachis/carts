# world.lua

**world.lua:50** `function sunset(horizon,sun_x,radius)`
The synthwave sky shared by the title and play: navy, a dithered navy-purple band, purple down to the horizon, stars, and a striped sun (yellow, orange, red, pink downward, its slats widening toward the bottom and scrolling) whose lower part sinks behind the horizon. Play puts it at the crest, so in giant fights the giant stands in front of it.
Keep: the user loved the 1980s title and asked for the whole game to have its art direction (the crestbeat-synth branch).

**world.lua:1** `function project(lane,t)`
`project(lane,t)` is the whole perspective: lane -1..1, `t` 0 at the crest to 1 at the bottom of the hill (y=100); lanes 12px apart at the crest and 40 at the bottom. Behind the crest (`t<0`) things sink below the crest line.

**world.lua:78** `function draw_ground()`
`draw_ground`: black ground with a dim purple grid line across it every 0.1 of depth, the road's edges in neon pink, blue dashes between the lanes. `scroll` slides the grid and dashes while flying.
Keep: the dashes do not flash on the beat; the user asked for the NecroDancer-style beats to be softened into the background.

**world.lua:69** `function draw_sky()`
`draw_sky`: the `sunset` at the crest, the sun leaning a tenth with the camera, and the skyline as black silhouettes, one lit window each, parallax 15%.

**world.lua:100** `function draw_buildings(behind)`
A neon city: each building navy with an outline in its `glow` (blue, pink or lavender, picked in `make_city`), and a grid of windows lit by a fixed pattern from its size (about two in five, one in seven of those yellow), so they do not flicker frame to frame.
