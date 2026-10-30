function new_loretta(x,y)
 local hero={x=x,y=y,w=hero_w,h=hero_h,vx=0,vy=0,facing=1,coyote=0,buffer=0,held=63,paddle=0,drop=0,idle=0,bark=0,cool=0,hurt=0,chain=0,squash=0,gait=0,happy=0,state="stand",pose=split"5,-10,19,-10,4,-10,0.5,0,0",turn=head_turn,sag=0.5,sag_v=0,head_bob=0,flop=0,ears={{},{}},tongue={{},{},{}}}
 animate_loretta(hero)
 return hero
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
   hero.squash,hero.landed=6,true
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
 animate_loretta(hero)
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

loretta_legs=split"0,-1,0.5,4,6,1,5,0,6,6,0,-3,0,9,7,1,3,0.5,7,7"
loretta_poses={stand=split"5,-10,19,-10,4,-10,0.5,0,0",sit=split"7,-5,14,-12,4,-10,0,3,0",sploot=split"4,-5,19,-5,6,-7,4,-9,6",nap=split"4,-5,19,-5,7,-5,4,-7,6",jump=split"4,-10,20,-11,4,-10,0,-3,3"}
loretta_poses.paddle=loretta_poses.jump

function gait_amp(hero)
 return hero.state=="paddle" and 1 or hero.air and 0 or min(1,abs(hero.vx)/0.4)
end

function pitch(hero)
 return hero.state=="jump" and mid(-1,-hero.vy/2,1) or 0
end

function leg_pose(hero,front,phase)
 if hero.state=="jump" then
  local rise=(pitch(hero)+1)/2
  if front then return 4-2*rise,1+3*rise end
  return -1-4*rise,3-2*rise
 end
 local amp,cycle=gait_amp(hero),(hero.gait+phase)%1
 local reach,lift=hero.pose[front and 9 or 8],hero.air and 2 or 0
 if cycle<0.5 then return reach+leg_stride*(0.5-2*cycle)*amp,lift end
 local swing=cycle*2-1
 return reach+leg_stride*(swing-0.5)*amp,lift-sin(swing/2)*2*amp
end

function leg_place(hero,i)
 local base,x,phase=unpack(loretta_legs,i,i+2)
 local dx,lift=leg_pose(hero,base>0,phase)
 return hero.pose[1+base*2]+x,hero.pose[2+base*2]+2,dx,lift
end

function body_bob(hero)
 local amp=gait_amp(hero)
 local launch=hero.squash<-2
 return hero.squash>2 and 1 or launch and -1 or 0,launch and 2 or sin(hero.gait)*amp>0.5 and -1 or 0
end

function ex(hero,x)
 return hero.facing<0 and hero.x+24-x or hero.x+x
end

function wx(hero,x)
 return flr(ex(hero,x)+0.5)
end

function follow(point,x,y,length,damp,gravity,pull_x,pull_y,pull)
 if not point.ox then point.x,point.y,point.ox,point.oy=pull_x,pull_y,pull_x,pull_y end
 local vx,vy=(point.x-point.ox)*damp,(point.y-point.oy)*damp+gravity
 point.ox,point.oy=point.x,point.y
 point.x+=vx+(pull_x-point.x)*pull
 point.y+=vy+(pull_y-point.y)*pull
 local dx,dy=point.x-x,point.y-y
 local reach=max(sqrt(dx*dx+dy*dy),0.1)
 point.x,point.y=x+dx/reach*length,y+dy/reach*length
end

