# world.lua

**world.lua:1** `function project(lane,t)`
`project(lane,t)` is the whole perspective: lane -1..1, `t` 0 at the crest to 1 at the bottom of the hill (y=100); lanes 12px apart at the crest and 40 at the bottom. Behind the crest (`t<0`) things sink below the crest line.

**world.lua:39** `function draw_ground()`
`draw_ground`: grey ground, the black road as strips, yellow dashes between the lanes that turn white on the beat. `scroll` slides the dashes (for flying up the hill later).
