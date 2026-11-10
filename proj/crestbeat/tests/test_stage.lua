local n,done,start_hp=0
local real_hurt=hurt_robot
function hurt_robot(lane)
 if not done then printh("hurt at beat "..flr(clock*10)/10-stage_beat.." in street "..lane..", robot in "..robot.lane) end
 real_hurt(lane)
end
local game_update,game_draw=_update,_draw
_update_game=game_update

function _draw() end

function _update()
 run_frame(stage_frames)
end

function stage_frames()
 for i=1,updates_per_frame do
  if not done then stage_frame() end
 end
 game_draw()
end

function stage_frame()
 n+=1
 held={}
 if n==1 then
  start_play()
  start_stage(first_stage)
  start_hp=robot.hp
 end
 local name=stage.name
 bot(n)
 game_update()
 if n==100 then
  game_draw()
  dump_screen("stage_"..first_stage.."_"..name)
 end
 for alien in all(aliens) do
  local kind=getmetatable(alien)
  if kind!=kinds[1] and abs(alien.pos)<0.6 and alien.t>0.3 and not kind.seen then
   kind.seen=true
   game_draw()
   dump_screen("stage_"..first_stage.."_"..kind.name)
  end
 end
 local last=first_stage==#stages
 if mode!="play" or stage_number!=first_stage then
  done=true
  if last and mode!="won" or not last and mode!="play" then
   printh("error: stage "..name.." ended in mode "..mode)
  end
  if robot.hp<start_hp then
   printh("error: the plan loses "..(start_hp-robot.hp).." hearts on stage "..name)
  end
  printh("stage "..first_stage.." "..name..": "..flr(clock).." beats ("..flr(clock/2).."s) on the plan, hp "..start_hp.." to "..robot.hp..", tickets so far "..ticket_total())
  if last then printh("payout: "..tickets.." tickets") end
  printh("ok stage "..first_stage)
  extcmd("shutdown")
 elseif n>3000 then
  done=true
  printh("error: stage "..name.." never ended")
 end
end
