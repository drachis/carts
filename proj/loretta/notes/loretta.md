# loretta.lua

**loretta.lua:1** `function new_loretta(x,y)`
held starts at 63 (every button) so a press that started the game, or a respawn, is not a jump or a bark.
**Keep:** menu presses belong to the menu (a dustroom lesson).

**loretta.lua:17** `function slide(hero,dx,dy,climb)`
Moves a pixel at a time. On the ground (climb) a blocked step tries one pixel higher, which walks her up slopes. Going down, a branch's top row stops her only when her feet first reach it and she is not dropping.

**loretta.lua:33** `function update_loretta(hero,input)`
dustroom's ground run (start speed, accel, skid, friction), coyote time and jump buffer, hover gravity while rising with jump held. Down on the ground sits; down+jump on a branch only drops through it and spends the paddle (a held jump after a drop floated her back up). After a horizontal move on the ground, ground within 3px below pulls her down (vy=3), which keeps her on a slope going down.
**Keep:** paddling starts only when falling with jump held, once a jump; a stomp gives it back.

**loretta.lua:95** `function hurt_loretta(hero,from_x)`
Knockback away from what hurt her; at 0 hearts, game over at once.

**loretta.lua:119** `function draw_loretta(hero)`
32x16 poses (sprite numbers in loretta_sprites and here), drawn with sspr so landing squashes and jumping stretches, flipped facing left. Blinks while hurt.
