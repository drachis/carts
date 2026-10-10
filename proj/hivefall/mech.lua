-- mech.lua : the player's mech, its weapons and their shots.

function update_player()
 local push=tonum(btn(1))-tonum(btn(0))
 player.vx=mid(-mech_speed,player.vx+push*mech_accel,mech_speed)
 if push==0 then player.vx*=0.9 end
 player.x=mid(-62,player.x+player.vx,62)
 camera_x=player.x*0.25

 player.hurt_flash=max(player.hurt_flash-1)
 player.muzzle=max(player.muzzle-1)
 player.recoil*=0.8
 player.heat=max(player.heat-cool_rate)
 if player.heat<restart_heat then player.overheated=false end
 for weapon in all(weapon_specs) do
  weapon.wait=max(weapon.wait-1)
 end

 if btnp(5) then
  repeat
   player.weapon=player.weapon%#weapon_specs+1
  until weapon_specs[player.weapon].wave<=wave
  sfx(snd_switch)
 end

 find_target()
 local weapon=weapon_specs[player.weapon]
 if btn(4) and weapon.wait==0 and not player.overheated then
  fire(weapon)
 end
end

-- the nearest foe inside the cone that opens upward from the guns
function find_target()
 local best
 local sx,sy=project(player.x,1,18)
 for foe in all(foes) do
  local rise=sy-foe.sy+8*foe.size*foe.scale
  if foe.z<far_z+0.2
   and abs(foe.sx-sx)<cone_base+rise*cone_slope
   and (not best or foe.z<best.z) then
   best=foe
  end
 end
 player.target=best
end

function fire(weapon)
 weapon.wait=weapon.cooldown
 player.heat+=weapon.heat
 if player.heat>=max_heat then
  player.overheated=true
  sfx(snd_overheat)
 end
 player.muzzle=3
 player.recoil=1+weapon.heat/8
 shake=max(shake,weapon.heat/10)
 sfx(weapon.sound)
 for i=1,weapon.count do
  player.gun_side=-player.gun_side
  local shot=setmetatable({
   x=player.x+player.gun_side*10,z=1,h=18,
   vx=0,vh=0,
   target=player.target,struck={}
  },weapon)
  aim(shot)
  shot.vx+=(rnd(2)-1)*weapon.spread
  add(shots,shot)
 end
end

-- point a shot so it meets its target when their depths match
function aim(shot)
 local foe=shot.target
 if foe and foe.hp>0 and foe.z>shot.z then
  local steps=max(1,(foe.z-shot.z)/shot.speed)
  shot.vx=(foe.x-shot.x)/steps
  shot.vh=(foe.h+8*foe.size-shot.h)/steps
 end
end

function update_shots()
 for shot in all(shots) do
  if shot.homing==1 then aim(shot) end
  shot.x+=shot.vx
  shot.z+=shot.speed
  shot.h+=shot.vh
  if shot.z>far_z+0.4 then
   del(shots,shot)
  else
   for foe in all(foes) do
    local reach=9*foe.size
    if not shot.struck[foe]
     and foe.z<far_z+0.3
     and abs(foe.z-shot.z)<max(shot.speed,0.15)
     and abs(foe.x-shot.x)<reach
     and abs(foe.h+8*foe.size-shot.h)<reach then
     if strike(shot,foe) then break end
    end
   end
  end
 end
end

-- true when the shot is spent
function strike(shot,foe)
 if shot.splash>0 then
  explode(shot)
 else
  hurt_foe(foe,shot.damage)
  if shot.pierce==1 then
   shot.struck[foe]=true
   return false
  end
 end
 del(shots,shot)
 return true
end

function explode(shot)
 local sx,sy,scale=project(shot.x,shot.z,shot.h)
 ring(sx,sy,shot.splash*scale*1.2,shot.colour)
 ring(sx,sy,shot.splash*scale*0.8,7)
 burst(sx,sy,shot.splash,shot.colour,shot.splash/6)
 shake=max(shake,shot.splash/4)
 grid_flash=8
 if shot.splash>40 then white=3 end
 sfx(snd_boom)
 for foe in all(foes) do
  if foe.z<far_z+0.3
   and abs(foe.x-shot.x)<shot.splash+8*foe.size
   and abs(foe.z-shot.z)<shot.splash/25 then
   hurt_foe(foe,shot.damage)
  end
 end
end

function draw_shots()
 for shot in all(shots) do
  local sx,sy,scale=project(shot.x,shot.z,shot.h)
  local radius=(0.5+shot.damage/5)*scale
  if shot.px then line(shot.px,shot.py,sx,sy,shot.colour) end
  circfill(sx,sy,radius+1,shot.colour)
  circfill(sx,sy,radius,7)
  shot.px,shot.py=sx,sy
  if shot.splash>0 and tick%2==0 then burst(sx,sy,1,9,0.6) end
 end
end

function hurt_player(amount)
 player.armor-=amount
 player.hurt_flash=24
 shake=7
 sfx(snd_hurt)
 local sx,sy=project(player.x,1,12)
 burst(sx,sy,14,9,3)
 if player.armor<=0 then
  burst(sx,sy,60,10,5)
  end_game(false)
 end
end

function draw_player()
 local sx,sy=project(player.x,1,0)
 local frame=abs(player.vx)>0.15 and tick\8%2 or 0
 if player.hurt_flash>0 and tick%4<2 then
  for colour=1,15 do pal(colour,8) end
 elseif player.overheated and tick%8<4 then
  pal(6,9)
  pal(13,8)
 end
 sspr(frame*24,32,24,24,sx-12,sy-23+player.recoil)
 pal()
 if player.muzzle>0 then
  circfill(sx-10,sy-24,2,7)
  circfill(sx+9,sy-24,2,7)
 end
 if player.overheated and tick%3==0 then
  burst(sx+rnd(16)-8,sy-16,1,6,0.8)
 end
end

-- the cone, as two dotted edges, and brackets around what is locked
function draw_aim()
 local sx,sy=project(player.x,1,18)
 for rise=6,76,6 do
  local half=cone_base+rise*cone_slope
  pset(sx-half,sy-rise,5)
  pset(sx+half,sy-rise,5)
 end
 local foe=player.target
 if foe then
  local half=8*foe.size*foe.scale
  local cx,cy=foe.sx,foe.sy-half
  half+=2+sin(tick/30)
  for side=-1,1,2 do
   for up=-1,1,2 do
    local x,y=cx+side*half,cy+up*half
    line(x,y,x-side*3,y,11)
    line(x,y,x,y-up*3,11)
   end
  end
 end
end
