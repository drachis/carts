# Code notes

The game's Lua modules carry no comments. PICO-8 counts every character of
source, comments included, against a limit of 65,535, and this cart needs that
room for code and data. Everything that would be a comment lives here instead.

Notes are filed by module, then by function or table, in the order they appear
in the file. A note about one line inside a function quotes that line, so
searching the module for the quoted text finds the place. When code changes,
change its note here in the same commit. `DESIGN.md` has the overall design,
the memory map and the rules of the build; this file is the detail.


## data.lua

data.lua : everything the game is tuned by.

a table constructor costs about three tokens per field; a string costs one however long it is. so all data lives in strings that are parsed once at boot, and adding a unit, building, legend or wrath level is a new line here rather than new code.

### `parse_table(text)`

lines of comma separated values. the first line names the fields and the first field is the row's name. rows are stored both in order and by name; empty cells are left nil.

a row is also a prototype: setmetatable(o,row) makes o read any field it has not set itself from the row. units, buildings, shots and settlements are made this way (see DESIGN.md).

### `parse_record(text,separator,into)`

lines of key=value (or one line, with another separator). a line with no "=" is skipped, so it can serve as a heading. the pairs go into a new table, or into `into` if one is given.

### `list(cell)`

a cell may hold a list: "a/b/c". an empty cell is an empty list.

### `named constants`

named constants. these are parsed straight into the global table (_ENV), so each is an ordinary global in the code: `tile_tree` costs one token where a field of a table, `tile.tree`, costs two.

tile_*: ground tile sprites. the burnt form of a tile is 16 ids later and its fuel is in its sprite flags (see gen_gfx.py and world.lua).

snd_*: sound effects, by their slot (see gen_gfx.py). snd_die and snd_eat are the first of three, one of which is picked at random.

the rest are tuning values.

### `ages`

the dragon's ages, from the whelp it starts as (dragon_stats) to a calamity. it grows by eating: every unit has a `meal` value, and sheep are by far the best. it comes of age when it has eaten that many meals' worth since the last age, and gains the stats listed, added to its own.

- size scales its whole body, its reach and its jaws.
- weight is heft: it shakes the ground with each wingbeat, crushes what it flies over, shrugs off blows, deepens its roar and makes the fearful flee at the sight of it.
- less accel and turn_rate with more friction is momentum: the same top speed, but slow to gather and slow to shed.

the three ages past calamity are for fun, for those who keep eating: bigger and deadlier still, but no heavier.

### `boons`

razing a settlement spins the reel and lands on one of these. each stat is added to the dragon's, for the rest of the game.

### `streaks`

called out when a combo reaches this many hits

### `body_shape`

the dragon's body before scaling: pairs of how far along the spine a circle sits and its radius, from haunches to snout

### `fury_stats`

laid over the dragon's stats while an inferno lasts. rage multiplies the breath's power (its reach, speed and damage), so an inferno is half as strong again whatever the dragon's age.

### `dragon_stats`

the dragon starts each game as a copy of this: a whelp. anything here can be changed in play (ages, boons, fury) without new code. flight is shmup-tight: top speed is accel/(1-friction), reached in a few frames. mercy is the frames of safety after a hit.

### `unit_specs`

ai names a function in unit_ai (units.lua). reload is the frames between its attacks. meal is the health the dragon gains when the unit dies. fire_taken scales breath damage; at or below `fireproof` a unit never ignites. ranged units hold at range and back off inside range*keep_away. color recolors the legend sprite's gold. the brave (1) stand against the dragon's roar and are too much to swallow in passing; the rest (0) flee from it and can be snapped up. a melee unit with a knock throws the dragon back that hard when it lands a blow. anything with a color is a named boss: it gets a health bar, and a fanfare when it falls.

### `shot_specs`

size 0 draws a streak, otherwise a ball of that radius. a lobbed shot ignores speed and lands on its target after `life` frames. fan is the angle between the shots of a volley. shots are slow enough to dodge, and come in two kinds: wooden ones (orange) burn up in the dragon's breath, holy ones (blue) do not.

### `building_specs`

tiles is its width in tiles. spawns is who answers the alarm, survivor who runs out burning when it falls, guardian the boss that rides out when it is badly hurt. razing a goal building wins the game. a ward building keeps every `warded` settlement (camelot) safe from all harm while it stands: the town churches are the spine of a run, the villages its side roads.

### `settlement_specs`

