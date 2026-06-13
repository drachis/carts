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

function update_fx()
 local live={}
 for q in all(fx_list) do
  q.px+=q.vx q.py+=q.vy q.ttl-=1
  if q.ttl>0 then add(live,q) end
 end
 fx_list=live
end

function draw_fx()
 for q in all(fx_list) do pset(q.px,q.py,q.c) end
end
