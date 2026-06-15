-- render.lua : world drawing. HEADER — draw_world is a STUB for an agent.
-- api: draw_world
-- NOTE sprite id == tile id, so map() renders the tile grid directly.
-- contract (flesh this out):
--   camera(camx,camy)
--   map(0,0,0,0,gw,gw)            -- the tiles (sprites match ids)
--   -- light overlays: e.g. faint congestion on busy roads from
--   --   peekp(pl_cong,x,y) over the visible window, animated water sparkle;
--   --   keep it cheap and don't fight the sprite art.
--   draw_agents()                 -- the moving commuters (agents.lua)
--   draw_cursor()                 -- the cursor outline (tools.lua)
--   camera()                      -- reset so the glue draws hud in screen space
-- tint a busy road tile: two red pixels at the tile centre
function rn_cong_mark(x,y)
 local px,py=x*8+3,y*8+3
 pset(px,py,8)
 pset(px+1,py+1,8)
end

function draw_world()
 camera(camx,camy)
 map(0,0,0,0,gw,gw)
 -- congestion overlay (visible window only)
 local cx=flr(camx/8)
 local cy=flr(camy/8)
 for ty=cy,min(gw-1,cy+15) do
  for tx=cx,min(gw-1,cx+16) do
   if is_road(tx,ty) and peekp(pl_cong,tx,ty)>p.cong_show then
    rn_cong_mark(tx,ty)
   end
  end
 end
 draw_agents()
 draw_cursor()
 camera()
end
