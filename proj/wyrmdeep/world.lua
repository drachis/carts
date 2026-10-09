function solid(x,y)
 return fget(mget(x\8,y\8),0)
end

function blocked(x,y)
 return solid(x-3,y-3) or solid(x+3,y-3) or solid(x-3,y+3) or solid(x+3,y+3)
end

function slide(body,dx,dy)
 local steps=ceil(max(abs(dx),abs(dy)))
 local reach=body.reach or 0
 local hit_x,hit_y
 for i=1,steps do
  local x=body.x+dx/steps
  if blocked(x-reach,body.y) or blocked(x+reach,body.y) then
   hit_x,dx=true,0
  else
   body.x+=dx/steps
  end
  local y=body.y+dy/steps
  if blocked(body.x-reach,y) or blocked(body.x+reach,y) then
   hit_y,dy=true,0
  else
   body.y+=dy/steps
  end
 end
 return hit_x,hit_y
end

function sight(from_x,from_y,to_x,to_y)
 for i=0,1,.125 do
  if solid(from_x+(to_x-from_x)*i,from_y+(to_y-from_y)*i) then return false end
 end
 return true
end

function ignite(tx,ty)
 local tile=mget(tx,ty)
 if fget(tile,1) then
  mset(tx,ty,tile_fire)
  add(fires,{tx=tx,ty=ty,life=burn_frames+flr(rnd(16)),remains=tile+16})
 end
end

function ram(x,y)
 local tx,ty=x\8,y\8
 local tile=mget(tx,ty)
 if fget(tile,2) then
  mset(tx,ty,tile+16)
  burst(tx*8+4,ty*8+4,6,8)
  sfx(snd_crash)
  jolt(4,2)
 end
end

function update_fire()
 for fire in all(fires) do
  local tx,ty=fire.tx,fire.ty
  fire.life-=1
  if fire.life==spread_at then
   ignite(tx-1,ty)
   ignite(tx+1,ty)
   ignite(tx,ty-1)
   ignite(tx,ty+1)
  elseif fire.life<=0 then
   mset(tx,ty,fire.remains)
   del(fires,fire)
  end
 end
end

function draw_fire()
 for fire in all(fires) do
  draw_flames(fire.tx*8,fire.ty*8,8,3)
 end
end

function break_ward(tile)
 for i=0,8191 do
  if mget(i%128,i\128)==tile then
   mset(i%128,i\128,0)
  end
 end
 announce("a seal is broken",150)
end

function populate()
 units,shots,relics={},{},{}
 relic_total=0
 for row in all(split(spawn_text,"\n")) do
  local name,x,y=unpack(split(row))
  if relic_specs[name] then
   relic_total+=1
   if not taken[row] then
    add(relics,setmetatable({x=x,y=y,key=row},relic_specs[name]))
   end
  elseif unit_specs[name] and not slain[row] then
   spawn_unit(name,x,y).key=row
  end
 end
end

function update_relics()
 for relic in all(relics) do
  if dragon_distance(relic.x,relic.y)<9 then
   del(relics,relic)
   taken[relic.key]=true
   relic_count+=1
   grant(relic.stats)
   announce(relic.text,120)
   sfx(snd_fanfare)
   ring(relic.x,relic.y,24)
   jolt(2,4)
  end
 end
end

function draw_relics()
 for relic in all(relics) do
  spr(relic.sprite,relic.x-4,relic.y-4+sin(frame/40)*1.5)
 end
end
