-- inspector.lua : the sim explains itself. HEADER — draw_inspector is a STUB.
-- api: draw_inspector
-- shows tile_info(cur.x,cur.y) for the tile under the cursor.
-- contract (flesh this out):
--   local ti=tile_info(cur.x,cur.y)   -- nil if not a zone (then draw nothing)
--   ti = {kind=1/2/3, dens=0..3, access=bool, served=bool}
--   draw a small panel in SCREEN space (camera already reset by draw_world):
--     - rectfill an OPAQUE background first, then a rect border  <-- citysim bug
--       was a panel with no bg; always back panels.
--     - line 1: kind label ("res"/"com"/"ind") + " lv"..dens
--     - line 2: status — "no road" if not access, else "starved" if not served,
--       else "thriving" (served).
--   keep it a few lines, tucked in a corner; readable over the map.
local ins_kinds={"res","com","ind"}
local ins_cols={11,12,10}
-- a factor light: green when healthy, red when it's the thing to fix.
local function f(l,fx,fy,ok)
 print(l,fx,fy,ok and 11 or 8)
end
-- inspector = a tiny diagnostic panel. each factor that feeds a building's
-- health shows green (ok) / red (problem), so "why is it unhappy?" is readable
-- at a glance: road access, power, service coverage, a reachable market (jobs/
-- customers/buyers), commute length, and land-value desirability.
function draw_inspector()
 local ti=tile_info(cur.x,cur.y)
 if not ti then return end
 local x,y=1,8
 rectfill(x,y,x+52,y+23,0)
 rect(x,y,x+52,y+23,5)
 print(ins_kinds[ti.kind].." "..ti.dens,x+2,y+2,ins_cols[ti.kind])
 f("rd",x+2,y+9,ti.access)
 f("pwr",x+20,y+9,ti.power)
 f("svc",x+38,y+9,ti.svc)
 f("job",x+2,y+16,ti.served)
 f("cmt",x+20,y+16,ti.commute~=3)   -- red only when a long commute was reported
 f("des",x+38,y+16,ti.val>=124)
end
