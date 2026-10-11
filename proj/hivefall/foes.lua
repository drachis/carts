-- foes.lua : the swarm. a foe rises behind the crest, hops the skyline,
-- and comes down the hill toward the mech.

-- `lead` is how far it slides sideways per unit of depth, for things
-- thrown from one place to land at another
function spawn_foe(spec,centre,z,phase,cell,lead)
 local foe=setmetatable({
  centre=centre,z=z,phase=phase,
  cell=cell or spec.cell,lead=lead or 0,
  hp=spec.hp,flash=0,age=0
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
 if spec.boss then
  boss=foes[#foes]
  boss.centre=0
  banner=150
  bark("big one inbound!")
  sfx(snd_roar)
  shake=6
 end
end

-- where a foe is, from its depth alone. the weave fades out near the
-- mech; fliers come down to the ground for the last stretch.
function place_foe(foe)
 local z=foe.z
 foe.x=foe.centre+foe.lead*(z-1)
  +foe.sway*sin(foe.phase+z/2.5)*min(1,(z-1)/1.5)
 if z>far_z then
  foe.h=(foe.fly+crest_hop)*(1-(z-far_z)*2.2)
 else
  foe.h=foe.fly*mid(0,(z-1.5)/2,1)+crest_hop*max(z-far_z+1)
 end
 foe.sx,foe.sy,foe.scale=project(foe.x,z,foe.h)
end

function update_foes()
 for foe in all(foes) do
  foe.z=max(foe.z-foe.speed,foe.halt)
  foe.flash-=1
  foe.age+=1
  if foe.z<3 and foe.track==1 then
   foe.centre+=mid(-0.2,player.x-foe.centre,0.2)
  end
  if foe.brood and foe.z<far_z and foe.age%foe.brood_every==0 then
   local brood=enemy_specs[foe.brood]
   if brood.track==1 then
    spawn_foe(brood,foe.x,foe.z,rnd())
   else
    spawn_foe(brood,player.x,foe.z,0,nil,(foe.x-player.x)/(foe.z-1))
   end
   burst(foe.sx,foe.sy-8*foe.size*foe.scale,6,11,1.5)
  end
  place_foe(foe)
  if foe.z<=1 then
   del(foes,foe)
   burst(foe.sx,foe.sy-6,8,foe.points>0 and 8 or 11,2)
   if abs(foe.x-player.x)<8+8*foe.size then
    hurt_player(foe.bite)
   elseif foe.points>0 then
    hurt_city(foe.bite/2)
   end
  end
 end
end

function hurt_foe(foe,amount)
 if foe.hp<=0 then return end
 foe.hp-=amount
 foe.flash=5
 local size=foe.size
 local x,y=foe.sx,foe.sy-8*size*foe.scale
 if foe.hp>0 then
  burst(x,y,2,7,1.5)
  return
 end
 del(foes,foe)
 add_score(foe.points,x,y)
 maybe_drop(foe)
 burst(x,y,6+size*8,8,1+size*1.5)
 burst(x,y,4+size*5,10,1+size)
 burst(x,y,4+size*6,2,1+size,0.12)
 ring(x,y,10*size*foe.scale+4,7,size>1 and 0.5)
 shake=max(shake,size*2)
 grid_flash=4
 if size>1.5 then
  freeze=6
  sfx(snd_boom)
 else
  sfx(snd_pop)
 end
 if foe.boss then
  dying,dying_x,dying_y,groups=150,x,y,{}
  freeze,white=30,4
 end
end

-- the boss comes apart over a couple of seconds, and takes the rest of
-- the swarm with it
function update_dying()
 dying-=1
 if dying%6==0 or dying==0 then
  local x,y=dying_x+rnd(50)-25,dying_y+rnd(50)-25
  burst(x,y,16,rnd{8,9,10,14},4)
  ring(x,y,12+rnd(20),7,0.6)
  shake=6
  sfx(snd_boom)
  if foes[1] then hurt_foe(foes[1],999) end
 end
 if dying==0 then
  for foe in all(foes) do hurt_foe(foe,999) end
  white=8
 end
end

-- a kill may leave something that slides down to the mech's line: bigger
-- foes and close kills leave more. what it is leans to what is needed:
-- plate when armour is low, else ammo for the emptiest gun, a charge of
-- alpha, or coolant.
function maybe_drop(foe)
 if #drops>5
  or rnd()>0.05+foe.points*0.02+(foe.z<2.2 and 0.3 or 0) then
  return
 end
 local kind,colour,weapon="cool",12
 local roll=rnd()
 if player.armor<player.max_armor*0.4 and roll<0.4 then
  kind,colour="plate",6
 elseif roll<0.6 then
  local emptiest=1
  for candidate in all(weapon_specs) do
   local fill=candidate.rounds/max(1,candidate.ammo)
   if candidate.wave<=wave and candidate.ammo>0 and fill<emptiest then
    emptiest,weapon=fill,candidate
   end
  end
  if weapon then kind,colour=weapon.name,weapon.colour end
 elseif roll<0.75 then
  kind,colour="alpha",7
 end
 add(drops,{x=foe.x,z=foe.z,kind=kind,colour=colour,weapon=weapon})
end

function update_drops()
 for drop in all(drops) do
  drop.z-=drop_speed
  if drop.z<=1 then
   del(drops,drop)
   if abs(drop.x-player.x)<16 then collect(drop) end
  end
 end
end

function collect(drop)
 local sx,sy=project(player.x,1,12)
 local weapon=drop.weapon
 ring(sx,sy,24,drop.colour,0.4)
 add(popups,{x=sx,y=sy-24,text="+"..drop.kind,life=50})
 sfx(snd_upgrade)
 if weapon then
  weapon.rounds=min(weapon.ammo,weapon.rounds+weapon.pack)
 elseif drop.kind=="plate" then
  player.armor=min(player.max_armor,player.armor+15)
 elseif drop.kind=="alpha" then
  charge=min(alpha_cost,charge+12)
 else
  -- coolant: the heat is gone, and none builds for a few seconds
  player.heat,player.overheated,player.chill=0,false,chill_frames
 end
end

function draw_drops()
 for drop in all(drops) do
  local sx,sy,scale=project(drop.x,drop.z,4+sin(tick/40)*2)
  line(sx,sy,sx,sy-14*scale,drop.colour)
  circfill(sx,sy,3*scale+1,drop.colour)
  circfill(sx,sy,2*scale,7)
  print(sub(drop.kind,1,1),sx-1,sy-14*scale-6,7)
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

function draw_cell(cell,x,y,size,flipped)
 sspr(cell%8*16,cell\8*16,16,16,x-size/2,y,size,size,flipped)
end

function draw_foes(behind_crest)
 for foe in all(foes) do
  if (foe.z>far_z)==behind_crest then
   local size=16*foe.size*foe.scale
   local frame=(tick\10+foe.phase*8)\1%2
   local top=foe.sy-size
   if foe.fly>0 and not behind_crest then
    local gx,gy=project(foe.x,foe.z,0)
    ovalfill(gx-size/3,gy-1,gx+size/3,gy+1,1)
   end
   if foe.points==0 then
    local gx,gy=project(foe.centre,1,0)
    if tick%8<4 then oval(gx-9,gy-3,gx+9,gy+3,8) end
   end
   if foe.flash>0 then
    for colour=1,15 do pal(colour,7) end
   end
   draw_cell(foe.cell+frame,foe.sx,top,size)
   for i,part in ipairs(foe.part_list) do
    draw_cell(part[1]+frame,
     foe.sx+part[2]*size/16,
     top+(part[3]+sin(tick/50+i/3)*1.5)*size/16,
     size,part[2]>0)
   end
   pal()
  end
 end
end
