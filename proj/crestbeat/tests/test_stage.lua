local n,done,start_hp=0
local game_update,game_draw=_update,_draw

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
  printh("stage "..first_stage.." "..name..": "..flr(clock).." beats ("..flr(clock/2).."s), hp "..start_hp.." to "..robot.hp)
  if last then
   for i=1,24 do game_update() end
   game_draw()
   dump_screen("stage_payout_counting")
   while not payout_done() do game_update() end
   for i=1,10 do game_update() end
   game_draw()
   dump_screen("stage_won")
   printh("payout: "..tickets.." tickets from "..stats.kills.." aliens, "..stats.golds.." golden, "..stats.bells.." bells, "..stats.titans.." giants, "..stats.civilians.." civilians hit")
  end
  printh("ok stage "..first_stage)
  extcmd("shutdown")
 elseif n>3000 then
  done=true
  printh("error: stage "..name.." never ended")
 end
end
