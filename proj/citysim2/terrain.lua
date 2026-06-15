-- terrain.lua : white noise + box blur -> PERCENTILE threshold. simple coastline
-- + lakes, no meandering river (it crowded the buildable land and cost tokens).
-- box-blur narrows the value spread, so sea/mtn come from the actual histogram
-- (always ~sea_pct water + the top (1-mtn_pct) as mountains).
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
 for y=0,gw-1 do for x=0,gw-1 do
  local e=buf[x+y*gw]
  pokep(pl_elev,x,y,e)
  set_tile(x,y,e<sea and 0 or e>=mtn and 2 or 1)
 end end
end
