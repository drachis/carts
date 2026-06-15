-- landval.lua : desirability / land value field (pl_val, 0..255, 128 neutral).
-- sim weights zone growth/decay by desir() so the waterfront booms and the
-- factory's edge rots. the per-tile box scan is too heavy to redo wholesale, so
-- recompute is a DIRTY QUEUE: a tile is only re-evaluated when something that
-- feeds it changes (a build, a fire, an agent's congestion). step_val drains a
-- slice of the queue each frame (1/val_div), so a static map costs ~nothing and
-- no dirty tile waits longer than ~val_div frames. update_val does a full sweep
-- for seed/tests.
-- api: update_val, step_val, val_dirty, val_dirty_area, desir

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

-- dirty queue: list of tile indices + a dedup set so a tile is queued once.
vq={}
local vqd={}

function val_dirty(x,y)
 if in_bounds(x,y) then
  local i=x+y*gw
  if not vqd[i] then vqd[i]=true add(vq,i) end
 end
end

-- a change at (x,y) feeds the land value of every tile whose box reaches it
-- (within val_rad) — queue that neighbourhood.
function val_dirty_area(x,y)
 local rad=p.val_rad
 for ty=y-rad,y+rad do
  for tx=x-rad,x+rad do
   val_dirty(tx,ty)
  end
 end
end

-- drain a slice of the queue: enough that the whole backlog clears in ~val_div
-- frames regardless of its size (so latency stays ~1s, cost scales with churn).
function step_val()
 for _=1,ceil(#vq/p.val_div) do
  local i=vq[#vq] deli(vq,#vq)
  vqd[i]=nil
  pokep(pl_val,i%gw,flr(i/gw),val_at(i%gw,flr(i/gw)))
 end
end

-- full sweep (seed + tests): recompute everything and empty the queue.
function update_val()
 for y=0,gw-1 do
  for x=0,gw-1 do
   pokep(pl_val,x,y,val_at(x,y))
  end
 end
 vq={} vqd={}
end

function desir(x,y)
 return peekp(pl_val,x,y)
end
