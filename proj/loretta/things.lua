function add_score(points)
 score+=points
end

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
 add_score(coin_points)
 sfx(snd_coin)
 puff(coin.x+3,coin.y+3,6,10)
end

function grab(thing,hero)
 if respawn==0 and abs(thing.x+3-hero.hx)<grab_reach and abs(thing.y+3-hero.hy)<grab_reach then _ENV["touch_"..thing.name](thing,hero) end
end
update_bone=grab

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
 if hearts<max_hearts then
  hearts+=1
  float_text("\135",hero.x+10,hero.y-8,8)
 else
  add_score(bone_points)
  float_text("munch!",hero.x,hero.y-8,7)
 end
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
 if squirrel.state then
  squirrel.x+=squirrel.vx
  squirrel.y+=squirrel.vy
  if squirrel.state=="bonked" then squirrel.vy+=0.15 end
  if squirrel.tree then
   for step=1,8 do
    if flag_at(squirrel.x+6,squirrel.y+11,0) then squirrel.y-=1 end
   end
   if not on_ledge(squirrel) and flag_at(squirrel.x+6,squirrel.y+40,0) then squirrel.y+=2 end
  end
  if squirrel.tree and (squirrel.x-squirrel.tree)*squirrel.vx>=0 then
   squirrel.trunk,squirrel.vy,squirrel.tree,squirrel.top=squirrel.tree-6,-squirrel_climb,nil,squirrel.y-squirrel_height
   sfx(snd_chitter)
   for drop=0,2 do
    new_thing(thing_specs[19],squirrel.x+drop*7-4,squirrel.y-30-drop*9,squirrel.y)
   end
  end
  if squirrel.top then
   squirrel.x,squirrel.vx=squirrel.trunk+sin(squirrel.age/squirrel_wind)*3,cos(squirrel.age/squirrel_wind)
   if squirrel.y<squirrel.top then
    squirrel.gone=true
    puff(squirrel.x+6,squirrel.y,10,11)
   end
  end
  if squirrel.y>140 then squirrel.gone=true end
  return
 end
 if abs(hero.x-squirrel.x)>squirrel_wake then return end
 if squirrel.vx==0 then squirrel.vx,squirrel.home=-squirrel_speed-squirrel_ramp*squirrel.x/level_w,squirrel.x end
 if squirrel.age%90<60 then
  local ahead=squirrel.vx<0 and squirrel.x-1 or squirrel.x+squirrel.w
  local below=squirrel.y+squirrel.h
  if flag_at(ahead,squirrel.y+6,0) or not (flag_at(ahead,below,0) or flag_at(ahead,below,1)) or abs(squirrel.x+squirrel.vx-squirrel.home)>squirrel_patrol then
   squirrel.vx=-squirrel.vx
  else
   squirrel.x+=squirrel.vx
  end
 end
end

function touch_squirrel(squirrel,hero)
 if squirrel.state then return end
 if hero.vy>0 and hero.y+hero_h-1<squirrel.y+6 then
  squirrel.state,squirrel.vx,squirrel.vy="bonked",hero.facing*0.5,-1.5
  hero.vy=hero.held&16>0 and -jump_a or -stomp_bounce
  hero.chain+=1
  local points=stomp_points*(1<<min(hero.chain-1,3))
  add_score(points)
  float_text(points.."0",squirrel.x,squirrel.y-8,10)
  puff(squirrel.x+6,squirrel.y,8,7)
  sfx(snd_stomp)
 else
  spook(squirrel,sgn(squirrel.x-hero.x))
 end
end

function spook(squirrel,direction)
 local tree,best=squirrel.x+direction*squirrel_run,30000
 for thing in all(things) do
  local gap=(thing.x+4-squirrel.x)*direction
  if thing.name=="tree" then
   if gap<squirrel_far then gap=5000-gap end
   if gap<best then tree,best=thing.x+4,gap end
  end
 end
 squirrel.state,squirrel.vx,squirrel.vy,squirrel.tree="spooked",sgn(tree-squirrel.x)*squirrel_flee,0,tree
 add_score(spook_points)
 float_text(spook_points.."0",squirrel.x,squirrel.y-8,10)
 sfx(snd_chitter)
end

function draw_squirrel(squirrel)
 local dir,links=sgn(squirrel.vx),squirrel.links or {}
 local body_x,body_y=squirrel.x+6-dir*2,squirrel.y+6-abs(sin(squirrel.x/squirrel_arc/2))*(squirrel.tree and 20 or 6)
 local x,y=body_x-dir*6,body_y
 squirrel.links=links
 for i=1,6 do
  local link=links[i] or {}
  links[i]=link
  follow(link,x,y,3,0.85,-0.12,x-dir*3,y-1,0.03)
  x,y=link.x,link.y
 end
 for pass=0,1 do
  for i=6,1,-1 do circfill(links[i].x,links[i].y,2+i/2-pass,pass*7+2) end
 end
 local head_x,head_y=body_x+dir*6,body_y-5
 for ear=-2,2,4 do
  tri(head_x+ear-3,head_y-1,head_x+ear+3,head_y-1,head_x+ear,head_y-9,2)
  tri(head_x+ear-1,head_y-2,head_x+ear+1,head_y-2,head_x+ear,head_y-6,9)
 end
 for pass=0,1 do
  circfill(body_x-dir*3,body_y,5-pass,2+pass*2)
  circfill(body_x+dir*2,body_y-1,4-pass,2+pass*2)
  circfill(head_x,head_y,4-pass,2+pass*2)
 end
 pset(head_x+dir*2,head_y,0)
 pset(head_x+dir*3,head_y+1,0)
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
    add_score(pet_points)
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
 shake=max(shake-1)
 for bit in all(puffs) do
  bit.x+=bit.vx
  bit.y+=bit.vy
  bit.vy+=0.05
  bit.life-=1
  if bit.life<0 then del(puffs,bit) end
 end
 for floater in all(floaters) do
  floater.y-=0.4
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
