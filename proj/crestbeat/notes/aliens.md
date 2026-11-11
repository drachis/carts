# aliens.lua

**aliens.lua:1** `function send_alien(lane,beat,kind)`
An alien inherits its kind's row (`kinds` in data.lua) by metatable: `hp`, `walk`, `bonus`, `harmless`, `body`/`rim` colours, and for a kind on a track `track` and `depth`. `pos` is its position across the streets for drawing; `lane` is the street it counts as in for shooting.

**aliens.lua:7** `function update_aliens()`
Every motion is a smooth function of song time (the crestbeat-smooth branch). A walker's depth is `beats - surge*sin(beats)`, then `t=(step-1)/walk`: it surges forward on each beat and eases off between, always moving forward (surge 0.12 keeps its speed above zero), and because PICO-8's sin is 0 on every whole beat it stands exactly where the hopping version stood when a shot lands, so levels.py's plans hold. A weaver sweeps along `-cos(turn/4)`, -1, 0, 1, 0, a street every `weave` beats. The golden alien (`track`) glides at a constant speed across the streets at `depth`, from `pos` -2 to past 1.6, a street every `track` beats. Knockback is a spring: a hit adds to `knock`, and a quarter of what is left moves into `born` each frame.
Keep: the user asked for the hard beats smoothed out while the game stays about beat matching: shots still land on the beat. levels.py's weaver_street and gold_street must match these formulas on whole beats. The golden alien starts midway up the hill and is on the streets for 12 beats. The aliens list stays sorted by `t`, far first; `front_alien` and drawing rely on it, and that is how a nearer alien shields the golden one.
An alien that reaches the bottom in the robot's street is body-blocked: the heart is lost but it counts as downed (`kills` points, a "blocked" popup); one reaching the bottom in another street leaks, a heart and no points.
Keep: the user's rule, so a golden-alien chase can trade hearts for points without losing them.

**aliens.lua:97** `function draw_fallen()`
A killed alien becomes a body in `fallen` that tips over backwards like a shooting-gallery target: its sprite squashes from the feet over 5 frames to a sliver, goes to its kind's dark colour, and is gone after 24 frames. Its sound is the knockdown clack (sfx 3). Ages in the draw.
Keep: the user asked for gallery knockdowns that clack.

**aliens.lua:115** `function draw_aliens(behind)`
`draw_aliens(behind)` is called twice: for aliens still behind the crest (clipped at the crest, so they rise over it, in front of a titan), and for the rest. `kind_colours` swaps the sprite's green for the kind's colours. The bob is a smooth arc, `(cos(hop)-1)`, low on the beat and high between. The second call also draws each spit pillar (`draw_pillar`) in depth order among the aliens, before the first alien nearer than it.
Keep: the user saw the spit sorted wrongly: drawn before every alien, a farther alien covered a nearer glob (now a pillar).

**aliens.lua:88** `function swarm_sprite(size,sizes)`
The largest drawn size in a list that fits the size wanted: the swarm's ten (swarm_sprites, 8 to 32px) or the civilian's four (civilian_sprites, 8 to 24px), from art.py. Everything is drawn 1:1 with it, never scaled; a kind with `sprite` set uses the civilian list and bobs a pixel to run.
Keep: the user prefers many sprites to scaling sprites.

**aliens.lua:41** `function front_alien(lane)`
The nearest enemy in a street. An enemy on a track (the golden alien) counts as in every street whose middle it is within `straddle` (0.7) of, so while it is visually between two streets it can be shot from either; it is not the plan's choice, but it is an option. levels.py's gold_streets matches.
Keep: the user: "let it be hit from both streets if it is on both visually".
