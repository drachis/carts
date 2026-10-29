# loretta.lua

**loretta.lua:1** `function new_loretta(x,y)`
held starts at 63 (every button) so a press that started the game, or a respawn, is not a jump or a bark.
**Keep:** menu presses belong to the menu (a dustroom lesson).

**loretta.lua:17** `function slide(hero,dx,dy,climb)`
Moves a pixel at a time. On the ground (climb) a blocked step tries one pixel higher, which walks her up slopes. Going down, a branch's top row stops her only when her feet first reach it and she is not dropping.

**loretta.lua:33** `function update_loretta(hero,input)`
dustroom's ground run (start speed, accel, skid, friction), coyote time and jump buffer, hover gravity while rising with jump held. Down on the ground sits; down+jump on a branch only drops through it and spends the paddle (a held jump after a drop floated her back up). After a horizontal move on the ground, ground within 3px below pulls her down (vy=3), which keeps her on a slope going down.
**Keep:** paddling starts only when falling with jump held, once a jump; a stomp gives it back.

**loretta.lua:92** `hero.gait=(hero.gait+(ground and abs(hero.vx)/(2*leg_stride)`
gait is where she is in her trot (0..1). On the ground it advances by distance, one cycle every 2*leg_stride pixels, which is what keeps a planted paw still while her body moves over it; paddling advances it by time.
**Keep:** the divisor must match leg_pose's stance; test_moves fails if a planted paw slides 0.1px in a frame.

**loretta.lua:96** `function hurt_loretta(hero,from_x)`
Knockback away from what hurt her; at 0 hearts, game over at once.

**loretta.lua:112** `loretta_legs=split"0,9,0.5,4,6,1,22,0,6,6,0,6,0,9,7,1,19,0.5`
Four legs, five numbers each: rear (0) or front (1), the joint's column in the body picture, phase, upper colour, sock colour. Far legs first (drawn behind the body), then near. Phases make a trot: near back with far front, far back with near front.
loretta_poses, per state, eased into by the drawing (hero.pose): how far her body drops, how far her head drops, where the hind and front paws reach, and how far the front legs move back (sitting). sploot (idle long): belly down, hind legs stretched out behind, a corgi habit; nap: the same with eyes shut; sit: the sit-pretty body.
**Keep:** the user asked for her proportions and markings to follow their title picture (measured: about 36x26 px at PICO-8 scale, the head nearly half her length, a tricolour coat) and for her to be thought of as character traits and body elements, not pixels (corgi_art.py lists them).

**loretta.lua:119** `function leg_pose(hero,front,phase)`
A paw's offset from under its joint and how high it is lifted. Half the cycle it is planted, moving back exactly as fast as she moves forward; half it swings forward in an arc 2px high. The swing shrinks to nothing as she slows (gait_amp), so standing, her legs are straight. Jumping: front paws reach forward, back legs stretch behind. Napping: front paws out ahead.

**loretta.lua:128** `function leg_place(hero,i)`
Where a leg's joint is (on the hips or shoulders) and its paw's pose. The test of planted paws uses this too, so it measures what is drawn.

**loretta.lua:134** `function draw_loretta(hero)`
She is drawn from parts made by corgi_art.py (sprites with 12 as their transparent colour, since her outline is black 0): the far ear, the far legs, the body cut in two (the rear piece columns 0..15, the front 12..27, outlined as one picture so the seam has no line), the near legs, the face, the near ear, then eyes and mouth in code. The rear piece rocks once a trot cycle (the corgi butt) and shifts side to side while she is happy (the wiggle); the body bobs at mid-stride. Legs are two bones of leg_bone (arm and forearm, thigh and shank) by IK to the paw, drawn as rows of circles with a black outline. Ears: up, swept back rising or fast, flopped landing or lying down. Eyes: open with a glint, blinking, happy squint (^) after a coin or a pat, shut napping. Mouth: smile at rest, panting with the tongue out moving or happy, open wide barking.
**Keep:** the user asked for "butt, body, shoulder, head, arms, forearms, no lines between the shoulder and the body", and the parts drawn in the character of a corgi.
**Keep:** the user called her body motion one of the most important things in the game; change it by watching the gait film strip (test_moves dumps gait_1..4).