function animate_loretta(hero)
 local pose,target=hero.pose,loretta_poses[hero.state] or loretta_poses.stand
 for i=1,9 do pose[i]+=(target[i]-pose[i])/6 end
 hero.sag_v=(hero.sag_v+(pose[7]-hero.sag)*belly_spring+(hero.landed and belly_bounce or 0))*belly_damp
 hero.sag+=hero.sag_v
 hero.flop=hero.landed and ear_flop or max(hero.flop-1)
 hero.landed=false
 hero.head_bob+=(body_bob(hero)-hero.head_bob)*0.35
 hero.turn+=mid(-head_turn_speed,(hero.state=="sit" and 0 or hero.facing*head_turn)-hero.turn,head_turn_speed)
 local turn=hero.turn
 local hx,hy=ex(hero,pose[3]+pose[5]),hero.y+13+pose[4]+pose[6]+hero.head_bob+hero.flop\3-(hero.bark>0 and 1 or 0)-pitch(hero)*2
 hero.hx,hero.hy=hx,hy
 local lying,fast=pose[7]>2 or hero.flop>0,hero.air or abs(hero.vx)>1
 for i,ear in ipairs(hero.ears) do
  local around=turn+(i*2-3)*0.14
  ear.bx,ear.by,ear.depth=hx-5.5*sin(around),hy-5,cos(around)
  follow(ear,ear.bx,ear.by,ear_length,ear_damp,ear_gravity,ear.bx-turn/head_turn*(lying and 9 or fast and 4 or 1),ear.by-(lying and 4 or fast and 9 or 10),ear_spring)
 end
 local x,y=hx-7.5*sin(turn),hy+6
 for i,link in ipairs(hero.tongue) do
  if i>1 then follow(link,x,y,tongue_link,tongue_damp,tongue_weight,x,y+1,0) end
  link.x,link.y=link.x or x,link.y or y
  if i==1 then link.x,link.y=x,y end
  x,y=link.x,link.y
 end
end

function tri(x0,y0,x1,y1,x2,y2,colour)
 if y1<y0 then x0,y0,x1,y1=x1,y1,x0,y0 end
 if y2<y0 then x0,y0,x2,y2=x2,y2,x0,y0 end
 if y2<y1 then x1,y1,x2,y2=x2,y2,x1,y1 end
 for y=ceil(y0),y2 do
  local far=x0+(x2-x0)*(y-y0)/max(y2-y0,0.01)
  local near=y<y1 and x0+(x1-x0)*(y-y0)/max(y1-y0,0.01) or x1+(x2-x1)*(y-y1)/max(y2-y1,0.01)
  line(far,y,near,y,colour)
 end
end

function draw_ear(ear,colour,inner,outline)
 local tip_x,tip_y,base_x=flr(ear.x+0.5),flr(ear.y+0.5),flr(ear.bx+0.5)
 local ax,ay,bx,by=base_x-4,ear.by+1,base_x+4,ear.by+1
 if outline then
  for side=0,3 do
   local dx,dy=side\2*2-1,0
   if side%2==1 then dx,dy=0,side\2*2-1 end
   tri(ax+dx,ay+dy,bx+dx,by+dy,tip_x+dx,tip_y+dy,0)
  end
 else
  tri(ax,ay,bx,by,tip_x,tip_y,colour)
  tri(ax+2,ay,bx-2,by,flr(base_x+(tip_x-base_x)*0.65),flr(ear.by+(tip_y-ear.by)*0.65),inner)
 end
end

