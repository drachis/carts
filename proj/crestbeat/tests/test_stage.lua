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

local function margins()
 local line,clean,survive="",nil,nil
 for lag=0,8 do
  local lost,_,earned=play_stage(first_stage,lag)
  line..=lag..":"..lost.." "
  printh("points "..first_stage.." lag "..lag.." "..lost.." "..earned)
  if lost>0 and not clean then clean=lag-1 end
  if lost>=max_hp and not survive then survive=lag-1 end
 end
 clean,survive=clean or 8,survive or 8
 printh("stage "..first_stage.." "..stages[first_stage].name..": clean margin "..clean..", survival margin "..survive.." beats behind the plan (lag:hearts lost) "..line)
 local wanted=stages[first_stage].margin
 if wanted and survive!=wanted then
  printh("error: stage "..first_stage.."'s survival margin is "..survive..", designed "..wanted)
 end
 if stages[first_stage].golden then
  local real_update=_update_game
  _update_game=function()
   local before=flr(clock)
   real_update()
   if flr(clock)!=before and trace_gold then
    local front=target_in(robot.lane)
    for alien in all(aliens) do
     if alien.bonus>0 then printh("beat "..(flr(clock)-stage_beat).." robot "..robot.lane.." front "..(front and (front.bonus>0 and "gold" or front.name) or "none").." gold in "..alien.lane.." hp "..alien.hp) end
    end
   end
  end
  local lost,prizes,earned=play_stage(first_stage,0,true)
  _update_game=real_update
  printh("points "..first_stage.." golden "..lost.." "..earned)
  local prize=stages[first_stage].bars and "bell" or "golden alien"
  printh("stage "..first_stage.." "..prize.." route: gets "..prizes.." "..prize.." for "..lost.." hearts (designed at most "..stages[first_stage].gold_cost.."), "..earned.." tickets")
  if prizes!=1 then printh("error: the "..prize.." route missed its "..prize) end
  if lost>stages[first_stage].gold_cost then printh("error: the "..prize.." route cost more than designed") end
 end
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
  if last then
   for i=1,24 do game_update() end
   game_draw()
   dump_screen("stage_payout_counting")
   while not payout_done() do game_update() end
   for i=1,10 do game_update() end
   game_draw()
   dump_screen("stage_won")
   printh("payout: "..tickets.." tickets")
  end
  if not stages[first_stage].fly then margins() end
  printh("ok stage "..first_stage)
  extcmd("shutdown")
 elseif n>3000 then
  done=true
  printh("error: stage "..name.." never ended")
 end
end
