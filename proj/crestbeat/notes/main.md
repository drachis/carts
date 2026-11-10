# main.lua

**main.lua:33** `function sync_clock()`
`sync_clock` pulls `clock` halfway toward the beat that channel 0's note number (`stat(50)`) says, each time that note changes. Channel 0 is the drums in every pattern; patterns are 8 beats.
Keep: the clock follows the music, not the other way round; with music stubbed (tests) it runs on frames alone.

**main.lua:48** `function on_beat(beat)`
`on_beat` reads one chart character per beat: `1` `2` `3` send an alien down lane -1, 0, 1 (`ord` 49..51); anything else is a rest.

**main.lua:72** `function update_play()`
`update_play` steps the clock, runs every whole beat it crossed, then the robot, then the aliens. The wave is won when the chart is used up and no alien is left.

**main.lua:128** `function draw_hud()`
`draw_hud`: hearts top left, multiplier top centre, score top right, the beat bar along the bottom: ticks a beat apart close on the centre box from both sides; the box flashes white on the beat.
