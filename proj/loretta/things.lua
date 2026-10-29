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
  local draw=_ENV["draw_"..thing.name]
  if draw and thing.back==back then draw(thing) end
 end
end

function touch_coin(coin)
 coin.gone=true
 coins+=1
 add_score(coin_points)
 sfx(snd_coin)
 puff(coin.x+3,coin.y+3,6,10)
end

function draw_coin(coin)
 spr(({36,36,36,36,36,37,38,37})[(t()*8+coin.x/16)\1%8+1],coin.x-1,coin.y-1+sin(t()/2+coin.x/40))
end

function touch_bone(bone,hero)
 bone.gone=true
 sfx(snd_munch)
 if hearts<max_hearts then
  hearts+=1
  float_text("\135",hero.x+2,hero.y-6,8)
 else
  add_score(bone_points)
  float_text("munch!",hero.x-4,hero.y-6,7)
 end
end

function draw_bone(bone)
 spr(39,bone.x,bone.y-2+sin(t()/2+bone.x/30))
end

function touch_hydrant(hydrant)
 if not hydrant.lit then
  hydrant.lit=true
  respawn_x,respawn_y=hydrant.x,hydrant.y+1
  sfx(snd_check)
  puff(hydrant.x+4,hydrant.y,8,10)
  float_text("sniff!",hydrant.x-6,hydrant.y-8,7)
 end
end

function draw_hydrant(hydrant)
 spr(hydrant.lit and 44 or 43,hydrant.x,hydrant.y)
 if hydrant.lit and t()%1<0.5 then spr(47,hydrant.x+3,hydrant.y-7) end
end

function update_squirrel(squirrel)
 if squirrel.state then
  squirrel.x+=squirrel.vx
  squirrel.y+=squirrel.vy
  if squirrel.state=="bonked" then squirrel.vy+=0.15 end
  if squirrel.y>140 or squirrel.y<-16 then squirrel.gone=true end
  return
 end
 if squirrel.vx==0 then squirrel.vx=-squirrel_speed end
 if squirrel.age%90<60 then
  local ahead=squirrel.vx<0 and squirrel.x-1 or squirrel.x+squirrel.w
  local below=squirrel.y+squirrel.h
  if flag_at(ahead,squirrel.y+3,0) or not (flag_at(ahead,below,0) or flag_at(ahead,below,1)) then
   squirrel.vx=-squirrel.vx
  else
   squirrel.x+=squirrel.vx
  end
 end
end

function touch_squirrel(squirrel,hero)
 if squirrel.state then return end
 if hero.vy>0 and hero.y+hero_h-1<squirrel.y+4 then
  squirrel.state,squirrel.vx,squirrel.vy="bonked",hero.facing*0.5,-1.5
  hero.vy=hero.held&16>0 and -jump_a or -stomp_bounce
  hero.chain+=1
  hero.paddle=paddle_frames
  local points=stomp_points*(1<<min(hero.chain-1,3))
  add_score(points)
  float_text(points.."0",squirrel.x-2,squirrel.y-6,10)
  puff(squirrel.x+3,squirrel.y,6,7)
  sfx(snd_stomp)
 else
  hurt_loretta(hero,squirrel.x+3)
 end
end

function spook(squirrel,direction)
 squirrel.state,squirrel.vx,squirrel.vy="spooked",direction*1.4,-1.2
 add_score(spook_points)
 float_text(spook_points.."0",squirrel.x-2,squirrel.y-6,10)
 sfx(snd_chitter)
end

function draw_squirrel(squirrel)
 local sprite=squirrel.state=="spooked" and 42 or squirrel.age%90<60 and 40+squirrel.age\6%2 or 40
 spr(sprite,squirrel.x,squirrel.y-1,1,1,squirrel.vx<0,squirrel.state=="bonked")
 if squirrel.state=="spooked" then print("!",squirrel.x+3,squirrel.y-8,7) end
end

function update_neighbour(neighbour,hero)
 if neighbour.petting>0 then
  neighbour.petting-=1
  if neighbour.petting%15==0 then float_text("\135",hero.x+2+neighbour.petting%4,hero.y-6,14) end
  if neighbour.petting==0 then
   neighbour.petted=true
   hearts=min(hearts+pet_hearts,max_hearts)
   add_score(pet_points)
   float_text("good girl!",neighbour.x-16,neighbour.y-8,7)
  end
 elseif not neighbour.petted and hero.state=="sit" and abs(hero.x+6-neighbour.x-4)<pet_range then
  neighbour.petting=pet_frames
  sfx(snd_pet)
 end
end

function draw_neighbour(neighbour)
 spr(neighbour.petting>0 and t()*4%2<1 and 49 or 48,neighbour.x,neighbour.y,1,2)
 if not neighbour.petted and neighbour.petting==0 and abs(hero.x-neighbour.x)<40 then
  print("\135?",neighbour.x-2,neighbour.y-9+sin(t()),14)
 end
end

function touch_gate()
 win()
end

function draw_gate(gate)
 local x,base=gate.x+4,gate.y+gate.h
 circfill(x-22,base-14,6,5)
 circfill(x+22,base-14,6,5)
 circfill(x,base-22,11,5)
 circ(x,base-22,11,13)
 rectfill(x-11,base-22,x+11,base-14,6)
 rectfill(x-28,base-14,x+28,base-1,6)
 rectfill(x-28,base-3,x+28,base-1,13)
 for column=-24,24,6 do
  line(x+column,base-12,x+column,base-4,13)
 end
 circfill(x,base-8,3,1)
 rectfill(x-3,base-8,x+3,base-1,1)
 for window=-1,1,2 do
  pset(x+window*6,base-18,10)
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
 add(barks,{x=hero.x+6+hero.facing*6,y=hero.y+3,direction=hero.facing,distance=0})
 float_text("woof!",hero.x+(hero.facing>0 and 10 or -16),hero.y-8,7)
end

function update_barks()
 for bark in all(barks) do
  bark.distance+=bark_speed
  local front=bark.x+bark.direction*bark.distance
  for thing in all(things) do
   if thing.name=="squirrel" and not thing.state and abs(thing.x+3.5-front)<6 and abs(thing.y+3.5-bark.y)<10 then
    spook(thing,bark.direction)
   end
  end
  if bark.distance>=bark_reach then del(barks,bark) end
 end
end

function draw_barks()
 for bark in all(barks) do
  for ring=0,2 do
   local radius=bark.distance-ring*5
   if radius>0 then
    for angle=-0.12,0.12,0.03 do
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
