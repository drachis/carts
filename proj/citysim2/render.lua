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
-- animated sparkle on visible water tiles (cheap: only the camera window).
function draw_water()
 local t=flr((tick or 0)/8)
 local x0,y0=flr(camx/8),flr(camy/8)
 for ty=y0,y0+16 do
  for tx=x0,x0+16 do
   if tile(tx,ty)==0 and (tx*3+ty*7+t)%6==0 then
    pset(tx*8+(tx+t)%5+1,ty*8+(ty*3)%5+1,7)
   end
  end
 end
end

function draw_world()
 camera(camx,camy)
 night_pal()              -- dusk/night colour remap (no-op at midday)
 map(0,0,0,0,gw,gw)
 draw_agents()
 pal()                    -- reset so fire/cursor draw at full brightness
 draw_water()             -- water glints (bright, after the night remap)
 draw_fire()
 draw_fx()
 draw_cursor()
 camera()
end
