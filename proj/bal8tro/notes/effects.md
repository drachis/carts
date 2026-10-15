# effects.lua

The VFX engine, asked for by the user so that juice is a line of data or one call rather than new code each time. Particles come from presets (vfx_specs in data.lua); things (cards, jokers) carry their own kick and flip; timers, hitstop and flash are global.

**effects.lua:1** `particles,timers,shake,freeze,flash_frames,chips_bump,mult_bump,heat={},{},0,0,0,0,0,0`
All the engine's state. shake is pixels of screen shake; freeze is frames of hitstop left; flash_frames frames of white flash left; chips_bump and mult_bump how far the boxes are swollen; heat see fan_flames.

**effects.lua:3** `function emit(name,x,y,colour,amount)`
Throws a preset's particles from x,y (spread over its width): count of them unless amount is given, each a random direction and speed up to speed, pushed up by rise, falling by gravity, living half to all of life. colour is for presets without a ramp; those grey out in their last 6 frames.

**effects.lua:16** `function kick(thing,amount)`
Balatro's juice_up on any card or joker drawn through glide (its source, engine/moveable.lua: a 0.4s pulse, the size swinging as sin(50.8t) fading cubically, a tilt as sin(40.8t) fading squarely). amount is the swell in pixels at its biggest: about 2 for a scoring card (Balatro's 11% of a card), 3-4 for a joker. A new kick restarts the pulse.
Keep: tests/test_shop.lua checks it swells past 2px, shrinks back past -1px and settles after juice_frames.
**effects.lua:20** `function after(frames,action)`
Calls action once, frames updates from now. Timers count in update_effects, so a hitstop holds them too.

**effects.lua:24** `function hitstop(frames)`
Freezes the game's update (and so the particles and timers) for frames, while it keeps drawing. A shorter hitstop never cuts a longer one.
Keep: tests/test_hands.lua checks emit, after, kick and hitstop.

**effects.lua:28** `function jiggle(thing)`
Advances a kicked thing's pulse a frame (glide calls it, once a frame per drawn thing): sets thing.swell (the size change, starting with growth: PICO-8's sin is inverted, so it is negated to grow first like Balatro's) and returns a sideways sway (x only) standing in for Balatro's tilt, since a card cannot rotate at this size. 0 when no pulse is running.

**effects.lua:38** `function flame_band(left,right,base,height)`
A row of flickering two-pixel flame columns, red, orange and a yellow root, each up to height tall: every fire on screen is one.

**effects.lua:47** `function draw_flames()`
While heat is 1 or more, a band along the top of both boxes, taller with heat (up to 10px at heat 4). Drawn before the boxes so it licks up from behind them.

**effects.lua:52** `function draw_floor_fire()`
The user asked that more of the screen catch fire the further a hand beats the goal. At heat 2 the bottom of the sidebar burns (and draw_sidebar flickers its edge in fire colours); at 3 the whole bottom of the screen. Drawn over the table, under the particles.

**effects.lua:56** `function fan_flames()`
heat is how many times the blind's goal the hand on screen (chips x mult) is worth, while a hand is scoring: Balatro lights its flames from the hand alone, not score plus hand (checked in its source, button_callbacks.lua flame_handler). It jumps up at once and dies down by 4% a frame. At 1 or more each box emits min(heat,4) flame particles a frame; at 4 embers rise across the whole bottom too.
Keep: tests/test_boot.lua checks the scripted pair of kings has no flames at 30x6 and flames at 80x6 against a goal of 300, and that a hand of 5x the goal sets the floor alight.

**effects.lua:84** `function draw_swirl(base,stripes,top)`
The moving background, standing in for Balatro's swirl: a rectfill of base (not cls, which ignores pal, so the end screens' tint reaches the felt), then from row top down, 16px dithered stripes every 32px, offset per row by a slow sine plus a drift, so they wave and slide. The table uses green with dark blue, the title dark blue with purple, the shop dark blue with black.
Keep: stripes is one colour. fillp(▒) leaves its other pixels transparent (observed; the manual documents the transparency bit, not the glyph patterns), so only the low digit of a two-colour value draws, and 0x13 on green drew nothing.

**effects.lua:95** `function shake_camera()`
Offsets the camera by up to shake pixels for the table only; _draw resets it before the banners.
Keep: the sidebar is drawn 8px past the screen's edges so a shake never shows the felt.

**effects.lua:99** `function draw_particles()`
Each particle is a short streak along its motion, so it reads at 128x128, coloured down its preset's ramp as it ages (hottest last in the ramp). The flash is drawn here too, a dithered white over the right side, last of all.

**effects.lua:113** `function panel_at(y)`
A new sliding panel, resting at y until glide moves it (draw.lua slide). Here, not in draw.lua, because open_shop calls it and the rules carts have no draw.lua.
Keep: tests/test_tarots.p8 and the other rules carts include no draw.lua.
