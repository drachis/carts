local n,phase,phase_start,done=0,"title",0
local game_update,game_draw=_update,_draw

local function expect_mode(wanted)
 if mode!=wanted then
  printh("error: frame "..n.." is in mode "..tostr(mode)..", wanted "..wanted)
 end
end

local function next_phase(name)
 phase,phase_start=name,n
end

local function dump(name)
 game_draw()
 dump_screen(name)
end

function _draw() end

function _update()
 run_frame(boot_frames)
end

function boot_frames()
 for i=1,updates_per_frame do
  if not done then boot_frame() end
 end
 game_draw()
end

function boot_frame()
 n+=1
 held={}
 local age=n-phase_start
 if phase=="title" then
  if age==40 then
   held[4]=true
   next_phase("idle")
  end
 elseif phase=="idle" then
  if age==2 then
   expect_mode("play")
   held[5]=true
  elseif age==4 then
   if robot.gun!=start_gun%#guns+1 then printh("error: x did not switch to the next gun") end
   held[4]=true
  elseif age==6 and robot.gun!=start_gun then
   printh("error: o did not switch back")
  end
  if mode!="play" then
   expect_mode("lost")
   printh("idle run lost in "..flr(clock).." beats")
   next_phase("lost")
  elseif age>3000 then
   printh("error: the idle run never ended")
   next_phase("lost")
  end
 elseif phase=="lost" and age==40 then
  held[4]=true
  next_phase("again")
 elseif phase=="again" and age==10 then
  expect_mode("play")
  finish("won")
  next_phase("won")
 end
 game_update()
 if n==5 then dump("boot_title") end
 if phase=="idle" and age==150 then dump("boot_play") end
 if phase=="idle" and age==300 then dump("boot_hurt") end
 if phase=="lost" and age==30 then dump("boot_lost") end
 if phase=="won" and age==30 then
  dump("boot_won")
  done=true
  printh("ok boot")
  extcmd("shutdown")
 end
end
