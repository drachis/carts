-- test_feel.lua : a pacing map. the bot plays for two minutes, healed so
-- that the map covers the whole time and carries on into the next stage.
-- once a second it prints: enemies on screen, kills so far, tiles burning,
-- shots in the air, health lost that second, and where it is.
-- feel_map.py runs this and its twin in ../wyrmfire and compares them.

local hurt=0

function step()
 local d=dragon
 play()
 hurt+=d.max_hp-d.hp
 d.hp=d.max_hp
 if state!="play" then
  new_game()
  state="play"
 end
 if n%30==0 then
  local seen=0
  for unit in all(units) do
   if on_screen(unit.x,unit.y,0) then seen+=1 end
  end
  printh("feel "..n\30 ..","..seen..","..kills..","..#fires..","..#shots..","..flr(hurt)..","..flr(d.x+stage*1024)..","..flr(d.y-cam_y))
  hurt=0
 end
 if n==3600 then
  printh("ok feel")
  extcmd("shutdown")
 end
end
