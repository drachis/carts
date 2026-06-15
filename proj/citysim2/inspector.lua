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
 rectfill(x,y,x+46,y+29,0)
 rect(x,y,x+46,y+29,5)
 print(ins_kinds[ti.kind].." lv"..ti.dens,x+2,y+2,ins_cols[ti.kind])
 -- status, plainest cause first. "served" = a trading partner is reachable;
 -- say what's missing per kind instead of the cryptic "starved".
 local st="thriving"
 if not ti.access then st="no road"
 elseif not ti.power then st="no power"
 elseif ti.settling then st="settling in"
 elseif not ti.served then st=ti.kind==1 and "no jobs" or ti.kind==2 and "no trade" or "no buyers"
 elseif ti.remote then st="long commute"
 elseif ti.dens>=2 and not ti.svc then st="needs svc" end
 print(st,x+2,y+9,7)
 -- land value: green desirable / red blighted
 print("val "..ti.val,x+2,y+16,ti.val>140 and 11 or ti.val<116 and 8 or 6)
 -- service coverage (station/park): green ok / grey none
 print(ti.svc and "svc ok" or "svc none",x+2,y+23,ti.svc and 11 or 5)
end