fixed buildings are kind:x:y offsets from the centre; the rest are scattered inside the radius. trees are cleared to `ground`. when the dragon first comes near, `militia` units drawn from `muster` turn out; razing every building pays the bounty. each wheat field has a `flock` of sheep. a warded (1) settlement cannot be harmed while any ward stands elsewhere.

### `realm`

the realm is a 3x3 grid of kind:name:hero settlements, read left to right, top to bottom. a settlement with a hero is under a dome until that hero, who comes out at the alarm, is slain. a legend's damage is set by how late it is met: its lunge does three times it, so arthur's 90 fells a whelp in one, a wyrm in two and a calamity in four.

### `wrath_levels`

wrath rises with score (kept in tens, so 200 here is 2000 on screen). each level has its own reinforcements and may send a legend. the last level is out of reach of score alone: it comes when the final ward breaks, and brings merlin.


## core.lua

core.lua : maths, particles and text shared by every module.

### `length(x,y)`

vector length, scaled so the squares stay inside 16.16 fixed point

### `dragon_distance(x,y)`

how far the dragon is from a point

### `angle_diff(a,b)`

signed shortest difference between two angles, in turns

### `print_centered(text,y,color)`

with no color the text flickers through the colors of fire

### `jolt(amount,stop)`

shake the screen and, for the big hits, freeze the game a moment

### `fire_ramp`

a fire particle's colors from dying to newborn, unless it carries a ramp of its own (the dragon's `flame` stat)

### `add_particle(x,y,vx,vy,life,kind,ember)`

kind is "fire", "smoke", "debris", "ring", "coin" or "text". embers ignite where they die. the particle is returned so the caller can add what its kind needs (size, text, sprite).

### `ring(x,y,size)`

an expanding shockwave

### `splat(x,y,color)`

a pop and a spatter: a ring, and six blobs of `color`. with no color it is blood (something was eaten, or the dragon was struck); a shot that strikes pops in its own color.

### `coins(x,y,count)`

gold that scatters, then flies to the dragon (see update_particles)

### `embers(x,y,count,speed)`

a wheel of embers that set light to wherever they land

### `update_particles()`

- at `local home=p.ember and frame%4==0 and dome_over(p.x,p.y)`: the dragon's flames are turned aside by a dome: slowed, and pushed out from its centre, so they slide off round it. (checked every few frames, which is plenty and much cheaper)
- at `if p.span-p.life>12 then`: after a moment it is drawn to where it belongs: a coin to the dragon, a meal (something eaten) to the sheep gauge in the corner of the screen, where it counts towards growth

### `draw_particles()`

- at `circfill(p.x,p.y,life/(p.ramp and 5/dragon.size or 6),(p.ramp or fire_ramp)[min(life\4+1,5)])`: white hot, cooling down its ramp of colors to smoke the dragon's own breath (it has a ramp) is drawn to its scale: a whelp's sparks, a calamity's gouts
- at `circfill(p.x,p.y,1,life%6<3 and 10 or 9)`: a coin blinks between gold and orange, with a white glint on top
- at `circfill(p.x,p.y,p.color and 1 or 0,p.color or life>8 and 6 or 4)`: debris is a speck of rubble, or given a color (blood) a blob


## world.lua

world.lua : the map, fire, buildings and world generation.

memory layout. the world is 64x64 tiles but the map is 128 wide, so the left half (x 0..63) holds ground sprites and the right half (x 64..127) holds one byte of state for the same tile:

- `0`: nothing
- `1..127`: burning, with this many fire visits left
- `128+id`: a building stands here (index into all_buildings)

no lua tables are needed for fires or occupancy, and neither has a cap. map rows 32..63 share memory with sprites 128..255, so only sprites 0..127 can be used for art.

**Section: fire**

### `ignite(tx,ty,by_chance)`

a tile's fuel is its sprite flags: high nibble is how many fire visits it burns for, low nibble its chance in 16 of catching from a neighbour. with `by_chance` the tile has to roll for it.

### `update_fire()`

fire is a cellular automaton over the state bytes. four rows are visited per frame, so every tile gets a visit each 16 frames: a burning tile tries to light a random neighbour, burns down one step, and at zero becomes its burnt sprite (16 ids later).

- at `if fget(mget(tx,ty))>=64 and rnd()<.25 then`: slow-burning ground (trees, wheat) sometimes pays as it goes

**Section: buildings**

### `place_building(kind,tx,ty,home)`

places a building with its top-left corner on a tile. returns nil if the footprint is off the map, occupied or over water. like a unit, a building inherits from its row of building_specs.

