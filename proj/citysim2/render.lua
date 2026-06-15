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
-- the water surface is the cls() colour (see glue _draw); here we just add an
-- animated glint over the visible water tiles.
function draw_water()
 local t=flr((tick or 0)/8)
 local x0,y0=flr(camx/8),flr(camy/8)
 for ty=y0,y0+16 do
  for tx=x0,x0+16 do
   if tile(tx,ty)==0 and (tx*3+ty*7+t)%4==0 then
    pset(tx*8+(tx+t)%6+1,ty*8+(ty*3)%6+1,7)
   end
  end
 end
end

-- flashing lightning bolt over zones that lack power (the v1 "no power" cue).
function draw_alerts()
 if tick%16>=8 then return end           -- blink
 local x0,y0=flr(camx/8),flr(camy/8)
 for ty=y0,y0+16 do
  for tx=x0,x0+16 do
   if is_zone(tx,ty) and zone_density(tx,ty)>0 and not powered(tx,ty) then
    local sx,sy=tx*8,ty*8
    line(sx+4,sy+1,sx+2,sy+4,10)
    line(sx+2,sy+4,sx+5,sy+4,10)
    line(sx+5,sy+4,sx+3,sy+7,10)
   end
  end
 end
end

-- power-line overlay where a wire crosses a road/water (pl_wire); drawn along
-- the axis it actually connects (a vertical run draws vertical, not horizontal).
function draw_wires()
 local x0,y0=flr(camx/8),flr(camy/8)
 for ty=y0,y0+16 do
  for tx=x0,x0+16 do
   if peekp(pl_wire,tx,ty)>0 then
    local sx,sy=tx*8,ty*8
    local v=conducts(tx,ty-1) or peekp(pl_wire,tx,ty-1)>0 or conducts(tx,ty+1) or peekp(pl_wire,tx,ty+1)>0
    local h=conducts(tx-1,ty) or peekp(pl_wire,tx-1,ty)>0 or conducts(tx+1,ty) or peekp(pl_wire,tx+1,ty)>0
    if v then line(sx+3,sy,sx+3,sy+7,0) end
    if h then line(sx,sy+3,sx+7,sy+3,0) end
    if not (v or h) then line(sx,sy+3,sx+7,sy+3,0) end
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
 draw_wires()             -- wires crossing roads
 draw_fire()
 draw_alerts()            -- no-power lightning bolts
 draw_cursor()
 camera()
end
