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
function draw_inspector()
 local ti=tile_info(cur.x,cur.y)
 if not ti then return end
 local x,y=1,8
 rectfill(x,y,x+46,y+15,0)
 rect(x,y,x+46,y+15,5)
 local label=ins_kinds[ti.kind].." lv"..ti.dens
 print(label,x+2,y+2,ins_cols[ti.kind])
 local st="thriving"
 if not ti.access then st="no road"
 elseif not ti.served then st="starved" end
 print(st,x+2,y+9,7)
end
