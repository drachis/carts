# things.lua

**things.lua:5** `function update_things(hero)`
Each thing's behaviour is found by name: update_<name>, touch_<name>, draw_<name>. A new kind of thing is a row in thing_specs and these functions.

**things.lua:99** `function touch_squirrel(squirrel,hero)`
A stomp needs her falling with her feet in the squirrel's top half; anything else hurts her. Stomp points double each bonk without landing (chain), up to 8x.

**things.lua:129** `function update_neighbour(neighbour,hero)`
Sitting within pet_range of a neighbour starts the petting; at its end her hearts fill by pet_hearts, once a neighbour.

**things.lua:145** `function draw_neighbour(neighbour)`
The neighbour is seen from a corgi's height: trouser legs from the top of the screen to the shoes, and a hand that comes down to pat her head while petting.
**Keep:** the user asked for a Peanuts-style adult whose top is never seen.

**things.lua:166** `function draw_gate(gate)`
The observatory, drawn at the gate's cell; the gate box itself is what she touches to win.

**things.lua:225** `function puff(x,y,count,colour)`
Puffs spread by an angle worked out from their index, not rnd, so tests replay.
