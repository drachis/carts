-- test_feel.lua : a pacing map. the bot plays for thirty seconds, unhealed,
-- or until it dies.
-- once a second it prints: enemies on screen, kills so far, tiles burning,
-- shots in the air, its health, and where it is.
-- feel_map.py runs this and its twin in ../wyrmfire and compares them.


function step()
 local d=dragon
 play()
 if n%30==0 then
  local seen=0
  for unit in all(units) do
   if on_screen(unit.x,unit.y,0) then seen+=1 end
  end
  printh("feel "..n\30 ..","..seen..","..kills..","..#fires..","..#shots..","..flr(d.hp)..","..flr(d.x+stage*1024)..","..flr(d.y-cam_y)..","..stage*3+block)
 end
 if state!="play" or n==900 then
  printh("ok feel")
  extcmd("shutdown")
 end
end
