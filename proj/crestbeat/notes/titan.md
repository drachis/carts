# titan.lua

**titan.lua:1** `function make_titan(spec)`
`make_titan(spec)` takes a stage row (`bars`, `colour`) and gives the titan three hot spots, one over each lane, each with a third of `bars*8` health,
Keep: the user set the titan's life at 4 bars of fire and the queen's at 6.
It also and sets a collapse time on every building on the far part of the hill.

**titan.lua:33** `function open_spot(lane,beat)`
`open_spot` opens a hot spot until 2.5 beats after its chart beat: the beat it opens on and the two after can all be shot.
Keep: a spot opens for two shots on the beat, the user's "shoot shoot, 2 beats".

**titan.lua:94** `function spit(lane,beat)`
`spit` lands two beats after its chart beat, on the beat; `land_spit` hurts the robot only if it is in the lane then.

**titan.lua:33** `function open_spot(lane,beat)`
Opening a hot spot is also the bell's clock: if the window before had no hit (`window_hit`), the lamps go out. `hit_spot` lights a lamp on a window's first hit and rings the bell at three.
Keep: an exploration of the user's "glowing pattern" idea; the user could not picture it yet, so expect it to change.

**titan.lua:46** `function ring_lamp(spot)`
The bell: a shot on an unlit spot lights it; a shot on a lit one puts every lamp out; three lit rings it, once a giant (`titan.rung`), for the `bells` payout row. Destroying any spot before the bell rings takes the bell away (`titan.bell_lost`, also sets `rung`) and hides the lamps; the user asked for this.
Keep: the user's rule: one shot on each, a double tap resets, one ring a boss, worth tickets towards a perfect run.

**titan.lua:23** `function draw_limb(x0,y0,x1,y1,from_radius,to_radius,colour)`
witchcap's hut's limb: an outline pass and a fill pass of filled circles along a line, tapering. The giant's arms and legs.

**titan.lua:118** `function draw_titan()`
The giant as parts (after witchcap's hut), each sprite 1:1: wings behind, drawn like wyrmdeep's (a wrist, four finger bones, a scalloped membrane of lines; `flap` is a sine over two beats), legs as limbs stomping in turn on the beat with feet (88,72) standing on the road at the crest, the torso (0,96), arms as limbs with hands (80,72), the head (40,96 shut, 64,96 open for a beat after a spit) turned a little toward the robot. pal(3) swaps the body colour per giant. Hot spots (spot_xy) sit on the chest and shoulders, each behind a hex shield (`hexagon`, two rings and a glint) that shrinks away while its spot is open and flashes white when hit. Over the head, one segmented bar per lane, a segment per bar of the giant's health (`titan.bars`), red, blinking yellow while that lane is open, clamped below the HUD (y 10).
Keep: the user found the old glowing spots looked like nipples and asked for hex shields on the closed lanes, a look change only: the pacing and what can be shot did not change. The user asked for one health bar per lane over the head, segmented.
Keep: the user asked for the giant to follow witchcap's 2.5D multi-sprite hut, and for sprites drawn at their size over scaled ones.

**titan.lua:2** `titan={rise=0,spots={},colour=spec.colour,crown=spec.crown,bars=spec.bars}`
`crown` (the queen's stage row) gives a giant the queen's crowned head (88,96) and bone blade-wings (the finger bones drawn long and white, no membrane).
Keep: the user asked for the hive queen to have a queen-of-the-swarm look with a crown; it is our own design, not a copy of any character.
