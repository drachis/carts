-- terrain.lua: white noise + box blur -> PERCENTILE threshold + greedy river.
-- box-blur narrows the value spread, so we pick sea/mtn from the actual
-- histogram (so we always get ~water_pct water + ~mtn_pct mountains).
function gen_terrain()
 local buf={}
 for i=0,gw*gw-1 do buf[i]=rnd(256) end
 for _=1,p.terr_blur do
  local t={}
  for y=0,gw-1 do for x=0,gw-1 do
   local s,n=0,0
   for j=-1,1 do for i=-1,1 do
    if in_bounds(x+i,y+j) then s+=buf[x+i+(y+j)*gw] n+=1 end
   end end
   t[x+y*gw]=s/n
  end end
  buf=t
 end
 -- histogram of integer elevations, then percentile cuts
 local h={}
 for i=0,255 do h[i]=0 end
 for i=0,gw*gw-1 do local e=flr(buf[i]) buf[i]=e h[e]+=1 end
 local cum,sea,mtn,n=0,0,256,gw*gw
 for i=0,255 do
  cum+=h[i]
  if sea==0 and cum>=n*p.sea_pct then sea=i end
  if mtn==256 and cum>=n*p.mtn_pct then mtn=i end
 end
 local bx,by,be=0,0,-1
 for y=0,gw-1 do for x=0,gw-1 do
  local e=buf[x+y*gw]
  pokep(pl_elev,x,y,e)
  if e>be then be=e bx=x by=y end
  set_tile(x,y,e<sea and 0 or e>=mtn and 2 or 1)
 end end
 -- greedy downhill river; rnd jitter causes meandering
 -- elev=0 marks visited tiles (river tiles become water anyway)
 local cx,cy=bx,by
 for _=1,gw*4 do
  set_tile(cx,cy,0) pokep(pl_elev,cx,cy,0)
  if cx==0 or cy==0 or cx==gw-1 or cy==gw-1 then break end
  local mn,nx,ny=999,cx,cy
  for _,nb in pairs(neighbors4(cx,cy)) do
   local ne=peekp(pl_elev,nb.x,nb.y)
   if ne>0 then
    ne=ne+rnd(p.river_jit)
    if ne<mn then mn=ne nx=nb.x ny=nb.y end
   end
  end
  if nx==cx and ny==cy then break end
  cx=nx cy=ny
 end
end
