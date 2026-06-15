-- landval.lua : desirability / land value field (pl_val, 0..255, 128 neutral).
-- sim weights zone growth/decay by desir() so the waterfront booms and the
-- factory's edge rots. the per-tile box scan is O(gw^2 * rad^2) — too heavy for
-- one frame — so step_val() amortizes it a few rows per frame (a rolling
-- refresh, invisible). update_val() does a full sweep for seed/tests.
-- api: update_val, step_val, desir

-- desirability at one tile: 128 + waterfront/park bonuses - pollution/congestion.
local function val_at(x,y)
 local rad=p.val_rad
 local v=128
 for dy=-rad,rad do
  for dx=-rad,rad do
   local nx,ny=x+dx,y+dy
   if in_bounds(nx,ny) then
    local t=tile(nx,ny)
    if t==0 then v+=p.val_water
    elseif t==61 then v+=p.val_park
    elseif (t>=56 and t<=59) or t==60 then v-=p.val_pol end
    if is_road(nx,ny) then v-=p.val_cong*peekp(pl_cong,nx,ny) end
   end
  end
 end
 return flr(mid(0,v,255))
end

function update_val()
 for y=0,gw-1 do
  for x=0,gw-1 do
   pokep(pl_val,x,y,val_at(x,y))
  end
 end
end

-- amortized recompute: refresh `rows` rows per call, cycling through the grid.
val_y=0
function step_val(rows)
 for _=1,rows or 2 do
  for x=0,gw-1 do
   pokep(pl_val,x,val_y,val_at(x,val_y))
  end
  val_y=(val_y+1)%gw
 end
end

-- recompute the neighbourhood a structural change touched, right away: a build
-- at (x,y) affects every tile whose box reaches it (within val_rad). cheap and
-- on-demand, so most tiles never get touched while the city sits static.
function dirty_val(x,y)
 local rad=p.val_rad
 for ty=y-rad,y+rad do
  for tx=x-rad,x+rad do
   if in_bounds(tx,ty) then pokep(pl_val,tx,ty,val_at(tx,ty)) end
  end
 end
end

function desir(x,y)
 return peekp(pl_val,x,y)
end
