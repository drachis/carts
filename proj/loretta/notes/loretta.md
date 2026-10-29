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

**loretta.lua:111** `loretta_legs=split"0,3,0.5,4,6,1,3,0,4,6,0,0,0,9,7,1,0,0.5,7`
Four legs, five numbers each: which end of the spine (0 hips, 1 shoulders), an x offset from it, phase, upper colour, lower (sock) colour. Far legs first (drawn behind the body), then near. Phases make a trot: near back with far front, far back with near front.
body_poses: where the hips and shoulders sit (x, y in the 32x16 box) and how far the head drops, standing, sitting and napping. The drawing eases hero.body toward the pose of her state, so she sits down and lies down rather than snapping.
**Keep:** the user asked for her proportions to follow their title picture: a big head about two fifths of her length on a round loaf of a body, short thick legs.

**loretta.lua:118** `function leg_pose(hero,front,phase)`
A paw's offset from under its joint and how high it is lifted. Half the cycle it is planted, moving back exactly as fast as she moves forward; half it swings forward in an arc 2px high. The swing shrinks to nothing as she slows (gait_amp), so standing, her legs are straight. Jumping: front paws reach forward, back legs stretch behind. Napping: front paws out ahead.

**loretta.lua:127** `function leg_place(hero,i)`
Where a leg's joint is (on the hips or shoulders) and its paw's pose. The test of planted paws uses this too, so it measures what is drawn.

**loretta.lua:133** `function draw_loretta(hero)`
A quadruped rig, as the user asked ("multi segment like a long dog body ... in quadruped ik"), after witchcap's hut: a butt, a body and a shoulder (round segments, with a blended circle between each pair so the back is one smooth line), a white chest, and the head; four legs, each two bones of leg_bone (arm and forearm, thigh and shank) worked out by IK from its joint to its paw (hind knees bend back, front ones forward), drawn solid as rows of circles. Every outline (the segments' and the near legs') is drawn before any fill, and the head has no outline where it sits on the shoulder, so no line shows between her parts.
**Keep:** the user asked for "butt, body, shoulder, head, arms, forearms, no lines between the shoulder and the body". The rump end of the spine rocks against the shoulders once a cycle and the body bobs at mid-stride, so the body bends. The head sprite rides on the shoulders and bobs a little after them. Heads: ears back in the air, fast or on landing; tongue flapping in time; barking; eyes shut napping; a blink every three seconds.
**Keep:** the user called her body motion one of the most important things in the game; change it by watching the gait film strip (test_moves dumps gait_1..4).
