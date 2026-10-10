-- test_soak.lua : every stage at every age. each stage's three blocks are
-- built at once, and the dragon is then moved along it from end to end,
-- healed throughout and mashing its buttons, to shake out errors.

local turns_per_stage=20
local age_turns=turns_per_stage*4

function step()
 local d=dragon
 local turn=(n-1)\16
 if (n-1)%16==0 then
  if turn%age_turns==0 and turn>0 and age<#ages then grow() end
  if turn%turns_per_stage==0 then
   enter_stage(turn\turns_per_stage%4)
   next_block()
   next_block()
  end
  d.x,d.y,d.vx,d.vy=40+turn%turns_per_stage*48,cam_y+60+turn%3*20,0,0
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
 if turn>=age_turns*#ages then
  printh("ok soak: 4 stages at "..#ages.." ages, "..kills.." kills")
  extcmd("shutdown")
 end
end
