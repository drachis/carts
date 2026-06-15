-- agents.lua : pooled visible trips that realise sim contracts
-- api: agents, init_agents(), spawn_agent(x0,y0,x1,y1,res), update_agents(), draw_agents()
-- calls: path (router), is_road (map), peekp/pokep/gw (map), pl_cong (data), res_col (data), p (params)

agents={}

function init_agents()
 agents={}
end

-- optional `job`: a closure run once the agent reaches its destination (service
-- vehicles). commuters instead carry ox/oy/dx/dy (set by the caller) and report
-- satisfaction on arrival. returns the agent (so the caller can tag it), or nil.
function spawn_agent(x0,y0,x1,y1,res,job)
 if #agents>=p.agent_cap then return end
 local pa=path(x0,y0,x1,y1,
  is_road,
  function(x,y) return 1+p.cong_k*peekp(pl_cong,x,y) end)
 if pa and #pa>1 then
  -- enter first tile
  pokep(pl_cong,x0,y0,min(255,peekp(pl_cong,x0,y0)+1))
  local a={
   path=pa, i=2,
   px=x0*8+4, py=y0*8+4,
   tx=x0, ty=y0,
   res=res, col=res_col[res],
   life=p.trip_life, job=job
  }
  add(agents,a)
  return a
 end
end

-- nudge a building's satisfaction battery (clamped to a byte).
function sat_add(x,y,dv)
 pokep(pl_sat,x,y,mid(0,peekp(pl_sat,x,y)+dv,255))
end

-- a commuter reached its destination: the destination got a visit/customer/
-- delivery, and the origin home hears how the commute went (good/ok/too long).
function ag_report(a)
 if a.dx then sat_add(a.dx,a.dy,p.sat_visit) end
 if a.ox then
  local t=#a.path
  if t<=p.commute_good then pokep(pl_cmt,a.ox,a.oy,1) sat_add(a.ox,a.oy,p.sat_visit)
  elseif t<=p.commute_ok then pokep(pl_cmt,a.ox,a.oy,2)
  else pokep(pl_cmt,a.ox,a.oy,3) sat_add(a.ox,a.oy,-p.sat_visit) end
 end
end

local function ag_remove(a)
 pokep(pl_cong,a.tx,a.ty,max(0,peekp(pl_cong,a.tx,a.ty)-1))
end

function update_agents()
 local keep={}
 for _,a in pairs(agents) do
  a.life-=1
  -- a road on the trip was bulldozed? the path is broken -> abandon the trip
  -- (no arrival, so no satisfaction report). otherwise it'd drive over grass.
  local alive=a.life>0 and a.i<=#a.path
   and is_road(a.tx,a.ty) and is_road(a.path[a.i].x,a.path[a.i].y)
  if alive then
   -- move 1px toward centre of current target node
   local n=a.path[a.i]
   local tnx=n.x*8+4
   local tny=n.y*8+4
   local dx=tnx-a.px
   local dy=tny-a.py
   -- move one axis at a time; remember heading so we can draw in the right lane
   if dx~=0 then
    a.px+=sgn(dx) a.hx=sgn(dx) a.hy=0
   elseif dy~=0 then
    a.py+=sgn(dy) a.hx=0 a.hy=sgn(dy)
   end
   -- crossed into a new tile?
   local ntx=flr(a.px/8)
   local nty=flr(a.py/8)
   if ntx~=a.tx or nty~=a.ty then
    pokep(pl_cong,a.tx,a.ty,max(0,peekp(pl_cong,a.tx,a.ty)-1))
    pokep(pl_cong,ntx,nty,min(255,peekp(pl_cong,ntx,nty)+1))
    -- congestion just changed here -> land value nearby is stale; queue it.
    if val_dirty_area then val_dirty_area(ntx,nty) end
    a.tx=ntx
    a.ty=nty
   end
   -- reached this node's centre?
   if a.px==tnx and a.py==tny then
    a.i+=1
   end
   if a.i>#a.path then
    -- arrived. a job-carrying vehicle (crew/engine) is done; a commuter turns
    -- around and heads home, so trips are visible round-trips, not one-way.
    if a.job or a.ret then
     alive=false
    else
     ag_report(a)  -- tell home + destination how this trip went
     a.ret=true
     local r={}
     for j=#a.path,1,-1 do add(r,a.path[j]) end
     a.path=r a.i=2
    end
   end
  end
  if alive then
   add(keep,a)
  else
   ag_remove(a)
   if a.job and a.i>#a.path then a.job() end
  end
 end
 agents=keep
end

function draw_agents()
 for _,a in pairs(agents) do
  -- offset to the RIGHT of travel (perp = rotate heading 90deg cw) so opposing
  -- traffic uses opposite lanes instead of overlapping on the centre line
  local px=a.px-(a.hy or 0)*2
  local py=a.py+(a.hx or 0)*2
  pset(px,py,a.col)
  pset(px+1,py,a.col)
  pset(px,py+1,a.col)
  pset(px+1,py+1,a.col)
 end
end
