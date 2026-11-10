local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
music=sfx

local seen_stage,stage_start
local n,phase,phase_start,bot_beat,shots=0,"title",0,nil,{}
local game_update,game_draw=_update60,_draw

local function expect_mode(wanted)
 if mode!=wanted then
  printh("error: frame "..n.." is in mode "..tostr(mode)..", wanted "..wanted)
 end
end

local function danger(lane)
 for hazard in all(hazards) do
  if hazard.lane==lane and hazard.land-clock<1.4 then return true end
 end
end

local function bot()
 local want
 for alien in all(aliens) do
  if alien.t>-0.05 then want=alien.lane end
 end
 if not want and titan then
  for spot in all(titan.spots) do
   if open_spot_in(spot.lane) then want=spot.lane end
  end
 end
 if danger(robot.lane) or want and danger(want) then
  want=nil
  for lane=-1,1 do
   if not danger(lane) then want=lane end
  end
 end
 if not want then return end
 if want!=robot.lane then
  if n%2==0 then held[want<robot.lane and 0 or 1]=true end
  return
 end
 local nearest=flr(clock+0.5)
 if nearest!=bot_beat and abs(clock-nearest)*frames_per_beat<1 then
  bot_beat=nearest
  held[4]=true
 end
end

local function next_phase(name)
 phase,phase_start=name,n
end

function _draw() end

function _update60()
 run_frame(boot_frame)
end

function boot_frame()
 n+=1
 held={}
 local age=n-phase_start
 if phase=="title" then
  if age==40 then
   held[4]=true
   next_phase("bot")
  end
 elseif phase=="bot" then
  if age==2 then expect_mode("play") end
  bot()
  if stage_number!=seen_stage then
   seen_stage,stage_start=stage_number,n
   printh("stage "..stage.name.." at beat "..next_beat..", hp "..robot.hp)
  end
  if stage_number==2 and n-stage_start==90 then dump_screen("boot_climb") end
  if stage.name=="titan" and n-stage_start==200 then dump_screen("boot_titan") end
  if stage.name=="queen" and n-stage_start==300 then dump_screen("boot_queen") end
  if mode!="play" then
   expect_mode("won")
   printh("bot won in "..flr(clock).." beats ("..flr(clock/2).."s), hp "..robot.hp.."/"..max_hp..", score "..score)
   next_phase("won")
  elseif age>9000 then
   printh("error: the bot's run never ended")
   next_phase("won")
  end
 elseif phase=="won" then
  if age==60 then
   held[4]=true
   next_phase("idle")
  end
 elseif phase=="idle" then
  if mode!="play" then
   expect_mode("lost")
   printh("idle run lost in "..flr(clock).." beats")
   next_phase("lost")
  elseif age>3000 then
   printh("error: the idle run never ended")
   next_phase("lost")
  end
 elseif phase=="lost" and age==60 then
  held[4]=true
  next_phase("again")
 end
 game_update()
 game_draw()
 if n==5 then dump_screen("boot_title") end
 if phase=="bot" and age==420 then dump_screen("boot_play") end
 if phase=="won" and age==50 then dump_screen("boot_won") end
 if phase=="idle" and age==500 then dump_screen("boot_hurt") end
 if phase=="lost" and age==50 then dump_screen("boot_lost") end
 if phase=="again" and age==10 then
  expect_mode("play")
  printh("ok boot")
  extcmd("shutdown")
 end
end
