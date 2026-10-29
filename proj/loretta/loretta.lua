function new_loretta(x,y)
 return {x=x,y=y,w=hero_w,h=hero_h,vx=0,vy=0,facing=1,coyote=0,buffer=0,held=63,paddle=0,drop=0,idle=0,bark=0,cool=0,hurt=0,chain=0,squash=0,gait=0,state="stand",body=split"8,6,20,6,0"}
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

function slide(hero,dx,dy,climb)
 local amount=dx+dy
 while amount!=0 do
  local part=mid(-1,amount,1)
  amount-=part
  local x,y=hero.x+(dx!=0 and part or 0),hero.y+(dy!=0 and part or 0)
  if climb and area_has(x,y,hero_w,hero_h,0) and not area_has(x,y-1,hero_w,hero_h,0) then y-=1 end
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
   puff(hero.x+12,hero.y+14,6,7)
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
 if slide(hero,hero.vx,0,ground) then hero.vx=0 end
 if ground and hero.vy>=0 and area_has(hero.x,hero.y+3,hero_w,hero_h,0) then hero.vy=3 end
 if slide(hero,0,hero.vy) then hero.vy=0 end
 hero.drop,hero.hurt,hero.squash=max(hero.drop-1),max(hero.hurt-1),toward(hero.squash,0,1)
 hero.gait=(hero.gait+(ground and abs(hero.vx)/(2*leg_stride) or paddling and paddle_gait or 0))%1
 hero.state=sitting and "sit" or hero.bark>0 and "bark" or not ground and (paddling and "paddle" or "jump") or abs(hero.vx)>0.1 and "run" or "stand"
end

function hurt_loretta(hero,from_x)
 if hero.hurt>0 then return end
 hearts-=1
 hero.hurt,hero.vx,hero.vy=hurt_frames,sgn(hero.x+12-from_x)*knock_x,-knock_y
 shake=8
 sfx(snd_hurt)
 if hearts<=0 then game_over() end
end

function fall_in(hero)
 hearts-=1
 respawn=respawn_frames
 sfx(snd_splash)
 puff(hero.x+12,min(hero.y,120),12,12)
end

loretta_legs=split"0,3,0.5,4,6,1,3,0,4,6,0,0,0,9,7,1,0,0.5,7,7"
body_poses={stand=split"8,6,20,6,0",sit=split"11,9,18,3,-1",nap=split"9,9,21,9,3"}

function gait_amp(hero)
 return hero.air and 1 or min(1,abs(hero.vx)/0.4)
end

function leg_pose(hero,front,phase)
 if hero.state=="nap" then return front and 6 or -3,0 end
 if hero.state=="jump" then return front and 2 or -2,1 end
 local amp,cycle=gait_amp(hero),(hero.gait+phase)%1
 if cycle<0.5 then return leg_stride*(0.5-2*cycle)*amp,0 end
 local swing=cycle*2-1
 return leg_stride*(swing-0.5)*amp,-sin(swing/2)*2*amp
end

function leg_place(hero,i)
 local base,offset,phase=unpack(loretta_legs,i,i+2)
 local dx,lift=leg_pose(hero,base>0,phase)
 return hero.body[base*2+1]+offset,hero.body[base*2+2]+3,dx,lift
end

function draw_loretta(hero)
 if hero.hurt%8>3 then return end
 local ox,oy,flip,body,target=hero.x-4,hero.y-2,hero.facing<0,hero.body,body_poses[hero.state] or body_poses.stand
 for i=1,5 do body[i]+=(target[i]-body[i])/5 end
 local function px(x) return flip and ox+31-x or ox+x end
 local amp=gait_amp(hero)
 local bob=(hero.squash>2 and 1 or 0)-(sin(hero.gait*2)*amp>0.5 and 1 or 0)
 local rump=flr(sin(hero.gait)*amp+0.5)
 local hx,hy,sx,sy=body[1],body[2]+bob+rump,body[3],body[4]+bob
 local function bone(x0,y0,x1,y1,radius,colour)
  for share=0,1,0.25 do circfill(px(x0+(x1-x0)*share),oy+y0+(y1-y0)*share,radius,colour) end
 end
 local limbs={}
 for i=1,16,5 do
  local jx,jy,dx,lift=leg_place(hero,i)
  local front=loretta_legs[i]>0
  jy+=front and bob or bob+rump
  local fx,fy=jx+dx,15-lift
  local vx,vy=fx-jx,fy-jy
  local reach=max(sqrt(vx*vx+vy*vy),0.1)
  local half=min(reach/2,leg_bone)
  local bend=sqrt(leg_bone*leg_bone-half*half)*(front and 1 or -1)
  add(limbs,{jx,jy,jx+vx/2-vy/reach*bend,jy+vy/2+vx/reach*bend,fx,fy,loretta_legs[i+3],loretta_legs[i+4]})
 end
 local function limb(which,pass)
  local jx,jy,kx,ky,fx,fy,upper,lower=unpack(limbs[which])
  bone(jx,jy,kx,ky,pass,pass>1 and 4 or upper)
  bone(kx,ky,fx,fy,pass,pass>1 and 4 or lower)
 end
 for which=1,2 do
  limb(which,2)
  limb(which,1)
 end
 local butt,middle,shoulder={hx-2,hy+1,4},{(hx+sx)/2,(hy+sy)/2,5},{sx,sy,4}
 local spine={butt,middle,shoulder}
 for pair=1,2 do
  local a,b=spine[pair],spine[pair+1]
  add(spine,{(a[1]+b[1])/2,(a[2]+b[2])/2,(a[3]+b[3])/2})
 end
 for part in all(spine) do circfill(px(part[1]),oy+part[2]-1,part[3]+1,4) end
 limb(3,2)
 limb(4,2)
 for part in all(spine) do circfill(px(part[1]),oy+part[2]+1,part[3],7) end
 for part in all(spine) do circfill(px(part[1]),oy+part[2]-1,part[3],9) end
 line(px(butt[1]),oy+butt[2]-4,px(shoulder[1]),oy+shoulder[2]-4,15)
 circfill(px(sx+3),oy+sy+2,3,7)
 limb(3,1)
 limb(4,1)
 local ears,tongue=hero.air or abs(hero.vx)>1.1 or hero.squash>2,amp>0 and hero.gait%0.5<0.25
 local head=hero.bark>0 and 46 or hero.state=="nap" and 64 or ears and (tongue and 66 or 42) or tongue and 44 or t()%3<0.1 and 64 or 40
 spr(head,flip and ox+19-sx or ox+sx-3,oy+sy-11+body[5]-(hero.bark>0 and 1 or sin(hero.gait*2+0.2)*amp>0.5 and 1 or 0),2,2,flip)
end
