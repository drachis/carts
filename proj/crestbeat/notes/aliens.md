# aliens.lua

**aliens.lua:5** `function update_aliens()`
`update_aliens`: an alien hops one step a beat, the hop taking the first third of the beat. `t` runs from -1/walk_beats (behind the crest) on the beat it is sent to 1 at the bottom, where it costs the robot a point of hp. A hit's knockback moves `born` later.
Keep: the aliens list stays sorted by `t`, far first; `front_alien` and drawing rely on it.

**aliens.lua:48** `function draw_fallen()`
A killed alien becomes a body in `fallen` that tips over backwards like a shooting-gallery target: its sprite squashes from the feet over 5 frames to a sliver, goes dark green, and is gone after 24 frames. Its sound is the knockdown clack (sfx 3). Ages in the draw.
Keep: the user asked for gallery knockdowns that clack.

**aliens.lua:60** `function draw_aliens(behind)`
`draw_aliens(behind)` is called twice: for aliens still behind the crest (clipped at the crest, so they rise over it, in front of a titan), and for the rest.
