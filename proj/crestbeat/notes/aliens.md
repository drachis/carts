# aliens.lua

**aliens.lua:1** `function send_alien(lane,beat,kind)`
An alien inherits its kind's row (`kinds` in data.lua) by metatable: `hp`, `walk`, `bonus`, `harmless`, `body`/`rim` colours, and for a kind on a track `track` and `depth`. `pos` is its position across the streets for drawing; `lane` is the street it counts as in for shooting.

**aliens.lua:7** `function update_aliens()`
`update_aliens`: an alien steps once a beat (or once every `track` beats), the hop taking the first third of the step. A walker's `t` runs from -1/walk (behind the crest) on the beat it is sent to 1 at the bottom, where it costs the robot a heart. A kind with `track` (the golden alien) stays at `depth` and slides across the streets from the side its key names (left key from the left, else from the right), from `pos` -2 to past 2.2, where it gets away, costing nothing if `harmless`. A hit's knockback moves `born` later.
Keep: the user asked for the golden alien to start midway up the hill and move across the streets, on screen for 12 beats (track 3) so there is time to clear what is in front of it. The aliens list stays sorted by `t`, far first; `front_alien` and drawing rely on it, and that is how a nearer alien shields the golden one.

**aliens.lua:96** `function draw_fallen()`
A killed alien becomes a body in `fallen` that tips over backwards like a shooting-gallery target: its sprite squashes from the feet over 5 frames to a sliver, goes to its kind's dark colour, and is gone after 24 frames. Its sound is the knockdown clack (sfx 3). Ages in the draw.
Keep: the user asked for gallery knockdowns that clack.

**aliens.lua:114** `function draw_aliens(behind)`
`draw_aliens(behind)` is called twice: for aliens still behind the crest (clipped at the crest, so they rise over it, in front of a titan), and for the rest. `kind_colours` swaps the sprite's green for the kind's colours.

**aliens.lua:37** `function weave_lane(turn)`
A weaver's street for a turn of its sweep: -1, 0, 1, 0 and round. `update_aliens` starts the sweep at its chart street (`first`) and eases `pos` between streets as it hops; `lane` is the nearest street.

**aliens.lua:87** `function swarm_sprite(size,sizes)`
The largest drawn size in a list that fits the size wanted: the swarm's ten (swarm_sprites, 8 to 32px) or the civilian's four (civilian_sprites, 8 to 24px), from art.py. Everything is drawn 1:1 with it, never scaled; a kind with `sprite` set uses the civilian list and bobs a pixel to run.
Keep: the user prefers many sprites to scaling sprites.
