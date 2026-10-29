function new_loretta(x,y)
 return {x=x,y=y,w=hero_w,h=hero_h,vx=0,vy=0,facing=1,coyote=0,buffer=0,held=63,paddle=0,drop=0,idle=0,bark=0,cool=0,hurt=0,chain=0,squash=0,gait=0,happy=0,state="stand",pose=split"0,0,0,0,0"}
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
 if sitting and not hero.resting then sfx(snd_sit) end
 hero.resting,hero.happy=sitting,max(hero.happy-1)
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
 hero.state=sitting and (down and "sit" or "sploot") or hero.bark>0 and "bark" or not ground and (paddling and "paddle" or "jump") or abs(hero.vx)>0.1 and "run" or "stand"
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

loretta_legs=split"0,9,0.5,4,6,1,22,0,6,6,0,6,0,9,7,1,19,0.5,7,7"
loretta_poses={stand=split"0,0,0,0,0",sploot=split"4,5,-9,6,0",nap=split"4,6,-7,6,0",sit=split"0,0,3,0,-5"}

function gait_amp(hero)
 return hero.air and 1 or min(1,abs(hero.vx)/0.4)
end

function leg_pose(hero,front,phase)
 if hero.state=="jump" then return front and 3 or -3,2 end
 local amp,cycle=gait_amp(hero),(hero.gait+phase)%1
 local reach=hero.pose[front and 4 or 3]
 if cycle<0.5 then return reach+leg_stride*(0.5-2*cycle)*amp,0 end
 local swing=cycle*2-1
 return reach+leg_stride*(swing-0.5)*amp,-sin(swing/2)*2*amp
end

function leg_place(hero,i)
 local base,x,phase=unpack(loretta_legs,i,i+2)
 local dx,lift=leg_pose(hero,base>0,phase)
 return x+base*hero.pose[5],11+hero.pose[1],dx,lift
end

function draw_loretta(hero)
 if hero.hurt%8>3 then return end
 local pose,target=hero.pose,loretta_poses[hero.state] or loretta_poses.stand
 for i=1,5 do pose[i]+=(target[i]-pose[i])/6 end
 local flip,amp,sit=hero.facing<0,gait_amp(hero),hero.state=="sit"
 local function mx(x,w) return flip and 2*hero.x+24-x-(w or 1) or x end
 local bob=(hero.squash>2 and 1 or 0)-(sin(hero.gait*2)*amp>0.5 and 1 or 0)
 local rump=flr(sin(hero.gait)*amp+0.5)
 local bx,by=hero.x-2,hero.y-4+flr(pose[1])
 local face_x,face_y=bx+(sit and 9 or 16),by-(sit and 10 or 8)+bob+flr(pose[2])-(hero.bark>0 and 1 or 0)
 local ears=(hero.squash>2 or pose[1]>2) and 4 or (hero.vy<0 or abs(hero.vx)>1) and 2 or 0
 local function limb(i,pass)
  local jx,jy,dx,lift=leg_place(hero,i)
  local front=loretta_legs[i]>0
  jx+=bx
  jy+=by+bob+(front and 0 or rump)
  local fx,fy=jx+dx,hero.y+13-lift
  local vx,vy=fx-jx,fy-jy
  local reach=max(sqrt(vx*vx+vy*vy),0.1)
  local half=min(reach/2,leg_bone)
  local bend=sqrt(leg_bone*leg_bone-half*half)*(front and 1 or -1)
  local kx,ky=jx+vx/2-vy/reach*bend,jy+vy/2+vx/reach*bend
  for share=0,1,0.25 do
   circfill(mx(jx+(kx-jx)*share),jy+(ky-jy)*share,pass,pass>1 and 0 or loretta_legs[i+3])
   circfill(mx(kx+(fx-kx)*share),ky+(fy-ky)*share,pass,pass>1 and 0 or loretta_legs[i+4])
  end
 end
 palt(0,false)
 palt(12,true)
 spr(182+ears,mx(face_x-1,16),face_y-9,2,2,flip)
 for i=1,16,5 do
  if i<11 then limb(i,2) limb(i,1) end
 end
 if sit then
  spr(231,mx(bx+2,24),hero.y-2,3,2,flip)
 else
  sspr(0,112,16,14,mx(bx-(hero.happy>0 and t()*12%2\1 or 0),16),by+bob+rump,16,14,flip)
  sspr(12,112,16,14,mx(bx+12,16),by+bob,16,14,flip)
 end
 for i=11,16,5 do
  limb(i,2)
  limb(i,1)
 end
 spr(228,mx(face_x,24),face_y,3,2,flip)
 spr(176+ears,mx(face_x+7,16),face_y-9,2,2,flip)
 local function dot(x,y,colour) pset(mx(face_x+x),face_y+y,colour) end
 if hero.state=="nap" or t()%3<0.1 then
  dot(12,7,0) dot(13,7,0) dot(5,8,0)
 elseif hero.happy>0 then
  dot(12,7,0) dot(13,6,0) dot(14,7,0) dot(5,7,0)
 else
  rectfill(mx(face_x+12),face_y+6,mx(face_x+13),face_y+8,0)
  dot(12,6,7) dot(5,7,0) dot(5,8,0)
 end
 if hero.bark>0 then
  rectfill(mx(face_x+15),face_y+11,mx(face_x+18),face_y+13,0)
  dot(16,13,14)
 elseif amp>0 or hero.happy>0 then
  rectfill(mx(face_x+14),face_y+11,mx(face_x+18),face_y+12,0)
  rectfill(mx(face_x+15),face_y+12,mx(face_x+17),face_y+13,14)
  dot(16+hero.gait*4%2\1,14,14)
  dot(16,12,8)
 else
  dot(15,12,0) dot(16,13,0) dot(17,13,0) dot(18,12,0)
 end
 palt()
end
