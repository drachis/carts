-- fx.lua : particles — the juice. smokestacks puff, fires belch dark smoke,
-- placing/dozing kicks up dust. a small capped pool; update moves+ages, draw
-- runs in world space (inside draw_world, after the night pal reset so embers
-- stay bright). emitters read plants[] (net.lua) and fires[] (disaster.lua).
-- api: init_fx, update_fx, draw_fx, fx_burst(px,py,col,n); global: parts
parts={}
local fxc=0

function init_fx() parts={} fxc=0 end

local function spawn(x,y,dx,dy,life,col)
 if #parts<72 then add(parts,{x=x,y=y,dx=dx,dy=dy,l=life,c=col}) end
end

-- a rising smoke wisp from world-pixel (px,py); dark for fire, grey for plant.
local function smoke(px,py,dark)
 spawn(px,py,(rnd(2)-1)*0.2,-0.3-rnd(0.3),24+rnd(16),dark and 1 or 6)
end

-- an outward burst (dust on placement, sparks on collapse).
function fx_burst(px,py,col,n)
 for i=1,n do
  local a=rnd(1)
  spawn(px,py,cos(a)*rnd(1.2),sin(a)*rnd(1.2)-0.3,8+rnd(8),col)
 end
end

function update_fx()
 for i=#parts,1,-1 do
  local q=parts[i]
  q.x+=q.dx q.y+=q.dy q.dy+=0.02 q.l-=1
  -- smoke cools grey->dark as it ages; embers keep their colour
  if q.c==6 and q.l<12 then q.c=5 end
  if q.l<=0 then deli(parts,i) end
 end
 fxc+=1
 if fxc%4==0 then
  for f in all(fires) do smoke(f.x*8+2+rnd(4),f.y*8,true) end
 end
 if fxc%8==0 then
  for pl in all(plants) do
   if rnd(1)<0.6 then smoke(pl.x*8+1+rnd(2),pl.y*8,false) end
  end
 end
end

function draw_fx()
 for q in all(parts) do
  pset(q.x,q.y,q.c)
 end
end
