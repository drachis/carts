-- test_run.lua : headless soak test, included by test_run.p8 after the
-- game's modules. everything that can be checked without a world is in
-- test_data.p8 instead.
--
-- flies a scripted dragon through whole games for a few thousand frames,
-- starting a new game whenever one ends, and dumps one frame of play as
-- the picture "shot".
--
-- it runs inside pico-8's own loop, by wrapping the game's _update, as a
-- real game does. (an earlier version ran the whole soak as one long
-- stretch of top-level code calling _update and _draw itself; pico-8 has
-- to interrupt code like that to keep its own loop turning, and under
-- load it crashed with an access violation while drawing.)
--
-- the game is too close to 8192 tokens to share a cart with this file, so
-- test_run.p8 includes soak_main.lua in place of main.lua: a copy that
-- run_tests.py makes with the title and game-over screens stubbed out.
-- those screens are covered by test_title.p8 instead.

local held={}
function btn(i) return held[i] end
btnp=btn
function sfx() end
music=sfx
-- the scripted dragon's scores must not become the player's best
dset=sfx

-- where the scripted dragon heads: a boss if one is out, else the
-- nearest ward, then the goal
local function objective()
 if boss then return boss end
 local best,nearest=goal,32000
 for building in all(buildings) do
  local distance=dragon_distance(building.x,building.y)
  if building.home.wards>0 and building.ward and distance<nearest then
   best,nearest=building,distance
  end
 end
 return best
end

local n,game_frames,shot_saved=0,0
local game_update,game_draw=_update,_draw

-- every frame is drawn from _update below, so that none is skipped when
-- pico-8 falls behind
function _draw() end

function _update()
 n+=1
 -- head for the objective, breathing in bursts and charging now and then
 local target=objective()
 held[0],held[1]=target.x<dragon.x-8,target.x>dragon.x+8
 held[2],held[3]=target.y<dragon.y-8,target.y>dragon.y+8
 held[4]=n%90<60
 held[5]=n%50==0
 state="play"
 -- healed every frame, so only a single blow bigger than its whole
 -- health can kill it
 dragon.hp=dragon.max_hp
 game_update()
 game_draw()
 game_frames+=1

 -- a finished game is replaced with a fresh one, to stay under load
 if state!="play" then
  printh("game "..state.." after "..game_frames.." frames as a "..ages[age].name)
  game_frames=0
  new_game()
 end
 -- a screenshot of the first inferno
 if fury_time==200 and not shot_saved then
  shot_saved=true
  dump_screen("shot")
 end
 if n==4500 then
  printh("ok soak: "..wards.." wards, "..#buildings.."/"..#all_buildings.." buildings")
  extcmd("shutdown")
 end
end
