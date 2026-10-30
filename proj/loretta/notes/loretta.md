# loretta.lua

**loretta.lua:1** `function new_loretta(x,y)`
held starts at 63 (every button) so a press that started the game, or a respawn, is not a jump or a bark.
**Keep:** menu presses belong to the menu (a dustroom lesson).

**loretta.lua:20** `function slide(hero,dx,dy,climb)`
Moves a pixel at a time. On the ground (climb) a blocked step tries one pixel higher, which walks her up slopes. Going down, a branch's top row stops her only when her feet first reach it and she is not dropping.

**loretta.lua:36** `function update_loretta(hero,input)`
dustroom's ground run (start speed, accel, skid, friction), coyote time and jump buffer, hover gravity while rising with jump held. Down on the ground sits; down+jump on a branch only drops through it and spends the paddle (a held jump after a drop floated her back up). After a horizontal move on the ground, ground within 3px below pulls her down (vy=3), which keeps her on a slope going down.
**Keep:** paddling starts only when falling with jump held, once a jump; a stomp gives it back.

**loretta.lua:93** `hero.gait=(hero.gait+(ground and abs(hero.vx)/(2*leg_stride)`
gait is where she is in her trot (0..1). On the ground it advances by distance, one cycle every 2*leg_stride pixels, which is what keeps a planted paw still while her body moves over it; paddling advances it by time.
**Keep:** the divisor must match leg_pose's stance; test_moves fails if a planted paw slides 0.1px in a frame.

**loretta.lua:98** `function hurt_loretta(hero,from_x)`
Knockback away from what hurt her; at 0 hearts, game over at once.

**loretta.lua:114** `loretta_legs=split"0,-1,0.5,4,6,1,5,0,6,6,0,-3,0,9,7,1,3,0.5`
Four legs, five numbers each: hips (0) or chest (1), x from that joint, phase, upper colour, lower colour. Far legs first (drawn behind the body), then near. Phases make a trot: near back with far front, far back with near front.
**Keep:** the user asked for the legs at the front and back of the body, not from the middle: hind legs sit behind the pelvis, under the butt; front legs ahead of the chest point.
loretta_poses: her skeleton per state, nine numbers, x from the box's left and y from the ground: pelvis x, y; chest x, y; the head's centre from the chest; the belly's sag; where hind and front paws reach. animate_loretta eases hero.pose toward her state's. stand; sit (pelvis low, chest high: sitting pretty); sploot (idle long: everything low, belly to the ground, hind legs out behind, a corgi habit); nap (the same, eyes shut); jump and paddle (stretched long, legs reaching).
**Keep:** the user asked for her proportions and markings to follow their title picture (measured: about 36x26 px at PICO-8 scale, the head nearly half her length, a tricolour coat), for her to be thought of as character traits and body elements, and for her motion to be modelled "from the skeleton on up".

**loretta.lua:126** `function leg_pose(hero,front,phase)`
A paw's offset from under its joint and how high it is lifted. Half the cycle it is planted, moving back exactly as fast as she moves forward; half it swings forward in an arc 2px high. The swing shrinks to nothing as she slows (gait_amp), so standing, her legs are straight. Jumping: front paws reach forward, back legs stretch behind. Napping: front paws out ahead.

**loretta.lua:139** `function leg_place(hero,i)`
Where a leg's joint is (on the hips or shoulders) and its paw's pose. The test of planted paws uses this too, so it measures what is drawn.

**loretta.lua:163** `function follow(point,x,y,length,damp,gravity,pull_x,pull_y,pull)`
One verlet point hung from (x,y) at a fixed length: it keeps its own speed (damped), falls by gravity, is pulled toward a rest point, then is put back at its length. Ear tips and the tongue's links are these, so they lag behind her head, swing and settle.

**loretta.lua:174** `function animate_loretta(hero)`
Runs at the end of every update (and once in new_loretta), so drawing only reads. Eases the skeleton; the belly is a spring (belly_spring, belly_damp) toward the pose's sag, kicked by belly_bounce on landing; the head's bob follows the body's a little late. The head is a 2.5D volume, after witchcap's hut: hero.turn is the angle it faces (0 at the camera, head_turn three quarters to her side), eased at head_turn_speed, so turning round swings her head through a front view, and sitting she looks at you. Its centre is hero.hx, hy. Ears: each base sits at an angle round the skull (turn plus or minus 0.14), projected; each tip a follow point pulled to stand up, lean back when fast or in the air, and droop when lying or for ear_flop frames after landing. The tongue: five links from the mouth, the first held at the mouth, the rest hanging by follow.
**Keep:** the user asked for "floppy ears and a waggling tongue and a belly that flops to the ground when she lays down", ears' edges linked to the head, and a 2.5D head referencing witchcap's hut because the 3/4 face sprite's eyes "feel bad".

**loretta.lua:210** `function draw_ear(ear,colour,inner,outline)`
An ear is a triangle from two base points on the head to its tip, with a pink one inside; the outline is the triangle drawn four times a pixel off in black. The ear further round the skull (smaller depth) is drawn first, behind; the nearer one's outline goes with the body's outline pass and its fill after the fill, so no line crosses the head where it joins.

**loretta.lua:224** `function draw_loretta(hero)`
Her body is a soft skin round the skeleton: the butt, the torso along the spine, the sagging belly, chest and neck, and each near leg's two bones (a fat thigh or upper arm, a slim shank or forearm, by IK to the paw), all drawn as circles in one black outline pass and then one fill pass, so they merge into one silhouette and the skin seems to stretch round each leg as it swings. The head's skull, white lower face and muzzle join that same skin, placed by the turn (side=-sin(turn): 0 facing the camera, about 0.73 three quarters on); the muzzle juts out by side. Far legs are drawn first, alone. Then the saddle, the butt fluff, the blaze, collar and tag, the eyes (each at turn plus or minus 0.08 round the skull, hidden past the edge, one pixel wide when far round), the nose, mouth and tongue. The butt rocks once a trot cycle and wiggles while she is happy. Eyes: open with a glint, blinking, happy squint after a coin or a pat, shut napping. Mouth: smile at rest, panting with the tongue out moving or happy, open wide barking.
**Keep:** the user asked for legs "with 2 segments that look like they stretch the soft body around", "butt, body, shoulder, head, arms, forearms, no lines between", and called her body motion one of the most important things in the game; change it by watching the pictures test_poses and test_body dump (gait_1..6, pose_sploot, pose_sit, ears_landing).

**loretta.lua:145** `function body_bob(hero)`
The chest stays level while she trots (her legs scurry, her body glides); the butt lifts a pixel once a stride; landing drops the chest a pixel; taking off (squash below -2) lifts the chest and drops the butt, so she launches from her haunches. Two bobs a stride and a separate rump and head bob each toggled a pixel at up to 15 times a second, which read as jitter (test_motion).
**Keep:** at pixel scale, few slow coordinated moves; test_motion fails if her chest bobs while she trots.

**loretta.lua:159** `function wx(hero,x)`
Drawing positions: her parts in whole pixels, rounded from ex. Physics (ear tips, the tongue) runs in ex's unrounded positions: running it on rounded roots made the tips chase each pixel snap and turn back nearly every frame.

**loretta.lua:122** `function pitch(hero)`
In a jump her body pitches like a dog over a hurdle: rising, chest up and butt down, front paws tucked up, hind legs pushed out behind; falling, chest down, front paws reaching for the ground, hind legs tucked under (leg_pose); paddling stays level. From -vy, clamped to 1.
**Keep:** the user asked for her jumps to move like a dog over an agility hurdle, still a loaf of bread doing it.