function draw_loretta(hero)
 if hero.hurt%8>3 then return end
 local pose,g,turn,hx,hy=hero.pose,hero.y+13,hero.turn,hero.hx,hero.hy
 local side=-sin(turn)
 local bob,rump=body_bob(hero)
 local tilt=flr(pitch(hero)*2+0.5)
 local px,py,cx,cy=flr(pose[1]+0.5),g+flr(pose[2]+0.5)+bob+rump+tilt,flr(pose[3]+0.5),g+flr(pose[4]+0.5)+bob-tilt
 local near,far={},{}
 local function part(list,x,y,radius,colour) add(list,{ex(hero,x),y,radius,colour}) end
 local function capsule(list,x0,y0,x1,y1,r0,r1,colour)
  for share=0,1,0.25 do part(list,x0+(x1-x0)*share,y0+(y1-y0)*share,r0+(r1-r0)*share,colour) end
 end
 local belly=min(hero.sag,g-max(py,cy)-5.5)
 part(near,px-2-(hero.happy>0 and t()*12%2\1 or 0),py,5,9)
 capsule(near,px,py,cx,cy,5,5.5,9)
 capsule(near,px+2,py+2+belly,cx-2,cy+2+belly,3,3,7)
 part(near,cx+3,cy+1,4.5,7)
 part(near,cx+2,cy-4,3.5,9)
 for i=1,16,5 do
  local jx,jy,dx,lift=leg_place(hero,i)
  local front=loretta_legs[i]>0
  jy+=g+bob+(front and 0 or rump)
  local fx,fy=jx+dx,g-lift
  local vx,vy=fx-jx,fy-jy
  local reach=max(sqrt(vx*vx+vy*vy),0.1)
  local half=min(reach/2,leg_bone)
  local bend=sqrt(leg_bone*leg_bone-half*half)*(front and 1 or -1)
  local kx,ky=jx+vx/2-vy/reach*bend,jy+vy/2+vx/reach*bend
  local list=i<11 and far or near
  capsule(list,jx,jy,kx,ky,2.5,2,loretta_legs[i+3])
  capsule(list,kx,ky,fx,fy,1.5,1,loretta_legs[i+4])
 end
 add(near,{hx,hy,7,9})
 add(near,{hx+side*3,hy+4.5,3.5,7})
 add(near,{hx+side*6.5,hy+3.5,3,7})
 local function blob(list,pass)
  for piece in all(list) do circfill(flr(piece[1]+0.5),flr(piece[2]+0.5),flr(piece[3]+0.5)+(pass==1 and 1 or 0),pass==1 and 0 or piece[4]) end
 end
 local back,front=hero.ears[1],hero.ears[2]
 if back.depth>front.depth then back,front=front,back end
 draw_ear(back,0,0,true)
 draw_ear(back,4,15)
 blob(far,1)
 blob(far,2)
 blob(near,1)
 draw_ear(front,0,0,true)
 blob(near,2)
 for share=0,1,0.25 do circfill(wx(hero,px+1+(cx-5-px)*share),py-2+(cy-py)*share,3,2) end
 circfill(wx(hero,px-6),py+2,2,7)
 draw_ear(front,9,14)
 local x,y=flr(hx+0.5),flr(hy+0.5)
 rectfill(flr(hx+side*5),y-6,flr(hx+side*5)+1,y-1,7)
 line(x-5,y+8,x+3,y+8,11)
 pset(flr(hx+side*3),y+9,10)
 for eye=-1,1,2 do
  local around=turn+eye*0.08
  local depth,eye_x=cos(around),flr(hx-6*sin(around)+0.5)
  if depth>0.05 then
   if hero.state=="nap" or t()%3<0.1 then
    line(eye_x,y,eye_x+1,y,0)
   elseif hero.happy>0 then
    pset(eye_x,y,0) pset(eye_x+1,y-1,0) pset(eye_x+2,y,0)
   else
    rectfill(eye_x,y-1,eye_x+(depth>0.6 and 1 or 0),y+1,0)
    pset(eye_x,y-1,7)
   end
  end
 end
 local nose_x,mouth_x=flr(hx+side*9.5),flr(hx+side*8)
 rectfill(nose_x-1,y+2,nose_x,y+3,0)
 if hero.bark>0 then
  rectfill(mouth_x-2,y+5,mouth_x+1,y+7,0)
  pset(mouth_x-1,y+7,14)
 elseif gait_amp(hero)>0 or hero.happy>0 or hero.air then
  rectfill(mouth_x-2,y+5,mouth_x+1,y+6,0)
  for colour in all{14,8} do
   for link in all(hero.tongue) do circfill(link.x+0.5,link.y+0.5,colour==14 and 1 or 0,colour) end
  end
 else
  pset(mouth_x-2,y+5,0) pset(mouth_x-1,y+6,0) pset(mouth_x,y+6,0) pset(mouth_x+1,y+5,0)
 end
end