- at `size=size,`: in pixels; `tiles` is its width in tiles
- at `if spec.ward and home.warded==0 then`: a ward inside the warded city would guard itself forever

### `shielded(home)`

a settlement is under a dome, which nothing can harm and the dragon cannot enter, while its hero lives or (if it is warded) while any ward stands

### `dome_over(x,y)`

the settlement whose dome a point is under, if any. fire cannot reach in: breath does no harm there, nothing there can be lit, and flames are turned aside

### `damage_building(building,amount)`

- at `building.burn=0`: nor can anything under a dome burn
- at `coins(x,y,building.score\10+2)`: it pays out, and throws fire at its neighbours
- at `jolt(size/2,size/4)`: the bigger it was, the longer the world holds its breath
- at `coins(x,y,30)`: jackpot: a fountain of gold and a spin of the boon reel
- at `reinforce_timer=lull_frames`: and a rest: the realm reels before it sends anyone else
- at `announce("camelot's ward is broken!",150)`: the finale: nothing is held back any more

### `update_settlements()`

a settlement the dragon comes near sounds the alarm, once, and its militia turns out. while the dragon is at a standing settlement it is in `battle`, which quickens the reinforcements and the music; open country is the rest between.

- at `local distance,dome=dragon_distance(x,y),dome_radius(home)+dragon.size*11`: how near the dragon's middle can come with its head (11 pixels forward at size 1) still outside the dome
- at `dragon.x=x+(dragon.x-x)*dome/distance`: the dome throws the dragon back out, sparking and chiming where it is struck
- at `if home.hero then`: its hero comes out to meet the dragon; the dome is theirs
- at `if frame%150==0 then`: the flocks are slowly restocked: every five seconds, if fewer than `min_livestock` sheep, pigs and cows are alive, a sheep appears at the edge of a random farming settlement. so a dragon that has burnt or eaten every animal can still grow

### `update_buildings()`

- at `local harm=distance<dragon.size*6+size/2 and dragon.weight*.15 or 0`: what a heavy dragon flies over is crushed beneath it
- at `if frame%30==0 then coins(x,y,1) end`: a burning building drips gold for as long as it lasts
- at `local reach=building.tiles+2`: embers land on a neighbouring tile

**Section: world generation**

### `connect(from,to)`

an l-shaped road: along x first, then along y

### `build_settlement(settlement)`

- at `for field=1,settlement.fields do`: wheat fields, each with a sheep, just outside the settlement
- at `if fget(mget(x,y))>0 and tile_state(x,y)==0 then`: anything that burns can be ploughed under

### `generate_world()`

- at `memset(0x1000,0,0x2000)`: the map is two blocks of memory: rows 32..63 at 0x1000 (shared with the sprite sheet) then rows 0..31 at 0x2000. one memset clears every tile's state.
- at `for forest=1,18 do`: forests: ragged blobs of trees
- at `local cx,cy=7+flr(rnd(50)),flr(rnd(64))`: (kept clear of the map edge, so a blob cannot spill into the state bytes in the other half of the map)
- at `local river_base=rnd{19,40}`: the river meanders down one of the gaps between settlement columns
- at `add(settlements,setmetatable({`: a settlement inherits from its row of settlement_specs
- at `for i,settlement in ipairs(settlements) do`: roads to the east and south neighbours, before anything is built


## units.lua

units.lua : the realm's defenders, their behaviours and shots. a unit inherits from its row of unit_specs (`unit.speed` is read from the row), as a shot does from shot_specs. how a unit acts is the function in unit_ai that its `ai` names.

### `spawn_unit(kind,x,y,force)`

- at `cooldown=30+rnd(30),`: frames until it can next attack; `reload` is the wait between
- at `clock=flr(rnd(100)),`: where it is in its fighting cycle (see unit_ai.legend)
- at `push_x=0,`: knockback, which decays
- at `offset_x=rnd(16)-8,`: each unit aims a little off-centre so a mob surrounds the dragon

### `spawn_boss(kind,x,y)`

a boss gets a health bar and a herald

### `damage_unit(unit,amount,eaten)`

`eaten` is a kill by the dragon's jaws, which makes it a meal

- at `if unit.guards then unit.guards.hero=nil end`: a town's hero held its dome up
- at `eaten=true`: a named boss is a feast however it dies
- at `sfx(snd_eat+rnd(3))`: one of three crunches
- at `add(particles,{`: eating is how the dragon grows: the meal, now meat on the bone (sprite 74), is flung up and flies to the sheep gauge, counting when it gets there. (added directly, so that a full particle list cannot lose a meal.)
- at `sfx(snd_die+rnd(3))`: one of three cries

