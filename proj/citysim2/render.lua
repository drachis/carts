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
-- congestion is shown on the minimap (minimap.lua), not as a world overlay.
function draw_world()
 camera(camx,camy)
 map(0,0,0,0,gw,gw)
 draw_agents()
 draw_cursor()
 camera()
end
