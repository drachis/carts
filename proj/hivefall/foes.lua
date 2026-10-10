-- foes.lua : the swarm. a foe rises behind the crest, hops the skyline,
-- and comes down the hill toward the mech.

function spawn_foe(spec,centre,z,phase,cell)
 local foe=setmetatable({
  centre=centre,z=z,phase=phase,
  cell=cell or spec.cell,
  hp=spec.hp,flash=0
 },spec)
 place_foe(foe)
 return add(foes,foe)
end

-- a chain is one creature in segments: every segment weaves along the
-- same path, a little behind the one before.
function spawn_group(name,count)
 local spec=enemy_specs[name]
 local centre,phase=rnd(90)-45,rnd()
 for i=1,count do
  if spec.chain==1 then
   spawn_foe(spec,centre,far_z+0.7+i*0.2,phase,i>1 and spec.tail)
  else
   spawn_foe(spec,mid(-58,centre+rnd(60)-30,58),
    far_z+0.8+rnd(count*0.15),rnd())
  end
 end
end

-- where a foe is, from its depth alone. the weave fades out near the
-- mech; fliers come down to the ground for the last stretch.
function place_foe(foe)
 local z=foe.z
 foe.x=foe.centre+foe.sway*sin(foe.phase+z/2.5)*min(1,(z-1)/1.5)
 if z>far_z then
  foe.h=(foe.fly+crest_hop)*(1-(z-far_z)*2.2)
 else
  foe.h=foe.fly*mid(0,(z-1.5)/2,1)+crest_hop*max(0,z-far_z+1)
 end
 foe.sx,foe.sy,foe.scale=project(foe.x,z,foe.h)
end

function update_foes()
 for foe in all(foes) do
  foe.z-=foe.speed
  foe.flash-=1
  if foe.z<3 then
   foe.centre+=mid(-0.2,player.x-foe.centre,0.2)
  end
  if foe.brood and foe.z<far_z and tick%180==0 then
   spawn_foe(enemy_specs[foe.brood],foe.x,foe.z,rnd())
   burst(foe.sx,foe.sy,6,11,1.5)
  end
  place_foe(foe)
  if foe.z<=1 then
   del(foes,foe)
   burst(foe.sx,foe.sy-6,8,8,2)
   if abs(foe.x-player.x)<8+8*foe.size then
    hurt_player(foe.bite)
   end
  end
 end
end

function hurt_foe(foe,amount)
 if foe.hp<=0 then return end
 foe.hp-=amount
 foe.flash=5
 local x,y=foe.sx,foe.sy-8*foe.size*foe.scale
 if foe.hp>0 then
  burst(x,y,2,7,1.5)
  return
 end
 del(foes,foe)
 score+=foe.points
 burst(x,y,6+foe.size*10,8,1+foe.size*1.5)
 burst(x,y,4+foe.size*6,10,1+foe.size)
 ring(x,y,10*foe.size*foe.scale+4,7)
 shake=max(shake,foe.size*2)
 grid_flash=4
 if foe.size>1.5 then
  freeze=5
  sfx(snd_boom)
 else
  sfx(snd_pop)
 end
end

-- far ones first, so near ones are drawn over them
function sort_foes()
 for i=2,#foes do
  local foe,j=foes[i],i-1
  while j>0 and foes[j].z<foe.z do
   foes[j+1]=foes[j]
   j-=1
  end
  foes[j+1]=foe
 end
end

function draw_foes(behind_crest)
 for foe in all(foes) do
  if (foe.z>far_z)==behind_crest then
   local size=16*foe.size*foe.scale
   local frame=foe.cell+(tick\10+foe.phase*8)\1%2
   if foe.fly>0 and not behind_crest then
    local gx,gy=project(foe.x,foe.z,0)
    ovalfill(gx-size/3,gy-1,gx+size/3,gy+1,1)
   end
   if foe.flash>0 then
    for colour=1,15 do pal(colour,7) end
   end
   sspr(frame%8*16,frame\8*16,16,16,foe.sx-size/2,foe.sy-size,size,size)
   pal()
  end
 end
end