### `shoot(unit,dir_x,dir_y,kind)`

a unit with a volley looses that many shots, fanned by the shot's own spread. each shot inherits from its row of shot_specs.

- at `target_x=dragon.x+dragon.vx*25,`: lobbed shots lead the target; the landing spot is telegraphed

behaviours: each takes the unit, the unit direction to the dragon and its distance, and returns this frame's movement

### `unit_ai.melee(unit,dir_x,dir_y,distance)`

closes until it touches the dragon's body, and strikes from there

### `unit_ai.legend(unit,dir_x,dir_y,distance)`

a legend (or a lancer) fights in a cycle the dragon can learn:

- press   : close in and trade blows, loosing its shot if it has one
- guard   : stands behind a shield no fire can pass. charge it.
- gather  : flashes white, fixed on the dragon. get out of the way.
- strike  : a long lunge that does three times the harm

### `unit_ai.flee(unit,dir_x,dir_y)`

dragonfear: run from the dragon, at twice its usual pace, until the terror passes. (so a sheep flees more slowly than a soldier.)

### `unit_ai.panic(unit)`

anyone on fire runs about, spreading it

### `update_units()`

units do not stack. each claims the tile it stands on in a scratch grid in user memory (0x4300, a byte per tile); one that finds its tile taken is jostled off it. one peek per unit, with no pair checks and no pathing, however big the mob.

- at `distance=dragon_gap(unit.x,unit.y)`: units head for the dragon's middle, but how far away they are is measured to its skin, whichever part of it is nearest
- at `if unit.brave==0 and distance<dragon.weight*12 then`: a heavy dragon is dreadful just to be near

**Section: shots**

### `update_shots()`

- at `shot.vx+=(shot.target_x-shot.x)*.003`: a seeking shot is on a spring to the spot it was aimed at: a volley fans out, then closes in on that spot all at once
- at `struck=landed and dragon_gap(shot.target_x,shot.target_y)<8`: harmless in the air, a blast where it lands
- at `local distance=dragon_gap(shot.x,shot.y)`: a shot hits whatever part of the body it touches (not the wings). a near miss is a graze, which feeds the fury once per shot.
- at `if struck then splat(shot.x,shot.y,shot.color) end`: a shot that strikes pops where it hit, in its own color. (a lobbed shot has its own blast where it lands, so it is not in this branch.)

### `draw_shots()`

shots are drawn over everything, the dragon included

- at `circ(shot.target_x,shot.target_y,12-shot.age*10\shot.life,8)`: a closing ring marks where it will land, and the rock arcs over towards it
- at `if shot.size>0 then`: an orb with a dark rim, or a streak: easy to read at a glance


## dragon.lua

dragon.lua : the player. stats start from dragon_stats (data.lua); the body is drawn procedurally so it can face any direction.

### `tune_voice()`

