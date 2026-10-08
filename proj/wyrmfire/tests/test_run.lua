-- test_run.lua : headless soak test, included by test_run.p8 after the
-- game's modules. data checks live in test_data.p8.
--
-- flies a scripted, immortal dragon through whole games for a few thousand
-- frames of update+draw, starting a new game whenever one ends, then prints
-- stats, having dumped one frame to shot_fb.p8.
--
-- the whole game shares this cart's 8192 tokens, so this file must stay
-- small: as the game grows, trim here first.

local held={}
function btn(i) return held[i] end
function btnp(i) return held[i] end
function sfx() end
function music() end

-- where the scripted dragon heads: the nearest ward, then the goal
local function objective()
 local best,nearest=goal,32000
 for building in all(buildings) do
  local distance=dragon_distance(building.center_x,building.center_y)
  if building.spec.ward and building.home.wards>0 and distance<nearest then
   best,nearest=building,distance
  end
 end
 return best
end

_init()
assert(wards==3,"expected the three town churches to be the wards")
damage_building(goal,50)
assert(goal.hp==goal.spec.hp,"the goal was harmed through its ward")

-- the scripted run rarely razes a whole settlement, so spin the boon
-- reel by hand a good number of times
state="play"
for spin=1,20 do
 reel_time=config.reel_frames
 while reel_time>0 do update_reel() end
end
new_game()
state="play"

local max_units,max_combo,max_cpu,game_frames,shot_saved=0,0,0,0

for n=1,4500 do
 -- head for the objective, breathing in bursts and charging now and then
 local target=objective()
 local dx,dy=target.center_x-dragon.x,target.center_y-dragon.y
 held[0],held[1]=dx<-8,dx>8
 held[2],held[3]=dy<-8,dy>8
 held[4]=n%90<60
 held[5]=n%50==0

 _update()
 _draw()
 dragon.hp=max(dragon.hp,20)
 max_units=max(max_units,#units)
 max_combo=max(max_combo,combo)
 max_cpu=max(max_cpu,stat(1))
 game_frames+=1

 -- a finished game is replaced with a fresh one, to stay under load
 if state!="play" then
  printh("game "..state.." after "..game_frames.." frames as a "..ages[age].name
   .." score "..points(score).." kills "..kills.." wrath "..wrath)
  game_frames=0
  new_game()
  state="play"
 end

 -- screenshot mid-breath during the first inferno
 if fury_time>0 and fury_time<200 and held[4] and not shot_saved then
  shot_saved=true
  cstore(0,0x6000,0x2000,"shot_fb.p8")
 end
end

printh("ok soak: in play "..game_frames.." frames as a "..ages[age].name
 .." wards "..wards.." buildings "..#buildings.."/"..#all_buildings
 .." max units "..max_units.." max combo "..max_combo.." max cpu "..max_cpu)
extcmd("shutdown")
