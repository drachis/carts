-- test_playthrough.lua : imperfect players play the level through, to see
-- whether its challenge grows from the street to the observatory.
--
-- each run is a bot with its own reflexes, drawn from a seed: how far
-- ahead it sees a squirrel or a gap, and how long it holds a jump. it
-- holds right, jumps at walls, gaps and squirrels, and can be hurt, fall
-- in and lose, like a player. it never sits, barks or turns back.
--
-- for every run and section of the level (256px each) it logs a line
--   sec run section frames jumps hits falls
-- and at each run's end
--   end run outcome section frames
-- py challenge_report.py turns them into a challenge per section and
-- says whether it grows. this cart checks only that the runs finish.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
music=sfx

local runs,run,bot,stats=12,0
_init_game,_update60_game=_init,_update60

local function section() return mid(1,flr((hero.x+12)/256)+1,8) end

local function new_run()
 run+=1
 srand(run*7)
 start_game()
 bot={see_squirrel=14+rnd(26),see_gap=1+rnd(8),hold=6+rnd(26),late=rnd(0.35),jump=0,frames=0,hearts=hearts,respawn=0}
 stats={}
 for s=1,8 do stats[s]={0,0,0,0} end
end

local function ground_ahead(front)
 for depth=0,12,2 do
  local y=hero.y+hero_h+depth
  if flag_at(front,y,0) or flag_at(front,y,1) then return true end
 end
end

local function danger_ahead(front)
 for thing in all(things) do
  if thing.name=="squirrel" and not thing.state and abs(thing.y-hero.y)<18 then
   local gap=thing.x-front
   if gap>-6 and gap<bot.see_squirrel then return true end
  end
 end
end

local function finish(outcome)
 for s=1,8 do
  local stat=stats[s]
  if stat[1]>0 then printh("sec "..run.." "..s.." "..stat[1].." "..stat[2].." "..stat[3].." "..stat[4]) end
 end
 printh("end "..run.." "..outcome.." "..section().." "..bot.frames)
end

local function bot_frame()
 local stat=stats[section()]
 bot.frames+=1
 stat[1]+=1
 if hearts<bot.hearts then
  if respawn>0 then stat[4]+=1 else stat[3]+=1 end
 end
 bot.hearts=hearts
 local front=hero.x+hero_w+2+bot.see_gap
 local want=area_has(hero.x+hero_w+3,hero.y,2,hero_h-4,0) or not ground_ahead(front) or danger_ahead(hero.x+hero_w)
 held={[1]=true}
 if bot.jump>0 then
  bot.jump-=1
  held[4]=true
 elseif want and not hero.air and rnd()>bot.late then
  bot.jump=bot.hold
  stat[2]+=1
  held[4]=true
 end
 _update60_game()
end

function _init()
 _init_game()
 new_run()
end

function _update60()
 run_frame(function()
  for i=1,32 do
   if mode=="play" then
    bot_frame()
    if bot.frames>6000 then finish("stuck") mode="next" end
   elseif mode=="win" then
    finish("won") mode="next"
   elseif mode=="over" then
    finish("lost") mode="next"
   end
   if mode=="next" then
    if run==runs then
     printh("ok playthrough")
     extcmd("shutdown")
     mode="done"
    else
     new_run()
    end
   end
  end
 end)
end
