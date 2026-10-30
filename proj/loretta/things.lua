function add_score(points)
 score+=points
end

function update_things(hero)
 for thing in all(things) do
  thing.age+=1
  local act=_ENV["update_"..thing.name]
  if act then act(thing,hero) end
  local touch=_ENV["touch_"..thing.name]
  if touch and respawn==0 and overlaps(hero,thing) then touch(thing,hero) end
  if thing.gone then del(things,thing) end
 end
end

function draw_things(back)
 for thing in all(things) do
  local draw=_ENV["draw_"..thing.name] or draw_prop
  if thing.back==back then draw(thing) end
 end
end

function draw_prop(prop)
 for op in all(shapes[prop.name]) do
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

function draw_coin(coin)
 local frame=({34,34,34,34,34,36,38,36})[(t()*8+coin.x/16)\1%8+1]
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

function touch_hydrant(hydrant)
 if not hydrant.lit then
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
  if squirrel.y>140 or squirrel.y<-16 then squirrel.gone=true end
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
  hero.paddle=paddle_frames
  local points=stomp_points*(1<<min(hero.chain-1,3))
  add_score(points)
  float_text(points.."0",squirrel.x,squirrel.y-8,10)
  puff(squirrel.x+6,squirrel.y,8,7)
  sfx(snd_stomp)
 else
  hurt_loretta(hero,squirrel.x+6)
 end
end

function spook(squirrel,direction)
 squirrel.state,squirrel.vx,squirrel.vy="spooked",direction*1.4,-1.2
 add_score(spook_points)
 float_text(spook_points.."0",squirrel.x,squirrel.y-8,10)
 sfx(snd_chitter)
end

function draw_squirrel(squirrel)
 local sprite=squirrel.state=="spooked" and 108 or squirrel.age%90<60 and 104+squirrel.age\8%2*2 or 104
 spr(sprite,squirrel.x-2,squirrel.y-4,2,2,squirrel.vx<0,squirrel.state=="bonked")
 if squirrel.state=="spooked" then print("!",squirrel.x+5,squirrel.y-12,7) end
end

function update_neighbour(neighbour,hero)
 if neighbour.petting>0 then
  neighbour.petting-=1
  hero.happy=30
  if neighbour.petting%15==0 then float_text("\135",hero.x+8+neighbour.petting%8,hero.y-8,14) end
  if neighbour.petting==0 then
   neighbour.petted=true
   hearts=min(hearts+pet_hearts,max_hearts)
   add_score(pet_points)
   float_text("good girl!",neighbour.x-12,neighbour.y-16,7)
  end
 elseif not neighbour.petted and hero.resting and abs(hero.x+12-neighbour.x-8)<pet_range then
  neighbour.petting=pet_frames
  sfx(snd_pet)
 end
end

function draw_neighbour(neighbour)
 local x,feet=neighbour.x,neighbour.y
 for leg=1,9,8 do
  rectfill(x+leg,0,x+leg+5,feet+4,13)
  line(x+leg+5,0,x+leg+5,feet+4,5)
  rectfill(x+leg-1,feet-2,x+leg+6,feet,2)
 end
 spr(46,x,feet+1,2,1)
 if neighbour.petting>0 then
  local reach=min(1,(pet_frames-neighbour.petting)/15)
  local hand_x,hand_y=hero.x+8+hero.facing*8,(hero.y-10)*reach-8+(t()*4%1<0.5 and 2 or 0)
  rectfill(hand_x+1,0,hand_x+6,hand_y,5)
  rectfill(hand_x+2,0,hand_x+5,hand_y,6)
  spr(45,hand_x,hand_y)
 elseif not neighbour.petted and abs(hero.x-x)<48 then
  print("\135?",x+4,feet-12+sin(t()),14)
 end
end

function touch_gate()
 win()
end

function draw_gate(gate)
 local x,base=gate.x+4,gate.y+gate.h
 circfill(x-35,base-22,9,5)
 circfill(x+35,base-22,9,5)
 circfill(x,base-35,17,5)
 circ(x,base-35,17,13)
 rectfill(x-18,base-35,x+18,base-22,6)
 rectfill(x-45,base-22,x+45,base-1,6)
 rectfill(x-45,base-4,x+45,base-1,13)
 for column=-40,40,9 do
  line(x+column,base-19,x+column,base-5,13)
 end
 circfill(x,base-12,5,1)
 rectfill(x-5,base-12,x+5,base-1,1)
 for window=-1,1,2 do
  rectfill(x+window*10,base-30,x+window*10+1,base-27,10)
 end
end

function draw_sign(sign)
 local x,y=sign.x,sign.y
 rectfill(x+3,y-1,x+4,y+7,4)
 rectfill(x-9,y-15,x+16,y-1,4)
 rect(x-9,y-15,x+16,y-1,2)
 print("los \145",x-6,y-13,15)
 print("feliz",x-6,y-7,15)
end

function start_bark(hero)
 add(barks,{x=hero.x+12+hero.facing*14,y=hero.y+6,direction=hero.facing,distance=0})
 float_text("woof!",hero.x+(hero.facing>0 and 26 or -18),hero.y-8,7)
end

function update_barks()
 for bark in all(barks) do
  bark.distance+=bark_speed
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
