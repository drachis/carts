-- test_level.lua : a bot that cannot be hurt runs the whole level from the
-- start, holding right, jumping (and holding the jump, so she paddles) at
-- a wall or a gap ahead. it must reach the observatory. it says only that
-- the level can be crossed by running and jumping, not that it is fair.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
music=sfx

local frames,falls,last_respawn=0,0,0
_init_game,_update60_game=_init,_update60

local function ground_ahead(front)
 for depth=0,12,2 do
  local y=hero.y+hero_h+depth
  if flag_at(front,y,0) or flag_at(front,y,1) then return true end
 end
end

local function bot_frame()
 frames+=1
 hearts=max_hearts
 hero.hurt=max(hero.hurt,2)
 if respawn>0 and last_respawn==0 then falls+=1 end
 last_respawn=respawn
 local front=hero.x+hero_w+4
 local blocked=area_has(front,hero.y,2,hero_h-4,0)
 local ground=not hero.air
 held={[1]=true}
 if ground then
  held[4]=(blocked or not ground_ahead(front)) and not hero.jumping
  hero.jumping=held[4]
 else
  held[4]=true
  hero.jumping=false
 end
 _update60_game()
end

function _init()
 _init_game()
 start_game()
end

function _update60()
 run_frame(function()
  for i=1,16 do
   if mode=="play" then bot_frame() end
  end
  if mode=="win" then
   printh("pass: the bot reached the observatory in "..frames.." frames ("..flr(frames/60).." seconds), falling in "..falls.." times")
   printh("ok level")
   extcmd("shutdown")
   mode="done"
  elseif mode=="play" and frames>9000 then
   printh("error: the bot was stuck at x "..hero.x..", y "..hero.y.." after "..frames.." frames")
   _draw()
   dump_screen("level_stuck")
   extcmd("shutdown")
   mode="done"
  end
 end)
end
