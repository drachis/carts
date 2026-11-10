# titan.lua

**titan.lua:1** `function make_titan(spec)`
`make_titan(spec)` takes a stage row (`spot_hp`, `colour`) and gives the titan three hot spots, one over each lane, and sets a collapse time on every building on the far part of the hill.

**titan.lua:23** `function open_spot(lane,beat)`
`open_spot` opens a hot spot until 2.5 beats after its chart beat: the beat it opens on and the two after can all be shot.
Keep: a spot opens for two shots on the beat, the user's "shoot shoot, 2 beats".

**titan.lua:52** `function spit(lane,beat)`
`spit` lands two beats after its chart beat, on the beat; `land_spit` hurts the robot only if it is in the lane then.
