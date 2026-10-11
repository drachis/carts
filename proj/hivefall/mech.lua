-- mech.lua : the player's mech, its weapons and their shots.

function update_player()
 local push=tonum(btn(1))-tonum(btn(0))
 local top_speed=mech_speed*player.agility
 player.vx=mid(-top_speed,player.vx+push*mech_accel*player.agility,top_speed)
 if push==0 then player.vx*=0.9 end
 player.x=mid(-62,player.x+player.vx,62)
 camera_x=player.x*0.25
 -- a heavy footfall
 if abs(player.vx)>0.3 and tick%24==0 then
  local sx,sy=project(player.x,1,0)
  burst(sx,sy,3,5,1)
  shake=max(shake,1.2)
  sfx(snd_step)
 end

 player.hurt_flash=max(player.hurt_flash-1)
 player.muzzle=max(player.muzzle-1)
 player.recoil*=0.8
 player.chill=max(player.chill-1)
 player.heat=max(player.heat-player.cooling)
 if player.heat<restart_heat then player.overheated=false end
 for weapon in all(weapon_specs) do
  weapon.wait=max(weapon.wait-1)
 end

 find_target()
 local step=tonum(btnp(5))-tonum(btnp(3))
 if step!=0 then
  repeat
   player.weapon=(player.weapon-1+step)%#weapon_specs+1
   local candidate=weapon_specs[player.weapon]
  until candidate.wave<=wave
   and (candidate.ammo==0 or candidate.rounds>0)
  sfx(snd_switch)
 end
 if btnp(2) and charge>=alpha_cost then start_alpha() end

 if player.alpha>0 then
  player.alpha-=1
  player.heat=0
  shake=max(shake,2)
  if tick%3==0 then
   local weapon
   repeat
    weapon=rnd(weapon_specs)
   until weapon.wave<=wave and weapon.cooldown<100
   local foe=rnd(foes)
   launch(weapon,foe and foe.z<far_z+0.2 and foe or player.target)
   sfx(weapon.sound)
  end
 end

 local weapon=weapon_specs[player.weapon]
 if btn(4) and weapon.wait==0 and not player.overheated then
  if weapon.ammo>0 and weapon.rounds<=0 then
   bark(weapon.name.." is dry")
   player.weapon=1
  else
   fire(weapon)
  end
 end
end

-- every gun the mech has, at everything on the hill, for a few seconds
function start_alpha()
 player.alpha,charge,alpha_told=alpha_frames,0
 freeze,white,shake=10,4,9
 local sx,sy=project(player.x,1,12)
 ring(sx,sy,90,12,1)
 ring(sx,sy,60,7,1)
 bark("alpha strike!")
 sfx(snd_alpha)
end

-- the nearest foe inside the cone that opens upward from the guns
function find_target()
 local best
 local reach=weapon_specs[player.weapon].range
 local sx,sy=project(player.x,1,18)
 for foe in all(foes) do
  local rise=sy-foe.sy+8*foe.size*foe.scale
  if foe.z<reach
   and abs(foe.sx-sx)<cone_base+rise*player.cone
   and (not best or foe.z<best.z) then
   best=foe
  end
 end
 player.target=best
end

function fire(weapon)
 weapon.wait=weapon.cooldown*max(0.4,player.haste)
 weapon.rounds-=1
 if player.chill==0 then player.heat+=weapon.heat end
 if player.heat>=max_heat then
  player.overheated=true
  bark("heat critical!")
  sfx(snd_overheat)
 end
 player.recoil=1+weapon.heat/8
 shake=max(shake,weapon.heat/10)
 sfx(weapon.sound)
 launch(weapon,player.target)
end

function launch(weapon,target)
 player.muzzle=3
 for i=1,weapon.count do
  player.gun_side=-player.gun_side
  local shot=setmetatable({
   x=player.x+player.gun_side*10,z=1,h=18,
   vx=0,vh=0,
   target=target,struck={}
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
  if shot.z>shot.range+0.3 then
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
  hurt_foe(foe,shot.damage*player.power)
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
 ring(sx,sy,shot.splash*scale*1.2,shot.colour,shot.splash/40)
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
   hurt_foe(foe,shot.damage*player.power)
  end
 end
end

function draw_shots()
 for shot in all(shots) do
  local sx,sy,scale=project(shot.x,shot.z,shot.h)
  local radius=(0.5+shot.damage/5)*scale
  if shot.px then line(shot.px,shot.py,sx,sy,shot.colour) end
  circfill(sx,sy,min(radius,7)+1,shot.colour)
  circfill(sx,sy,min(radius,7),7)
  shot.px,shot.py=sx,sy
  if shot.splash>0 and tick%2==0 then burst(sx,sy,1,9,0.6) end
 end
end

-- a bite buys a moment of mercy, so a pack arriving together is one hit
function hurt_player(amount)
 if player.hurt_flash>mercy_ends then return end
 if player.armor>30 and player.armor-amount<=30 then
  bark("armor critical!")
 end
 player.armor-=amount
 player.hurt_flash=45
 combo=0
 shake=7
 sfx(snd_hurt)
 local sx,sy=project(player.x,1,12)
 burst(sx,sy,14,9,3)
 if player.armor<=0 then
  burst(sx,sy,60,10,5)
  ring(sx,sy,70,8,1)
  end_game(false,"mech destroyed")
 end
end

function draw_player()
 local sx,sy=project(player.x,1,0)
 local frame=abs(player.vx)>0.15 and tick\8%2 or 0
 if player.hurt_flash>0 and tick%4<2 then
  for colour=1,15 do pal(colour,8) end
 elseif player.alpha>0 and tick%4<2 then
  pal(6,7)
  pal(13,12)
  pal(5,12)
 elseif player.overheated and tick%8<4 then
  pal(6,9)
  pal(13,8)
 end
 sspr(frame*24,64,24,24,sx-12,sy-23+player.recoil)
 pal()
 if player.muzzle>0 then
  circfill(sx-10,sy-24,2,7)
  circfill(sx+9,sy-24,2,7)
 end
 if player.overheated and tick%3==0 then
  burst(sx+rnd(16)-8,sy-16,1,6,0.8,-0.05)
 end
end

-- the cone, as two dotted edges out to the weapon's range, and
-- brackets around what is locked
function draw_aim()
 local sx,sy=project(player.x,1,18)
 local _,top=project(player.x,weapon_specs[player.weapon].range,0)
 local half
 for rise=6,sy-top,6 do
  half=cone_base+rise*player.cone
  pset(sx-half,sy-rise,5)
  pset(sx+half,sy-rise,5)
 end
 line(sx-half,top,sx+half,top,5)
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
