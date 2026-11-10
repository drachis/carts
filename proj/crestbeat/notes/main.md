# main.lua

**main.lua:34** `function sync_clock()`
`sync_clock` pulls `clock` halfway toward the beat that channel 0's note number (`stat(50)`) says, each time that note changes. Channel 0 is the drums in every pattern; patterns are 8 beats.
Keep: the clock follows the music, not the other way round; with music stubbed (tests) it runs on frames alone.

**main.lua:49** `function on_beat(beat)`
`on_beat` reads one chart character per beat (`lane_of` turns a character of a three-character set into lane -1, 0, 1): `123` aliens, `qwe` hot spots, `asd` spit; anything else is a rest.

**main.lua:75** `function update_play()`
`update_play` steps the clock, runs every whole beat it crossed, then the robot, then the aliens. The wave is won when the chart is used up and no alien is left.

**main.lua:138** `function draw_hud()`
`draw_hud`: hearts top left, multiplier top centre, score top right, a thin dim timeline along the bottom (y 123-127): the gun's shots as short ticks in its colour flowing left to a grey mark, whole beats as dark dots, the gun's name at the right.
Keep: background, not a NecroDancer bar: nothing in it flashes; the user asked for it softened.
