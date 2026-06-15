-- minimap.lua : whole-city overview. HEADER — draw_minimap is a STUB.
-- api: draw_minimap
-- calls: tile/zone_kind/zone_density/is_road (map), gw, p
-- the player toggles a map mode (glue owns the toggle + calling this); runs in
-- SCREEN space. ALWAYS back the panel with an opaque rect (citysim's overview
-- had no bg and was unreadable).

local mm_ox,mm_oy=16,16

-- zone colour tables: kind 1/2/3 -> bright, dim
local mm_zb={11,12,10}
local mm_zd={3,1,4}

function draw_minimap()
 rectfill(mm_ox-1,mm_oy-1,mm_ox+96,mm_oy+96,0)
 rect(mm_ox-1,mm_oy-1,mm_ox+96,mm_oy+96,5)
 for y=0,gw-1 do
  for x=0,gw-1 do
   local t=tile(x,y)
   local c
   if t==0 then
    c=1
   elseif t==2 then
    c=13
   elseif is_road(x,y) then
    c=peekp(pl_cong,x,y)>p.cong_show and 8 or 5 -- busy roads glow red
   else
    local k=zone_kind(x,y)
    if k then
     c=(zone_density(x,y)>0) and mm_zb[k] or mm_zd[k]
    else
     c=3
    end
   end
   rectfill(mm_ox+x*3,mm_oy+y*3,mm_ox+x*3+2,mm_oy+y*3+2,c)
  end
 end
 rect(mm_ox+flr(camx/8)*3,mm_oy+flr(camy/8)*3,
      mm_ox+flr(camx/8)*3+16*3,mm_oy+flr(camy/8)*3+15*3,7)
end
