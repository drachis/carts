-- test_level.lua : a bot that cannot be hurt runs each of the six levels
-- in turn from the start, holding right, jumping (and holding the jump, so she paddles) at
-- a wall or a gap ahead. it must reach the observatory. it says only that
-- the level can be crossed by running and jumping, not that it is fair.
-- squirrels are taken out: this checks the ground, and bot_playthrough
-- plays with them.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
music=sfx

local frames,falls,last_respawn,total=0,0,0,0
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
 if respawn>0 and last_respawn==0 then
  falls+=1
 end
 last_respawn=respawn
 local front=hero.x+hero_w+4
 local blocked=area_has(front,hero.y,2,hero_h-4,0) or area_has(front,hero.y,2,hero_h-4,5)
 local ground=not hero.air
 held={[1]=true}
 if ground then
  held[4]=(blocked or not ground_ahead(front)) and not hero.jumping
  hero.jumping=held[4]
 else
  local below=false
  for y=hero.y+hero_h,120,4 do below=below or flag_at(hero.x+12,y,0) or flag_at(hero.x+12,y,1) end
  held[4]=hero.vy<0 or not below
  hero.jumping=false
 end
 _update60_game()
end

local function no_squirrels()
 for thing in all(things) do
  if thing.name=="squirrel" then del(things,thing) end
 end
end

function _init()
 _init_game()
 start_game()
 no_squirrels()
end

function _update60()
 run_frame(function()
  for i=1,32 do
   if mode=="play" then bot_frame() end
  end
  if mode=="win" then
   total+=frames
   printh("pass: level "..level..", "..level_names[level]..": the bot reached "..(landmarks[level] or "the observatory").." in "..flr(frames/60).." seconds, falling in "..falls.." times")
   if level<#levels then
    level+=1
    start_game()
    no_squirrels()
    frames,falls=0,0
   else
    printh("pass: all six levels in "..flr(total/60).." seconds")
    printh("ok level")
    extcmd("shutdown")
    mode="done"
   end
  elseif mode=="play" and frames>9000 then
   printh("error: the bot was stuck at x "..hero.x..", y "..hero.y.." after "..frames.." frames (vx "..hero.vx..", state "..hero.state..", air "..tostr(hero.air)..", blocked "..tostr(area_has(hero.x+hero_w+4,hero.y,2,hero_h-4,0))..", "..falls.." falls, respawning at "..respawn_x..")")
   _draw()
   dump_screen("level_stuck")
   extcmd("shutdown")
   mode="done"
  end
 end)
end
