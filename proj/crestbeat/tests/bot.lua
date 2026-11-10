held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
music=sfx

updates_per_frame=8

function bot(frame,lag,route)
 local want=plan_lane(flr(clock)+1-(lag or 0),route)
 if want and want!=robot.lane and frame%2==0 then
  held[want<robot.lane and 0 or 1]=true
 end
end

function play_stage(number,lag,route)
 start_play()
 start_stage(number)
 local frame,hp=0,robot.hp
 while mode=="play" and stage_number==number and frame<3000 do
  frame+=1
  held={}
  bot(frame,lag,route and stage.golden)
  _update_game()
 end
 return hp-robot.hp,stats.golds,ticket_total()
end