the roar is five saw-wave notes in sfx memory (two bytes a note, the low byte being pitch plus the saw's 0x80). rewriting their pitch lower for each point of weight takes the dragon's voice from a whelp's yelp to something that shakes the hills. called for a new dragon and each time it grows. weight stops at 4, which is as low as the pitch goes.

### `roar(reach,frames)`

a roar is heard `reach` pixels away. everyone there who is not brave is struck with dragonfear and flees for a while.

### `grant(stats)`

add a record of stats to the dragon's own, for good: boons and growth. during an inferno the calm stats must gain them too.

### `belly_fill()`

how far the dragon has eaten towards its next age, 0 to 1. at the last age there is nothing left to grow into.

### `feed(meal)`

a meal reaches the gauge, which pops for a moment

### `grow()`

it has eaten enough: the dragon comes of age

### `damage_dragon(amount,dir_x,dir_y,knock)`

a heavy blow also has a direction and a `knock`, the distance it throws the dragon back along it

- at `if state!="play" or dragon.charge>0 or dragon.flash>0 then return end`: nothing touches a charging dragon, or one still reeling from the last blow (flash doubles as its moment of invulnerability)
- at `knock*=1-dragon.friction`: knock is how many pixels the dragon is thrown: sliding to a stop under friction f covers its starting speed over 1-f
- at `jolt(2+amount/8,amount\12)`: the harder the blow, the harder the screen is shaken and the longer the game holds on it: a pinprick passes, a lunge lands
- at `poke(0x3201+snd_hurt*68,0x50+mid(2,amount\3+1,7)*2)`: and the louder it sounds: the hurt sfx is one fading note whose second byte is 0x50 plus twice its volume, rewritten for each blow. a really heavy one has a crash under it too.
- at `dragon.hp=0`: it dies in a storm of its own fire, with a last roar, and then (see _update) spins away to nothing

### `update_tail()`

each tail segment is dragged a fixed distance behind the last

### `update_body()`

the dragon's body is a list of circles: five along the spine from haunches to snout (body_shape in data.lua), then the tail. it is rebuilt each frame and is both what is drawn and what can be hit, so the two always agree.

### `dragon_gap(x,y)`

how far a point is from the dragon's skin: zero or less is a touch. far-off points skip the per-circle test.

### `in_breath(x,y,mouth_x,mouth_y,radius)`

is a target of this radius inside the cone of fire?

### `breathe_fire(mouth_x,mouth_y)`

a breath is one long exhale: fiercest and longest-reaching on full lungs, guttering as they empty. once empty the dragon is winded and must let go of the button to breathe in.

- at `d.exhaling=true`: the first gasp is a blast that kicks the dragon back, harder the fuller its lungs and the greater its age
- at `d.vx-=cos(d.angle)*d.recoil*power`: it pushes the dragon back
- at `if frame%4!=0 then return end`: the flames are for show; damage is a cone test every few frames
- at `for shot in all(shots) do`: shots that can burn are eaten by the flames, and feed the fury
- at `if frame%12==0 then`: a raised guard throws the fire back, and sprays it aside

### `boost_dragon(stats)`

lay a record of stats over the dragon's own, returning what they replaced so the change can be undone the same way

### `inferno()`

spend a full fury meter: a nova of fire, then a spell as a greater dragon (fury_stats in data.lua)

### `charge_impacts(head_x,head_y)`

while charging the head is a battering ram. each charge has an id so it hits a given target only once.

- at `unit.push_x,unit.push_y=d.vx,d.vy`: whatever survives the jaws is thrown back
- at `d.charge=min(d.charge,3)`: hitting a wall ends the charge

### `update_dragon()`

- at `local input_x=tonum(btn(1))-tonum(btn(0))`: buttons 0..3 are left, right, up, down; tonum makes each 1 or 0
- at `if frame%32==0 then`: each wingbeat sounds, and a heavy dragon's shakes the ground
- at `if not btn(4) then d.winded=false end`: button 4 (z) breathes, button 5 (x) charges
- at `add_particle(tail[3].x,tail[3].y,0,0,8,"fire")`: a charge leaves a trail of fire behind it
- at `local target=(input_x!=0 or input_y!=0) and atan2(input_x,input_y)`: the dragon turns to face the way it flies, except mid-charge, and while breathing: then its aim is locked and it strafes
- at `d.windup-=1`: coil back for a moment, then burst forward
- at `if btn(4) and fury>=100 then inferno() end`: charging with the fire held and fury full is an inferno
- at `d.snap-=1`: jaws: whatever is not brave and passes under the head is snapped up, a mouthful at a time
- at `d.fire=min(d.max_fire,d.fire+d.fire_regen+(d.max_fire-d.fire)*d.inhale)`: breathe in: a deep gulp at first, slowing as the lungs fill
- at `local angle=rnd()`: air is drawn in to the mouth
- at `if d.hp<d.max_hp/3 and frame%3==0 then`: close to death it trails smoke

### `draw_dragon()`

- at `local size=d.size`: the forward and sideways vectors are scaled by the dragon's size, so every offset below grows with it; radii are scaled one by one
- at `local flap=charging and -1 or d.windup>0 and 1 or sin(frame/16)`: wings swept back in a charge, raised high while coiling for one
- at `local drop=charging and 2 or 7`: shadow: far below when soaring, tight when diving
- at `local hurt=d.flash%4>1`: drawn in red and purple, then recoloured. it blinks white while it cannot be hurt.
- at `for i=#body,6,-1 do`: the tail, tip first (body[6] onwards)
- at `local span,sweep=13+flap*3,3-flap*2`: wing: a fan of lines from the shoulder makes the membrane, then three bones over it
- at `line(`: horn
- at `for i=1,5 do`: haunches, chest, neck, head, snout


## main.lua

main.lua : game states, scoring, the wrath director, hud and main loop. state is "title", "play", "dead" or "won".

### `update_music()`

there are two tracks (see gen_gfx.py), both kept to channels 0 and 1 so two are left for effects. the battle track plays while the dragon is fighting at a settlement and for a few seconds after (this runs once a second); the roaming track the rest of the time.

### `multiplier()`

one more for every combo_step hits in a row

### `points(tens)`

pico-8 numbers stop at 32767, so score is kept in tens and shown with a zero on the end: room for 327,670 points

### `add_fury(amount)`

fury fills from score, coins, grazes and burnt shots, but not while an inferno is spending it

- at `announce("fury is full! \142+\151",120)`: make sure the moment it fills is not missed

### `add_score(worth,x,y)`

every kill and ruin goes through here. hits in quick succession build a combo that multiplies the score and feeds the fury meter.

- at `if gained>=100 then`: only the bigger prizes are spelled out, to keep the screen clear

### `collect_coin()`

a coin reaching the dragon: a little score, and it keeps the combo alive, so a realm left burning keeps the streak cooking. each ding is a note higher than the last: the coin sfx's first byte is its pitch, poked just before it plays.

### `update_reel()`

the boon reel: flicker through the boons, then land on one

### `update_wrath()`

the more you burn, the harder the realm pushes back

- at `local angle=rnd()`: newcomers arrive from just off screen
- at `if not boss and heralded<wrath then`: each level's legend is heralded once, one boss at a time
- at `reinforce_timer-=battle and battle_rush or 1`: reinforcements pour in during a battle and thin out between

### `draw_gauge(glyph,x,fraction,color,back)`

a gauge in the top bar: a column that fills from the bottom, marked with a glyph from the pico-8 font

### `draw_compass()`

a dial in the top bar whose needle points to the next step of the run: the nearest settlement whose ward still stands (blue), and once none do, the goal itself (gold)

### `draw_blaze()`

flames lick in from the screen edges when things are going well, in the colors of the dragon's own breath

### `draw_hud()`

one bar along the top: four gauges that fill upwards (heart: health, spark: fire, star: fury, sheep: growth), the score and multiplier, the wards left, and the compass. a boss has a bar of its own along the bottom.

- at `local low=dragon.hp<dragon.max_hp/3`: under a third of its health the dragon is close to death
- at `rect(0,10,127,127,8)`: a red frame beats round the screen then
- at `draw_gauge(135,0,dragon.hp/dragon.max_hp,low and blink and 7 or 8,2)`: the heart flashes white when health is low
- at `draw_gauge(146,20,fury/100,fury<100 and 10 or blink and 7 or 12,5)`: a full fury gauge flashes blue and white, the inferno's colors
- at `belly_pop-=1`: eat to fill the column behind the sheep, and grow. it flashes and sparkles as each meal lands.
- at `print(points(shown_score),43,2,shown_score<flr(score) and 10 or 7)`: the score rolls up to its true value like a payout counter
- at `print("x"..multiplier(),76,2,blink and 10 or 9)`: the multiplier and how long is left to keep the combo going
- at `for ward=1,wards do`: a dome for each ward still standing
- at `rectfill(0,121,127,127,2)`: a bar along the bottom with the boss's name on it

### `draw_title()`

a panel over the top of the screen, in reading order: title, what to do, best score, how to grow, controls. the strip left clear below it shows the whelp circling its lair, with how to start flashing over it. the controls are written with the font's own button glyphs (\139 \145 \148 \131 are the arrows, \142 is o/z, \151 is x), each as a command. buttons and commands are two columns, each one print, so they line up whatever the glyphs' widths.

- at `local y=27`: the best score takes a line only once there is one, so the lines below close up when there is not
- at `print("eat",27,y+2,11)`: "eat (sheep, pig, cow) to grow", the animals as their sprites

### `_update()`

- at `if freeze>0 then`: hit-stop: big impacts hold the frame for a moment
- at `local turn=frame/240`: the whelp flies a lazy oval over its lair while it waits, flat enough to stay inside the strip under the title panel
- at `if state=="dead" then`: for two seconds the ending is left to play out: a dragon that has died spins away to nothing

### `_draw()`

- at `flash-=1`: a white frame for the biggest moments
- at `local lead=dragon.breath_range/2`: the camera eases towards a point ahead of the dragon's nose, so there is always room to see what it is aiming at (half its breath's reach ahead, so the view opens up as it grows)
- at `if state=="title" then`: on the title screen the view is fixed on the lair and lowered, so the dragon's oval sits in the strip beneath the panel
- at `draw_units()`: the dragon flies over everyone; only shots are drawn above it
