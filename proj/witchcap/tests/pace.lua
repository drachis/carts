-- pace.lua : how long a run takes. not a test: it prints measurements.
-- run it with: py run_tests.py tests/pace.p8
--
-- a bot plays whole runs with the clock held open at three minutes, and
-- the time it takes to brew is printed for each forest. the bot knows
-- which mushrooms the recipe wants, never picks a lookalike, goes to the
-- nearest wanted one first and to the pot when it has all five.
--
-- every level is played by a bot that stands still for `read_frames` at
-- every mushroom it comes within reach of, wanted or not, which is a
-- guess at what telling them apart costs a person. the last level is
-- also played with the broom and without stopping to read. the bot does
-- not get lost, hesitate or go back for a spoiled mushroom, so a person
-- will be slower than any of these. the levels' pars in data.lua are
-- set from the first nine lines this prints.
--
-- sixteen frames of the game are played for each frame pico-8 shows, and
-- nothing is drawn.

function music() end
function sfx() end
dset=sfx

local held={}
function btn(i) return held[i] or false end
btnp=btn

local game_update=_update60
function _draw() end

level_seconds=180
local seeds=4
-- every level, on foot, stopping 3/4 of a second at each mushroom; and
-- the last level the three other ways, for comparison
local ways={}
for number=1,9 do
 add(ways,{name="level "..number.." on foot, 3/4 second a mushroom",read_frames=45,level=number})
end
add(ways,{name="level 9 with the broom, 3/4 second a mushroom",read_frames=45,broom=true,level=9})
add(ways,{name="level 9 on foot, reading at a glance",read_frames=0,level=9})
add(ways,{name="level 9 with the broom, reading at a glance",read_frames=0,broom=true,level=9})
local way_number,seed,times=1,0,{}
local read,pause,still,last_x

local function begin()
 seed+=1
 level=ways[way_number].level
 make_forest(seed)
 reset_witch()
 reset_hut()
 reset_effects()
 frames_left,mode=level_seconds*60,"play"
 read,pause,still,last_x={},0,0,witch.x
end

-- the nearest mushroom the recipe still wants, or the pot when it wants
-- no more
local function target()
 local best,best_distance
 for mushroom in all(mushrooms) do
  local distance=abs(near(mushroom.x)-witch.x)
  if slot_in(0,mushroom.kind) and (not best or distance<best_distance) then
   best,best_distance=mushroom,distance
  end
 end
 return best or {x=cauldron_x,y=clearing_row*8,pot=true}
end

local function play(way)
 held={}
 -- stop to read any mushroom in reach that has not been read
 for mushroom in all(mushrooms) do
  if not read[mushroom] and abs(near(mushroom.x)-witch.x)<8
   and abs(mushroom.y-witch.y)<12 then
   read[mushroom]=true
   pause=way.read_frames
  end
 end
 if pause>0 then
  pause-=1
  return
 end
 local goal=target()
 local away=near(goal.x)-witch.x
 local direction=sgn(away)
 if abs(away)>3 then
  held[direction>0 and 1 or 0]=true
  -- over a step, or up to a branch the goal is on
  if ground_at(witch.x+direction*6,witch.y-1)
   or goal.y<witch.y-8 and abs(away)<24 then
   held[4]=true
  end
  if way.broom and abs(away)>150 and witch.facing==direction then
   held[2]=true
  end
 elseif goal.y>witch.y+8 then
  -- it is below her: walk off whatever she is standing on
  held[1]=true
 elseif not goal.pot then
  held[5]=true
 end
 -- a full jump, held, gets her out of most places she can be stuck in:
 -- under a branch the goal is on, most of all
 still=witch.x==last_x and still+1 or 0
 last_x=witch.x
 if still>30 and still%60<30 then held[4]=true end
 stuck_goal=goal
end

local function seconds(frames)
 return flr(frames/6)/10
end

local function report(way)
 local line,total,inside="",0,0
 for frames in all(times) do
  line..=" "..seconds(frames)
  -- in seconds, so that the sum stays a number pico-8 can hold
  total+=frames/60
  if frames<=3600 then inside+=1 end
 end
 printh(way.name..":"..line.." seconds; mean "..flr(total/#times*10)/10
  ..", "..inside.." of "..#times.." inside 60")
end

local begun

function _update60()
 run_frame(pace_frame)
end

function pace_frame()
 -- not before the game's own _init, which would put it back at the title
 if not begun then
  begun=true
  begin()
 end
 for frame=1,16 do
  local way=ways[way_number]
  if mode=="play" then
   play(way)
   game_update()
  else
   -- brewed, or the three minutes ran out, which is the bot's failing
   -- and not the game's: say where it was left
   add(times,mode=="brewed" and run_frames or level_seconds*60)
   if mode!="brewed" then
    printh("  the bot ran out of time in forest "..seed.." at "..witch.x..","..witch.y
     ..", going for "..near(stuck_goal.x)..","..stuck_goal.y)
   else
    -- a line a run, so that the runner can see the cart is alive
    printh("  forest "..seed.." brewed in "..seconds(run_frames))
   end
   if seed==seeds then
    report(way)
    way_number+=1
    seed,times=0,{}
    if not ways[way_number] then
     printh("ok pace")
     extcmd("shutdown")
     ways,way_number={{read_frames=0,level=1}},1
    end
   end
   begin()
  end
 end
end
