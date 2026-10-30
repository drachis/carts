# things.lua

**things.lua:5** `function update_things(hero)`
Each thing's behaviour is found by name: update_<name>, touch_<name>, draw_<name>. A new kind of thing is a row in thing_specs and these functions.

**things.lua:128** `function touch_squirrel(squirrel,hero)`
A stomp needs her falling with her feet in the squirrel's top half; any other touch chases it off (spook, away from her). Stomp points double each bonk without landing (chain), up to 8x.
Keep: squirrels never cost a heart; the user wanted to chase them, not run into them.

**things.lua:158** `function update_neighbour(neighbour,hero)`
Sitting within pet_range (64, the zone the user circled: about a dog length either side) of a neighbour starts the petting; at its end her hearts fill by pet_hearts, once a neighbour.

**things.lua:183** `function draw_neighbour(neighbour)`
The neighbour is a tall adult seen from a corgi's height: one of four Los Feliz outfits (sprite 99 on, 10x16 each: sundress, bowling shirt, overalls, jumpsuit, by place) stretched from off the top of the screen to the shoes, skin (f) swapped from skins, the head never seen. Petting, they step in behind her shoulders (step) and the arm on her head's side swings down; a big hand (twice size) lands: pat, pat, pat, a pause (40-frame beat); each pat dips her head (flop) and knocks her ears sideways. Until the first pats they hold a bone treat. Only the first pats restore hearts; after that, while she sits by them, they pat again at random (1 in pet_again a frame).
Keep: the user asked for the petting to stay beside her, not the hand in front, and for repeat pats without hearts because the petting is charming.
**Keep:** the user asked for a Peanuts-style adult whose head is off screen, about six times her shoulder height, and a larger hand that gives a good pat - pat - pat.

**things.lua:207** `function draw_gate(gate)`
The end of a level, at its cell: on levels 1..5 an arch with the level's dog landmark named on its banner (landmarks), on the last the observatory (both shapes in data.lua). The gate box itself is what she touches to win.

**things.lua:85** `function update_hydrant(hydrant,hero)`
A hydrant is a checkpoint, lit once she passes it at any height: needing to touch it let a jump or a squirrel bounce carry her over it, and a fall then sent her far back.

**things.lua:247** `function puff(x,y,count,colour)`
Puffs spread by an angle worked out from their index, not rnd, so tests replay.

**things.lua:37** `function draw_prop(prop,shape)`
Draws a prop from its shape (or a named one). Things without a draw_<name> function fall through to this.

**things.lua:100** `function update_squirrel(squirrel,hero)`
A squirrel sleeps until Loretta is within squirrel_wake pixels, then patrols no further than squirrel_patrol from where it woke, turning at walls and edges. Its speed grows along the level (squirrel_speed plus squirrel_ramp times how far along it is). When every squirrel walked from the start, the yard's had wandered into Fern Dell by the time she got there, so where a squirrel was placed said nothing about where she met it.
A spooked squirrel (bumped or barked at) runs squirrel_flee px a frame for squirrel_run frames, then climbs straight up a tree and three coins fall from above it to its feet (coin.land; update_coin).
**Keep:** placement means something: bot_playthrough's challenge per section depends on it.

**things.lua:23** `function draw_slot(slot)`
House, tree and decor slots (K, T, d in the level text) pick which shape they show from slot_kinds by where they are and the level, and tint walls (15) and roofs (8) from walls and roofs, so a chunk reused through a level looks different each time: the seed mixes in the chunk index (x\256*5), since a chunk is 32 tiles wide and x\8 alone gave every copy the same building and colours (the user saw five of one in a row). Houses are weighted two homes to one shop (slot_kinds). Colours are put back one by one: pal() would also reset the screen palette.
**Keep:** the user asked for streets varied by palette swaps and creative placement, with landmarks never repeating; landmarks are not slots.

**things.lua:33** `function praise(x,y)`
A floating word of praise picked from praises by place and level.
**Keep:** the user asked not to repeat one phrase ("good girl") everywhere.
