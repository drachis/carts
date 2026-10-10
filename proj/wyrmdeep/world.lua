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

function standing(tile)
 return fget(tile,0) and fget(tile)&22>0
end

function unseat(tx,ty,tile)
 if fget(tile,0) then
  razed+=1
  add(falls,{tx=tx,ty=ty-1,wait=4})
  add(falls,{tx=tx-1,ty=ty,wait=7})
  add(falls,{tx=tx+1,ty=ty,wait=7})
 end
end

function ignite(tx,ty)
 local tile=mget(tx,ty)
 if fget(tile,1) then
  mset(tx,ty,tile_fire)
  add(fires,{tx=tx,ty=ty,life=burn_frames+flr(rnd(16)),remains=tile+16})
  unseat(tx,ty,tile)
 end
end

function raze(tx,ty,tile)
 mset(tx,ty,tile+16)
 burst(tx*8+4,ty*8+4,5,8)
 if rnd()<.4 then coins(tx*8+4,ty*8+4,1) end
 sfx(snd_crash)
 unseat(tx,ty,tile)
end

function ram(x,y,charging)
 local tx,ty=x\8,y\8
 local tile=mget(tx,ty)
 if fget(tile,2) or charging and fget(tile,4) then
  raze(tx,ty,tile)
  jolt(charging and 4 or 1.5)
 end
end

function update_fire()
 for fall in all(falls) do
  fall.wait-=1
  if fall.wait<=0 then
   del(falls,fall)
   local tile=mget(fall.tx,fall.ty)
   if standing(tile) and not fget(mget(fall.tx,fall.ty+1),0) then
    raze(fall.tx,fall.ty,tile)
    jolt(1)
   end
  end
 end
 for fire in all(fires) do
  local tx,ty=fire.tx,fire.ty
  fire.life-=1
  if rnd()<.25 then
   add_particle(tx*8+rnd(8),ty*8+2,rnd()-.5,-.4,12+rnd(8),"fire")
  end
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

function build_block()
 local kind=blocks[min(stage+block,#blocks)]
 local tx=block_from+8
 while tx<block_to-8 do
  local rows=split(stamps[rnd(split(kind.stamps,"+"))].rows,":",false)
  for r,row in ipairs(rows) do
   for c=1,#row do
    local char=row[c]
    local x,y=tx+c-1,stage*16+12-#rows+r
    local name=placed[char]
    if tiles[char] then
     mset(x,y,tiles[char])
    elseif relic_specs[name] then
     add(relics,setmetatable({x=x*8+4,y=y*8+4},relic_specs[name]))
    elseif name then
     spawn_unit(name,x*8+4,y*8+4)
    end
   end
  end
  tx+=#rows[1]+1+flr(rnd(2+(1-dragon.hp/dragon.max_hp)*8))
 end
 if block_to<128 then
  for ty=0,12 do
   mset(block_to,stage*16+ty,tile_ward)
  end
 end
end

function update_relics()
 for relic in all(relics) do
  if dragon_distance(relic.x,relic.y)<9 then
   del(relics,relic)
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
