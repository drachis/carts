# world.lua

**world.lua:61** `function sunset(horizon,sun_x,sun_y,radius,glory)`
The synthwave sky shared by the title and play: navy, a dithered navy-purple band, purple down to the horizon, stars, and a striped sun (yellow, orange, red, pink downward, its slats widening toward the bottom and scrolling) cut off at the horizon. With `glory` (0..1) it throws god rays: Loretta's rays (sixteen thin triangles through `tri`, Loretta's scanline fill, in see-through fill patterns, slowly turning, alternately orange and pink), reaching out by `glory`.
Keep: the user asked for the sun behind the boss's head while you fight it, like an old religious painting, with Loretta's god rays.
Keep: the user loved the 1980s title and asked for the whole game to have its art direction (the crestbeat-synth branch).

**world.lua:1** `function project(lane,t)`
`project(lane,t)` is the whole perspective: lane -1..1, `t` 0 at the crest to 1 at the bottom of the hill (y=100); lanes 12px apart at the crest and 40 at the bottom. Behind the crest (`t<0`) things sink below the crest line.

**world.lua:107** `function draw_ground()`
`draw_ground`: black ground with a dim purple grid line across it every 0.1 of depth, the road's edges in neon pink, blue dashes between the lanes. `scroll` slides the grid and dashes while flying.
Keep: the dashes do not flash on the beat; the user asked for the NecroDancer-style beats to be softened into the background.

**world.lua:90** `function draw_sky()`
`draw_sky`: the `sunset` at the crest, the sun leaning a tenth with the camera; in a giant fight the sun glides up behind the giant's head as it rises (`titan.rise`, which also sinks it as the giant falls) and its rays reach out by the same amount; and the skyline as black silhouettes, one lit window each, parallax 15%.

**world.lua:135** `function draw_buildings(behind)`
A neon city: each building navy with an outline in its `glow` (blue, pink or lavender, picked in `make_city`), and a grid of windows lit by a fixed pattern from its size (about two in five, one in seven of those yellow), so they do not flicker frame to frame.

**world.lua:86** `function fever()`
Fever is the top multiplier (x4) in play: the grid lines turn pink, the sun throws its rays on any stage (pulsing a little with the beat), and the HUD shows "fever x4".
Keep: the user's "go wild" pass; fever makes a long combo feel like something.
