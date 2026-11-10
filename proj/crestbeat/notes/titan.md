# titan.lua

**titan.lua:1** `function make_titan(spec)`
`make_titan(spec)` takes a stage row (`bars`, `colour`) and gives the titan three hot spots, one over each lane, each with a third of `bars*8` health,
Keep: the user set the titan's life at 4 bars of fire and the queen's at 6.
It also and sets a collapse time on every building on the far part of the hill.

**titan.lua:23** `function open_spot(lane,beat)`
`open_spot` opens a hot spot until 2.5 beats after its chart beat: the beat it opens on and the two after can all be shot.
Keep: a spot opens for two shots on the beat, the user's "shoot shoot, 2 beats".

**titan.lua:83** `function spit(lane,beat)`
`spit` lands two beats after its chart beat, on the beat; `land_spit` hurts the robot only if it is in the lane then.

**titan.lua:23** `function open_spot(lane,beat)`
Opening a hot spot is also the bell's clock: if the window before had no hit (`window_hit`), the lamps go out. `hit_spot` lights a lamp on a window's first hit and rings the bell at three.
Keep: an exploration of the user's "glowing pattern" idea; the user could not picture it yet, so expect it to change.

**titan.lua:36** `function ring_lamp(spot)`
The bell: a shot on an unlit spot lights it; a shot on a lit one puts every lamp out; three lit rings it, once a giant (`titan.rung`), for the `bells` payout row.
Keep: the user's rule: one shot on each, a double tap resets, one ring a boss, worth tickets towards a perfect run.
