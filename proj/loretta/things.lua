function update_things(hero)
 for thing in all(things) do
  thing.age+=1
  local act=_ENV["update_"..thing.name]
  if act then act(thing,hero) end
  local touch=_ENV["touch_"..thing.name]
  if touch and not thing.gone and respawn==0 and overlaps(hero,thing) then touch(thing,hero) end
  if thing.gone then del(things,thing) end
 end
end

function draw_things(back)
 for thing in all(things) do
  local draw=_ENV["draw_"..thing.name] or draw_prop
  if thing.back==back then draw(thing) end
 end
end

function draw_slot(slot)
 local kinds,seed=slot_kinds[slot.name],slot.x\8+slot.x\256*5+level*3
 pal(15,walls[seed%4+1])
 pal(8,roofs[seed*3%4+1])
 draw_prop(slot,kinds[seed*7%#kinds+1])
 pal(15,15)
 pal(8,8)
end
draw_house,draw_tree,draw_decor=draw_slot,draw_slot,draw_slot

function praise(x,y)
 float_text(praises[(x\8+level)%#praises+1],x,y,7)
end

function draw_prop(prop,shape)
 for op in all(shapes[shape or prop.name]) do
  local kind,a,b,c,d,e=unpack(op)
  local x,y=prop.x+a,prop.y+b
  if kind=="r" then rectfill(x,y,prop.x+c,prop.y+d,e)
  elseif kind=="b" then rect(x,y,prop.x+c,prop.y+d,e)
  elseif kind=="l" then line(x,y,prop.x+c,prop.y+d,e)
  elseif kind=="c" then circfill(x,y,c,d)
  elseif kind=="t" then print(d,x,y,c)
  elseif kind=="p" then
   for petal=1,8 do pset(x+(petal*13+t()*6)%c,y+(petal*29+t()*10)%d,e) end
  end
 end
end

function touch_coin(coin,hero)
 coin.gone,hero.happy=true,30
 coins+=1
 if coins%50==0 then new_thing(thing_specs.bone,view.x+36,-14,1) end
 score+=coin_points
 sfx(snd_coin)
 puff(coin.x+3,coin.y+3,6,10)
end

function grab(thing,hero)
 if respawn==0 and abs(thing.x+3-hero.hx)<grab_reach and abs(thing.y+3-hero.hy)<grab_reach then _ENV["touch_"..thing.name](thing,hero) end
end

function update_bone(bone,hero)
 if bone.land then
  bone.x+=(hero.hx-bone.x)/12
  bone.y+=(hero.hy-bone.y)/12
 end
 grab(bone,hero)
end

function update_coin(coin,hero)
 coin.y=min(coin.y+1,coin.land or coin.y)
 grab(coin,hero)
end

function draw_coin(coin)
 local frame=coin_frames[(t()*8+coin.x/16)\1%8+1]
 sspr(frame%16*8,frame\16*8,16,16,coin.x-1,coin.y-1+sin(t()/2+coin.x/40),8,8)
end

function touch_bone(bone,hero)
 bone.gone=true
 sfx(snd_munch)
 hearts=min(hearts+1,max_hearts)
 float_text("\135",hero.x+10,hero.y-8,8)
end

function draw_bone(bone)
 spr(40,bone.x-1,bone.y-1+sin(t()/2+bone.x/30),2,1)
end

function update_hydrant(hydrant,hero)
 if not hydrant.lit and hero.x+12>hydrant.x and respawn==0 then
  hydrant.lit=true
  respawn_x,respawn_y=hydrant.x-7,hydrant.y+hydrant.h-hero_h
  sfx(snd_check)
  puff(hydrant.x+5,hydrant.y,10,10)
  float_text("sniff!",hydrant.x-6,hydrant.y-10,7)
 end
end

function draw_hydrant(hydrant)
 spr(hydrant.lit and 32 or 110,hydrant.x-3,hydrant.y-2,2,2)
 if hydrant.lit and t()%1<0.5 then spr(44,hydrant.x+1,hydrant.y-10) end
end

function update_squirrel(squirrel,hero)
 if not squirrel.state and abs(hero.x-squirrel.x)>squirrel_wake then return end
 if squirrel.top then
  squirrel.y-=squirrel_climb
  squirrel.x,squirrel.vx=squirrel.trunk+sin(squirrel.age/squirrel_wind)*3,cos(squirrel.age/squirrel_wind)
  if squirrel.y<squirrel.top then
   squirrel.gone=true
   puff(squirrel.x+6,squirrel.y,10,11)
  end
  return
 end
 if not squirrel.state and abs(hero.x-squirrel.x)<squirrel_gap then spook(squirrel,sgn(squirrel.x-hero.x)) end
 if squirrel.vx==0 then squirrel.vx,squirrel.home=-squirrel_speed,squirrel.x end
 squirrel.x+=squirrel.vx
 for step=1,8 do
  if flag_at(squirrel.x+6,squirrel.y+11,0) then squirrel.y-=1 end
 end
 if not on_ledge(squirrel) and flag_at(squirrel.x+6,squirrel.y+40,0) then squirrel.y+=2 end
 local dir=sgn(squirrel.vx)
 if not squirrel.tree then
  if abs(squirrel.x-squirrel.home)>squirrel_patrol then squirrel.vx=-squirrel.vx end
  return
 end
 if not lead or not lead.tree then lead=squirrel end
 local leading=lead==squirrel
 local gap=(squirrel.x-hero.x)*dir
 squirrel.vx=dir*mid(squirrel_flee,abs(hero.vx)+(squirrel_gap+(leading and 0 or 32)-gap)*0.04,squirrel_dash)
 squirrel.leap=flag_at(squirrel.x+6+dir*20,squirrel.y+6,0) and 1 or squirrel.leap*0.96
 squirrel.held=abs(gap)<(squirrel.held and 100 or 80)
 if leading and squirrel.held then chase_x=squirrel.x+6 end
 if leading and abs(gap)<100 then
  chase+=1
  hero.happy=30
  if chase%30==0 then
   pot+=(100-abs(gap))\20
   puff(hero.x+4,hero.y+14,2+chase\60,7)
  end
 end
 if (squirrel.x-squirrel.tree)*dir>=0 then
  squirrel.trunk,squirrel.tree,squirrel.top=squirrel.tree-6,nil,squirrel.y-squirrel_height
  sfx(snd_chitter)
  squirrel.gone=squirrel.dive
  if squirrel.dive then puff(squirrel.x+6,squirrel.y+6,12,11) end
  for drop=0,min(2+chase\120,6) do
   new_thing(thing_specs[19],squirrel.x+drop*7-4,squirrel.y-30-drop*9,squirrel.y)
  end
  if leading then
   add(floaters,{text=pot.."0",x=squirrel.x,y=squirrel.y-16,life=40,colour=10,fly=pot})
   chase,pot=0,0
  end
 end
end

function spook(squirrel,direction)
 local tree,best=squirrel.x+direction*squirrel_run,30000
 for thing in all(things) do
  local gap=(thing.x+4-squirrel.x)*direction
  if thing.name=="tree" or thing.name=="decor" then
   if gap<squirrel_far then gap=5000-gap end
   if gap<best then tree,best,squirrel.dive=thing.x+4,gap,thing.name=="decor" end
  end
 end
 squirrel.state,squirrel.vx,squirrel.tree,squirrel.leap="spooked",sgn(tree-squirrel.x)*squirrel_flee,tree,0
 sfx(snd_chitter)
end

function draw_squirrel(squirrel)
 local dir,links=sgn(squirrel.vx),squirrel.links
 local hop,height=squirrel.x/squirrel_arc/2,squirrel.tree and 20+squirrel.leap*24 or 6
 local air=abs(sin(hop))
 local reach,mid_x,base=1.5+air*4,squirrel.x+6,squirrel.y+6
 local front_x,front_y,back_x,back_y=mid_x+dir*reach,base-air*height,mid_x-dir*reach,base-abs(sin(hop-dir*squirrel_lag))*height
 local x,y,mid_y=back_x-dir*3,back_y,(front_y+back_y)/2
 for i=1,6 do
  local link=links[i] or {}
  links[i]=link
  follow(link,x,y,3,0.85,-0.12,x-dir*3,y-1,0.03)
  x,y=link.x,link.y
 end
 for pass=0,1 do
  for i=6,1,-1 do circfill(links[i].x,links[i].y,2+i/2-pass,pass*13+2) end
 end
 local head_x,head_y=front_x+dir*3,front_y-4
 for ear=-2,2,4 do
  tri(head_x+ear-3,head_y-1,head_x+ear+3,head_y-1,head_x+ear,head_y-8,2)
 end
 for pass=0,1 do
  circfill(back_x,back_y,6-air-pass,2+pass*7)
  circfill(mid_x,mid_y,4-pass,2+pass*7)
  circfill(front_x,front_y,5-air-pass,2+pass*7)
  circfill(head_x,head_y,4-pass,2+pass*7)
 end
 circfill(mid_x,mid_y+1,2,7)
 pset(head_x+dir,head_y,0)
 if lead==squirrel and squirrel.tree and pot>0 then outlined(pot.."0",head_x-4,head_y-16,10) end
end

function update_neighbour(neighbour,hero)
 neighbour.step*=neighbour.petting>0 and 1 or 0.94
 if neighbour.petting>0 then
  neighbour.petting-=1
  hero.happy=30
  neighbour.step+=(hero.hx+sgn(neighbour.x+8-hero.hx)*22-8-neighbour.x-neighbour.step)/12
  local beat=neighbour.petting%40
  if beat<24 and beat%8==0 then
   hero.flop=6
   for ear in all(hero.ears) do ear.x+=rnd(6)-3 end
   float_text("\135",hero.hx-3+beat%3,hero.hy-24,14)
  end
  if neighbour.petting==0 then
   if not neighbour.petted then
    hearts=min(hearts+pet_hearts,max_hearts)
    score+=pet_points
   end
   neighbour.petted=true
   praise(neighbour.x-24,neighbour.y-16)
  end
 elseif (not neighbour.petted or rnd(pet_again)<1) and hero.resting and abs(hero.x+12-neighbour.x-8)<pet_range then
  neighbour.petting=pet_frames
  sfx(snd_pet)
 end
end

function draw_neighbour(neighbour)
 local x,feet,seed=neighbour.x+neighbour.step,neighbour.y,neighbour.x\8
 local shirt,arm=cloths[seed%#cloths+1],hero.hx>x+8 and 18 or -6
 pal(15,skins[seed%3+1])
 pal(14,shirt)
 sspr(24+seed%5*8,48,8,16,x-4,-24,24,feet+28)
 spr(46,x,feet+1,2,1)
 local hand_x,hand_y=x+arm+(arm>0 and 0 or -12),feet-50
 if neighbour.petting>0 then
  local reach,beat=min(1,(pet_frames-neighbour.petting)/20),neighbour.petting%40
  hand_x+=(hero.hx-8-hand_x)*reach
  hand_y+=(hero.hy-22+(beat<24 and beat%8<4 and 3 or 0)-hand_y)*reach
 end
 for side=0,3 do line(x+arm+side,-24,hand_x+5+side,hand_y+2,shirt) end
 sspr(104,16,8,8,hand_x,hand_y,16,16)
 if not neighbour.petted then spr(40,hand_x,hand_y+12,2,1) end
 pal(15,15)
 pal(14,14)
end

function touch_gate()
 win()
end

function draw_gate(gate)
 local last=level==#levels
 draw_prop(gate,last and "observatory" or "arch")
 if not last then
  local text=landmarks[level]
  print(text,gate.x+4-#text*2,gate.y+3,7)
 end
end

function start_bark(hero)
 add(barks,{x=hero.x+12+hero.facing*14,y=hero.y+6,direction=hero.facing,distance=0})
 float_text("woof!",hero.x+(hero.facing>0 and 26 or -18),hero.y-8,7)
end

function update_barks()
 for bark in all(barks) do
  bark.distance+=bark_speed
  bark.x,bark.y=hero.x+12+bark.direction*14,hero.y+6
  local front=bark.x+bark.direction*bark.distance
  for thing in all(things) do
   if thing.name=="squirrel" and not thing.state and abs(thing.x+6-front)<8 and abs(thing.y+6-bark.y)<12 then
    spook(thing,bark.direction)
   end
  end
  if bark.distance>=bark_reach then del(barks,bark) end
 end
end

function draw_barks()
 for bark in all(barks) do
  for ring=0,2 do
   local radius=bark.distance-ring*6
   if radius>0 then
    for angle=-0.12,0.12,0.02 do
     pset(bark.x+bark.direction*cos(angle)*radius,bark.y+sin(angle)*radius,ring==0 and 7 or 6)
    end
   end
  end
 end
end

function puff(x,y,count,colour)
 for i=1,count do
  local angle=i/count+count*0.07
  add(puffs,{x=x,y=y,vx=cos(angle)*0.7,vy=sin(angle)*0.5-0.4,life=12+i%3*4,colour=colour})
 end
end

function float_text(text,x,y,colour)
 add(floaters,{text=text,x=x,y=y,life=40,colour=colour})
end

function update_effects()
 for bit in all(puffs) do
  bit.x+=bit.vx
  bit.y+=bit.vy
  bit.vy+=0.05
  bit.life-=1
  if bit.life<0 then del(puffs,bit) end
 end
 for floater in all(floaters) do
  floater.y-=0.4
  if floater.fly then
   floater.x+=(view.x+100-floater.x)/8
   floater.y+=(-14-floater.y)/8
   if floater.life==0 then score+=floater.fly end
  end
  floater.life-=1
  if floater.life<0 then del(floaters,floater) end
 end
end

function draw_effects()
 for bit in all(puffs) do
  pset(bit.x,bit.y,bit.colour)
 end
 for floater in all(floaters) do
  print(floater.text,floater.x+1,floater.y+1,0)
  print(floater.text,floater.x,floater.y,floater.colour)
 end
end
