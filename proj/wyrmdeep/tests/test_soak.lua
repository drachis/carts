-- test_soak.lua : the dragon is moved to everything the level places, stage
-- by stage and at every age, healed throughout and mashing its buttons, to
-- shake out errors.

local stops={}
for row in all(split(spawn_text,"\n")) do
 local name,x,y=unpack(split(row))
 if name!="" then add(stops,{name=name,x=x,y=y}) end
end

function step()
 local d=dragon
 local turn=(n-1)\16
 local stop=stops[turn%#stops+1]
 if (n-1)%16==0 then
  if turn%#stops==0 and turn>0 and age<#ages then grow() end
  if stop.y\128!=stage then enter_stage(stop.y\128) end
  d.x,d.y,d.vx,d.vy=stop.x-12,stop.y-8,0,0
  cam_x=mid(0,d.x-44,896)
 end
 d.hp=d.max_hp
 fury=100
 advance=nil
 hold(n%4,4)
 if n%16>10 then hold(n%2,5) end
 if state!="play" then
  new_game()
  state="play"
 end
 if turn>=#stops*#ages then
  printh("ok soak: "..#stops.." stops at "..#ages.." ages, "..kills.." kills")
  extcmd("shutdown")
 end
end
