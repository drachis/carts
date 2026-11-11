_update_game=_update
function _draw() end

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

local done
function _update()
 if not done then
  done=true
  run_frame(function()
   margins()
   printh("ok margin "..first_stage)
   extcmd("shutdown")
  end)
 end
end
