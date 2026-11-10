# main.lua

**main.lua:37** `function sync_clock()`
`sync_clock` pulls `clock` halfway toward the beat that channel 0's note number (`stat(50)`) says, each time that note changes. Channel 0 is the drums in every pattern; patterns are 8 beats.
Keep: the clock follows the music, not the other way round; with music stubbed (tests) it runs on frames alone.

**main.lua:76** `function on_beat(beat)`
`on_beat` reads one chart character per beat (`lane_of` turns a character of a three-character set into lane -1, 0, 1): `123` aliens, `qwe` hot spots, `asd` spit; anything else is a rest.

**main.lua:106** `function update_play()`
`update_play` steps the clock, runs every whole beat it crossed, then the robot, then the aliens. The wave is won when the chart is used up and no alien is left.

**main.lua:179** `function draw_hud()`
`draw_hud`: hearts top left, multiplier top centre, score top right, a thin dim timeline along the bottom (y 123-127): the gun's shots as short ticks in its colour flowing left to a grey mark, whole beats as dark dots, the gun's name at the right.
Keep: background, not a NecroDancer bar: nothing in it flashes; the user asked for it softened.

**main.lua:46** `function plan_lane(beat,route)`
The street a route (the stage's `plan`, or `golden`) designates for a beat: its character there, "1" to "3", or nil for "."; looped like the chart in a titan stage. `draw_plan` shows it while down is held: chevrons for the next three shots, green fading, and gold where the golden route parts from the plan.
Keep: the user asked for this view to see the designated street; the test bots steer by the same function.

**main.lua:92** `if titan and not titan.dead and titan.rise==1 and clock-robot.moved>=idle_beats then`
The idle spit: in a giant fight, a robot that has not changed street for `idle_beats` (4) gets spat at where it stands (landing two beats later), so no one can sit in a street waiting for its hot spot. `robot.moved` is set on every street change and when a stage starts. levels.py asserts the plan never holds one street long enough to be hit.
Keep: the user: "spit should force the player to keep moving so they can't idle out in a lane".

**main.lua:223** `function draw_title()`
The 1980s title (DESIGN.md "The title"). The giant's silhouette is `draw_titan` with every colour mapped to 0 and `pal` stubbed out while it draws, so its own `pal` calls cannot undo that; it is clipped at the horizon (y 75), stood low with `crest_y` 225 and `titan.bars` 0 (no health bars). It sets `crest_y`, `robot.x`, `robot.lift` and `cam_x` for the title only; `reset` puts them back for play.
Keep: the user asked for a very 1980s title with the robot flying down the street towards the fight.

**main.lua:208** `function chrome(text,y,wide)`
Text in the title logo's chrome: printed three times through clips of four rows, white, blue and grey, over a navy shadow; `wide` for the double-width logo, tall letters only for stage banners.
