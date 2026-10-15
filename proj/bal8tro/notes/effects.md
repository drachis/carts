# effects.lua

The VFX engine, asked for by the user so that juice is a line of data or one call rather than new code each time. Particles come from presets (vfx_specs in data.lua); things (cards, jokers) carry their own kick and flip; timers, hitstop and flash are global.

**effects.lua:1** `particles,timers,shake,freeze,flash_frames,chips_bump,mult_bump,heat={},{},0,0,0,0,0,0`
All the engine's state. shake is pixels of screen shake; freeze is frames of hitstop left; flash_frames frames of white flash left; chips_bump and mult_bump how far the boxes are swollen; heat see fan_flames.

**effects.lua:3** `function emit(name,x,y,colour,amount)`
Throws a preset's particles from x,y (spread over its width): count of them unless amount is given, each a random direction and speed up to speed, pushed up by rise, falling by gravity, living half to all of life. colour is for presets without a ramp; those grey out in their last 6 frames.

**effects.lua:16** `function kick(thing,amount)`
Starts a shake-and-lift on any thing that is drawn through glide (cards, jokers). It decays by a fifth a frame in jiggle, which glide calls, so nothing else needs updating. A bigger kick replaces a smaller one, never the reverse.

**effects.lua:20** `function turn_over(card)`
Turns a card over: draw_card narrows it with clip to its centre through zero and back over 16 frames, showing the back for the first half and the face for the second.
Keep: never name a global flip. It replaced PICO-8's own flip(), and the cart stopped after its first frame with no error.

**effects.lua:24** `function after(frames,action)`
Calls action once, frames updates from now. Timers count in update_effects, so a hitstop holds them too.

**effects.lua:28** `function hitstop(frames)`
Freezes the game's update (and so the particles and timers) for frames, while it keeps drawing. A shorter hitstop never cuts a longer one.
Keep: tests/test_hands.lua checks emit, after, kick and hitstop.

**effects.lua:42** `function flame_band(left,right,base,height)`
A row of flickering two-pixel flame columns, red, orange and a yellow root, each up to height tall: every fire on screen is one.

**effects.lua:51** `function draw_flames()`
While heat is 1 or more, a band along the top of both boxes, taller with heat (up to 10px at heat 4). Drawn before the boxes so it licks up from behind them.

**effects.lua:56** `function draw_floor_fire()`
The user asked that more of the screen catch fire the further a hand beats the goal. At heat 2 the bottom of the sidebar burns (and draw_sidebar flickers its edge in fire colours); at 3 the whole bottom of the screen. Drawn over the table, under the particles.

**effects.lua:60** `function fan_flames()`
heat is how many times the blind's goal the hand on screen (chips x mult) is worth, while a hand is scoring: Balatro lights its flames from the hand alone, not score plus hand (checked in its source, button_callbacks.lua flame_handler). It jumps up at once and dies down by 4% a frame. At 1 or more each box emits min(heat,4) flame particles a frame; at 4 embers rise across the whole bottom too.
Keep: tests/test_boot.lua checks the scripted pair of kings has no flames at 30x6 and flames at 80x6 against a goal of 300, and that a hand of 5x the goal sets the floor alight.

**effects.lua:88** `function draw_swirl(base,stripes,top)`
The moving background, standing in for Balatro's swirl: cls to base, then from row top down, 16px dithered stripes every 32px, offset per row by a slow sine plus a drift, so they wave and slide. The table uses green with dark blue, the title dark blue with purple, the shop dark blue with black.
Keep: stripes is one colour. fillp(▒) leaves its other pixels transparent (observed; the manual documents the transparency bit, not the glyph patterns), so only the low digit of a two-colour value draws, and 0x13 on green drew nothing.

**effects.lua:99** `function shake_camera()`
Offsets the camera by up to shake pixels for the table only; _draw resets it before the banners.
Keep: the sidebar is drawn 8px past the screen's edges so a shake never shows the felt.

**effects.lua:103** `function draw_particles()`
Each particle is a short streak along its motion, so it reads at 128x128, coloured down its preset's ramp as it ages (hottest last in the ramp). The flash is drawn here too, a dithered white over the right side, last of all.
