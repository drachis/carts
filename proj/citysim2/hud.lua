-- hud.lua : top status bar + RCI demand bars.
-- api: draw_hud
-- calls: money/mfmt/month/year (econ), pop/jobs/demand (sim)
-- runs in SCREEN space (called after draw_world reset the camera).
local mon=split"jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec"
local hd_lbl=split"r,c,i"
local hd_col=split"11,12,10"
local hd_dim=split"3,13,4"

function draw_hud()
 rectfill(0,0,127,6,0)
 -- money
 print(mfmt(money),0,1,money<0 and 8 or 11)
 -- pop (jobs moved to the minimap detail view to free space)
 print("p"..pop,32,1,14)
 -- date
 print(mon[month].." "..year,58,1,7)
 -- rci demand bars (x=104..126, midline y=4)
 local bx=104
 local hd_dv={demand.r,demand.c,demand.i}
 rectfill(bx,4,bx+22,4,5)
 for i=1,3 do
  local lx=bx+(i-1)*8
  print(hd_lbl[i],lx,1,hd_col[i])
  -- bar at lx+4 (1px gap after the 3px letter, for readability)
  local h=mid(-3,flr(hd_dv[i]*3+0.5),3)
  if h>0 then
   rectfill(lx+4,4-h,lx+5,4,hd_col[i])
  elseif h<0 then
   rectfill(lx+4,4,lx+5,4-h,hd_dim[i])
  end
 end
end
