-- effects.lua: single parameterized particle system
-- add_fx(x,y,n,dvx,dvy,ttl,ca,cb): n particles, velocity spread dvx/dvy,
--   ttl lifetime, alternating colors ca/cb
fx_list={}

function init_fx()
 fx_list={}
end

-- spd=velocity spread radius (±), bvy=base y-velocity, ca/cb=color pair
function add_fx(x,y,n,spd,bvy,ttl,ca,cb)
 for i=1,n do
  add(fx_list,{px=x*8+4+flr(rnd(5))-2,py=y*8+4,
   vx=rnd(spd*2)-spd,vy=bvy+rnd(spd*2)-spd,
   ttl=ttl,c=rnd()<0.5 and ca or cb})
 end
end

-- smoke: dark→grey→white puff that swells as it rises (ttl 40→0)
function add_smoke(x,y)
 add(fx_list,{px=x*8+2+rnd(5),py=y*8,
  vx=rnd(0.4)-0.2,vy=-0.3-rnd(0.3),ttl=40,sm=true})
end

function update_fx()
 local live={}
 for q in all(fx_list) do
  q.px+=q.vx q.py+=q.vy q.ttl-=1
  if q.ttl>0 then add(live,q) end
 end
 fx_list=live
end

function draw_fx()
 for q in all(fx_list) do
  if q.sm then
   -- radius swells 0→2, color lightens with age (dark→grey→white)
   circfill(q.px,q.py,(40-q.ttl)\14,
    q.ttl>26 and 5 or q.ttl>13 and 6 or 7)
  else
   pset(q.px,q.py,q.c)
  end
 end
end
