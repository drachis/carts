# loretta.lua

**loretta.lua:1** `function new_loretta(x,y)`
held starts at 63 (every button) so a press that started the game, or a respawn, is not a jump or a bark.
**Keep:** menu presses belong to the menu (a dustroom lesson).

**loretta.lua:17** `function slide(hero,dx,dy,climb)`
Moves a pixel at a time. On the ground (climb) a blocked step tries one pixel higher, which walks her up slopes. Going down, a branch's top row stops her only when her feet first reach it and she is not dropping.

**loretta.lua:33** `function update_loretta(hero,input)`
dustroom's ground run (start speed, accel, skid, friction), coyote time and jump buffer, hover gravity while rising with jump held. Down on the ground sits; down+jump on a branch only drops through it and spends the paddle (a held jump after a drop floated her back up). After a horizontal move on the ground, ground within 3px below pulls her down (vy=3), which keeps her on a slope going down.
**Keep:** paddling starts only when falling with jump held, once a jump; a stomp gives it back.

**loretta.lua:91** `hero.gait=(hero.gait+(ground and abs(hero.vx)/(2*leg_stride)`
gait is where she is in her trot (0..1). On the ground it advances by distance, one cycle every 2*leg_stride pixels, which is what keeps a planted paw still while her body moves over it; paddling advances it by time.
**Keep:** the divisor must match leg_pose's stance; test_moves fails if a planted paw slides 0.1px in a frame.

**loretta.lua:95** `function hurt_loretta(hero,from_x)`
Knockback away from what hurt her; at 0 hearts, game over at once.

**loretta.lua:111** `loretta_legs=split"9,0.5,2,4,6,22,0,2,6,6,4,0,3,9,7,17,0.5,3`
Four legs, five numbers each: hip column in the 32px picture, phase, width, colour, paw colour. Far back and far front first (drawn behind the torso), then near back and near front. Phases make a trot: near back with far front, far back with near front.

**loretta.lua:117** `function leg_pose(hero,hip,phase)`
A paw's offset from under its hip and how high it is lifted. Half the cycle it is planted, moving back exactly as fast as she moves forward; half it swings forward in an arc 2px high. The swing shrinks to nothing as she slows (gait_amp), so standing, her legs are straight. Jumping: front paws reach forward, back legs stretch behind.

**loretta.lua:125** `function draw_loretta(hero)`
She is built from parts, after witchcap's hut: far legs, the torso in two halves (the rump half rocks up and down against the chest once a cycle, the corgi-butt bounce), near legs, then the head. The body bobs up a pixel at mid-stride; the head bobs a little after it. Heads: ears back in the air, fast or on landing; tongue flapping in time with the trot; barking; a blink every three seconds standing. Sitting and napping are whole pictures.
**Keep:** the user called her body motion one of the most important things in the game; change it by watching the gait film strip (test_moves dumps gait_1..4).
