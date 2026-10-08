-- test_run.lua : headless soak test, included by test_run.p8 after the
-- game's modules.
--
-- flies a scripted, immortal dragon at the goal for a few thousand frames
-- of update+draw, checks the data parsed, prints stats, dumps one frame
-- to shot_fb.p8 and exits.

local soak_frames=2400
local screen_address,screen_bytes=0x6000,0x2000

local held={}
function btn(i) return held[i] end
function btnp(i) return held[i] end
function sfx() end
function music() end

local function burning_tiles()
 local count=0
 for ty=0,63 do
  for tx=0,63 do
   if burning_at(tx,ty) then count+=1 end
  end
 end
 return count
end

-- every name the data refers to must exist
for spec in all(unit_specs) do
 assert(unit_ai[spec.ai],"no ai for "..spec.name)
 assert(not spec.shot or shot_specs[spec.shot],"no shot for "..spec.name)
end
for spec in all(building_specs) do
 for kind in all(list(spec.spawns)) do
  assert(unit_specs[kind],spec.name.." spawns unknown "..kind)
 end
end
for level in all(wrath_levels) do
 for kind in all(list(level.pool)) do
  assert(unit_specs[kind],level.name.." sends unknown "..kind)
 end
 assert(not level.legend or unit_specs[level.legend],"unknown legend")
end
for spec in all(settlement_specs) do
 for kind in all(list(spec.muster)) do
  assert(unit_specs[kind],spec.name.." musters unknown "..kind)
 end
end
for entry in all(realm) do
 assert(settlement_specs[split(entry,":")[1]],"unknown settlement "..entry)
end

_init()
assert(goal,"the realm has no goal building")
for boon in all(boons) do
 for key in pairs(parse_record(boon.stats,"/")) do
  assert(dragon[key],boon.name.." boosts unknown stat "..key)
 end
end
state="play"

-- the scripted run rarely razes a whole settlement, so spin the boon
-- reel by hand until it has landed a good number of times
local hp_before=dragon.max_hp
for spin=1,40 do
 reel_time=config.reel_frames
 while reel_time>0 do update_reel() end
end
assert(dragon.max_hp>hp_before,"forty spins never landed on iron scales")
new_game()
state="play"

local max_units,max_particles,max_burning,max_combo,infernos=0,0,0,0,0
local spins,coins_banked,feared,frames_played=0,0,0,0
local games_won,game_frames=0,0
-- burnt shots and grazes are told apart by the fury they give
local shots_burnt,grazes=0,0
local real_add_fury=add_fury
function add_fury(amount)
 if amount==3 then shots_burnt+=1 end
 if amount==2 then grazes+=1 end
 real_add_fury(amount)
end
local roars=0
local real_roar=roar
function roar(reach,frames)
 roars+=1
 real_roar(reach,frames)
end
local real_collect_coin=collect_coin
function collect_coin()
 coins_banked+=1
 real_collect_coin()
end
local shot_saved=false

for n=1,soak_frames do
 -- head for the goal, breathing in bursts and charging now and then
 local dx,dy=goal.center_x-dragon.x,goal.center_y-dragon.y
 local playing=state=="play"
 held[0],held[1]=dx<-8,dx>8
 held[2],held[3]=dy<-8,dy>8
 held[4]=playing and n%90<60
 held[5]=playing and n%50==0

 _update()
 _draw()
 dragon.hp=max(dragon.hp,50)

 max_units=max(max_units,#units)
 max_particles=max(max_particles,#particles)
 max_combo=max(max_combo,combo)
 if fury_time==config.fury_frames-1 then infernos+=1 end
 if reel_time==1 then spins+=1 end
 -- a finished game is replaced with a fresh one, to stay under load
 if not playing then
  games_won+=state=="won" and 1 or 0
  printh("game over: "..state.." after "..game_frames.." frames, size "..dragon.size)
  game_frames=0
  new_game()
  state="play"
 else
  game_frames+=1
  frames_played+=1
  for unit in all(units) do
   if unit.fear>0 then feared+=1 break end
  end
 end
 if n%30==0 then
  max_burning=max(max_burning,burning_tiles())
 end

 -- screenshot mid-breath during the first inferno
 local mid_breath=held[4] and n%90>20
 if fury_time>0 and fury_time<200 and not shot_saved and mid_breath then
  shot_saved=true
  cstore(0,screen_address,screen_bytes,"shot_fb.p8")
 end
end

printh("ok state="..state.." score="..score.." kills="..kills
 .." wrath="..wrath.." heralded="..heralded)
printh("buildings "..#buildings.."/"..#all_buildings
 .." max units="..max_units.." particles="..max_particles
 .." burning tiles="..max_burning)
printh("max combo="..max_combo.." infernos="..infernos
 .." reel spins="..spins.." coins banked="..coins_banked)
printh("shots burnt="..shots_burnt.." grazes="..grazes
 .." frames with fear="..feared.."/"..frames_played.." roars="..roars
 .." dragon size="..dragon.size)
extcmd("shutdown")
