-- landval.lua : desirability / land value field. HEADER — update_val is a STUB.
-- api: update_val, desir
-- writes the pl_val plane (0..255, 128 = neutral). recomputed on a slow tick
-- (the sim census). sim weights zone growth/decay by desir() so the waterfront
-- booms and the factory's edge rots — emergent desirability.
-- contract for update_val():
--   for each tile (x,y) in the gw x gw grid, start v=128, then scan the box of
--   chebyshev radius p.val_rad around it and apply:
--     + p.val_water  per water tile     (tile==0)   -- waterfront desirable
--     + p.val_park   per park tile       (tile==44)  -- services (future)
--     - p.val_pol    per polluter        (industry 56..59 or plant 60)
--     - p.val_cong   per agent on a road (is_road and peekp(pl_cong,nx,ny))
--   clamp v to 0..255 and pokep(pl_val,x,y,v).
function update_val()
 local rad=p.val_rad
 for y=0,gw-1 do
  for x=0,gw-1 do
   local v=128
   for dy=-rad,rad do
    for dx=-rad,rad do
     local nx,ny=x+dx,y+dy
     if in_bounds(nx,ny) then
      local t=tile(nx,ny)
      if t==0 then
       v+=p.val_water
      elseif t==61 then
       v+=p.val_park
      elseif (t>=56 and t<=59) or t==60 then
       v-=p.val_pol
      end
      if is_road(nx,ny) then
       v-=p.val_cong*peekp(pl_cong,nx,ny)
      end
     end
    end
   end
   pokep(pl_val,x,y,flr(mid(0,v,255)))
  end
 end
end

function desir(x,y)
 return peekp(pl_val,x,y)
end
