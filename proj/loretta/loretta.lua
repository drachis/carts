function new_loretta(x,y)
 return {x=x,y=y,w=hero_w,h=hero_h,vx=0,vy=0,facing=1,coyote=0,buffer=0,held=63,paddle=0,drop=0,idle=0,bark=0,cool=0,hurt=0,chain=0,squash=0,stride=0,state="stand"}
end

function read_input()
 local input=0
 for button=0,5 do
  if btn(button) then input|=1<<button end
 end
 return input
end

function toward(value,target,step)
 return value<target and min(value+step,target) or max(value-step,target)
end

function slide(hero,dx,dy)
 local amount=dx+dy
 while amount!=0 do
  local part=mid(-1,amount,1)
  amount-=part
  local x,y=hero.x+(dx!=0 and part or 0),hero.y+(dy!=0 and part or 0)
  local feet=flr(y)+hero_h-1
  if area_has(x,y,hero_w,hero_h,0) or dy>0 and hero.drop==0 and feet>flr(hero.y)+hero_h-1 and feet%8==0 and area_has(x,feet,hero_w,1,1) then
   if dx!=0 then hero.x=flr(hero.x) else hero.y=flr(hero.y) end
   return true
  end
  hero.x,hero.y=x,y
 end
end

function update_loretta(hero,input)
 local pressed=input&~hero.held
 hero.held=input
 local x_intent=(input&2>0 and 1 or 0)-(input&1>0 and 1 or 0)
 local jump_held,down=input&16>0,input&8>0
 local ground=hero.vy>=0 and on_ledge(hero.x,hero.y,hero_w,hero_h,hero.drop>0)
 if x_intent!=0 then hero.facing=x_intent end
 if ground then
  if hero.air then
   sfx(snd_land)
   hero.squash=6
   puff(hero.x+6,hero.y+7,4,7)
  end
  hero.coyote,hero.paddle,hero.chain,hero.y=coyote_frames,paddle_frames,0,flr(hero.y)
 else
  hero.coyote=max(hero.coyote-1)
 end
 hero.air=not ground
 hero.idle=ground and input==0 and min(hero.idle+1,idle_sit) or 0
 local sitting=ground and abs(hero.vx)<0.5 and (down or hero.idle>=idle_sit)
 if sitting and hero.state!="sit" then sfx(snd_sit) end
 local drop=sitting and down and pressed&16>0 and not on_ledge(hero.x,hero.y,hero_w,hero_h,true)
 if drop then hero.drop,hero.paddle,sitting=drop_frames,0,false end
 hero.buffer=pressed&16>0 and not drop and jump_buffer or max(hero.buffer-1)
 if sitting then
  hero.vx=toward(hero.vx,0,idle_fric)
 elseif ground then
  if x_intent==0 then
   hero.vx=toward(hero.vx,0,idle_fric)
  elseif hero.vx*x_intent<0 then
   hero.vx+=x_intent*skid_fric
  else
   hero.vx=x_intent*min(max(abs(hero.vx),run_start)+run_accel,max(abs(hero.vx)-idle_fric,run_max))
  end
 elseif x_intent!=0 and hero.vx*x_intent<run_max then
  hero.vx=mid(-run_max,hero.vx+x_intent*air_accel,run_max)
 end
 hero.vy=ground and hero.vy>=0 and 0 or min(hero.vy+(jump_held and hero.vy<0 and hover_accel or fall_accel),fall_max)
 local paddling=not ground and hero.vy>0 and jump_held and hero.paddle>0
 if paddling then
  if hero.paddle==paddle_frames then sfx(snd_paddle) end
  hero.paddle-=1
  hero.vy=max(hero.vy-paddle_lift,paddle_rise)
 end
 if hero.buffer>0 and hero.coyote>0 then
  hero.vy,hero.coyote,hero.buffer,hero.squash,sitting=-jump_a,0,0,-6,false
  sfx(snd_jump)
 end
 hero.cool,hero.bark=max(hero.cool-1),max(hero.bark-1)
 if pressed&32>0 and hero.cool==0 then
  hero.bark,hero.cool=bark_frames,bark_cool
  sfx(snd_bark)
  start_bark(hero)
 end
 if slide(hero,hero.vx,0) then hero.vx=0 end
 if slide(hero,0,hero.vy) then hero.vy=0 end
 hero.drop,hero.hurt,hero.squash=max(hero.drop-1),max(hero.hurt-1),toward(hero.squash,0,1)
 hero.stride+=abs(hero.vx)
 hero.state=sitting and "sit" or hero.bark>0 and "bark" or not ground and (paddling and "paddle" or "jump") or abs(hero.vx)>0.1 and "run" or "stand"
end

function hurt_loretta(hero,from_x)
 if hero.hurt>0 then return end
 hearts-=1
 hero.hurt,hero.vx,hero.vy=hurt_frames,sgn(hero.x+6-from_x)*knock_x,-knock_y
 shake=8
 sfx(snd_hurt)
 if hearts<=0 then game_over() end
end

function fall_in(hero)
 hearts-=1
 respawn=respawn_frames
 sfx(snd_splash)
 puff(hero.x+6,min(hero.y,120),12,12)
end

loretta_sprites=parse_record[[
stand=16
sit=30
bark=32
jump=24
nap=34
]]

function draw_loretta(hero)
 if hero.hurt%8>3 then return end
 local sprite=loretta_sprites[hero.state]
 if hero.state=="run" then
  sprite=({20,16,22,16})[hero.stride\6%4+1]
 elseif hero.state=="paddle" then
  sprite=t()*16%2<1 and 26 or 28
 elseif hero.state=="stand" and t()*3%2<1 then
  sprite=18
 end
 local squash=hero.squash/2
 local w,h=16+squash,8-squash
 sspr(sprite%16*8,sprite\16*8,16,8,hero.x+6-w/2,hero.y+7-h,w,h,hero.facing<0)
end
