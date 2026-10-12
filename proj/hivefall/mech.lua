-- mech.lua : the player's mech, its weapons and their shots.

function update_player()
 local push=tonum(btn(1))-tonum(btn(0))
 local top_speed=mech_speed*player.agility
 player.vx=mid(-top_speed,player.vx+push*mech_accel*player.agility,top_speed)
 if push==0 then player.vx*=0.9 end
 player.x=mid(-62,player.x+player.vx,62)
 camera_x=player.x*0.25

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
 -- a tap of x is the next gun; x held along with fire vents heat
 if btn(5) then
  x_held=min(x_held+1,99)
 else
  if x_held>0 and x_held<=vent_delay then
   repeat
    player.weapon=player.weapon%#weapon_specs+1
    local candidate=weapon_specs[player.weapon]
   until candidate.wave<=wave
    and (candidate.ammo==0 or candidate.rounds>0)
   sfx(snd_switch)
  end
  x_held=0
 end
 local venting=btn(4) and x_held>vent_delay
 if venting then
  player.heat=max(player.heat-vent_rate)
  if tick%6==0 then
   local sx,sy=project(player.x,1,16)
   burst(sx+rnd(20)-10,sy,2,6,1,-0.06)
   sfx(snd_vent)
  end
 end
 if btnp(3) and charge>=alpha_cost then start_alpha() end
 -- up pushes forward: everything on the hill closes faster
 boost=btn(2) and boost_speed or 0
 -- fire has to be let go once after a refit before the guns answer
 if not btn(4) then safety=false end

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
 if btn(4) and weapon.wait==0 and not player.overheated
  and not venting and not safety then
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

-- half the lock cone's width at a depth, in world pixels
function cone_half(z)
 return cone_base+(z-1)*player.cone
end

-- the nearest foe inside the cone, out to the range of the gun in hand
function find_target()
 local best
 local reach=weapon_specs[player.weapon].range
 for foe in all(foes) do
  if foe.z<reach
   and abs(foe.x-player.x)<cone_half(foe.z)
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
   x=player.x+player.gun_side*10,z=1,h=18+hover,
   vx=0,vh=0,
   target=target,fuse=target and target.z,struck={}
  },weapon)
  aim(shot)
  -- a gun with spread throws its shots in an even fan about the aim
  -- line, each a little ragged, and scatters them up and down as well
  local across=(i-0.5)/weapon.count*2-1
  shot.vx+=weapon.spread*(across+rnd(0.3)-0.15)
  shot.vh+=weapon.spread*(rnd(0.8)-0.4)
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
  elseif shot.splash>0 and shot.fuse and shot.z>=shot.fuse then
   -- a blast that met nothing goes off where it was aimed
   explode(shot)
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
  hurt_foe(foe,shot.damage*player.power,shot)
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
 blast(sx,sy,shot.splash*scale*0.8)
 burst(sx,sy,shot.splash,shot.colour,shot.splash/6)
 shake=max(shake,shot.splash/4)
 grid_flash=8
 if shot.splash>40 then white=3 end
 sfx(snd_boom)
 for foe in all(foes) do
  if foe.z<far_z+0.3
   and abs(foe.x-shot.x)<shot.splash+8*foe.size
   and abs(foe.z-shot.z)<shot.splash/25 then
   hurt_foe(foe,shot.damage*player.power,shot)
   -- what lives through it is thrown back up the hill and aside
   if foe.hp>0 then
    foe.z=min(foe.z+shot.splash/40,far_z)
    foe.centre+=sgn(foe.x-shot.x)*shot.splash/3
   end
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

-- armour pays for whatever the mech stands in front of
function hurt_player(amount)
 if player.armor>30 and player.armor-amount<=30 then
  bark("armor critical!")
 end
 player.armor-=amount
 player.hurt_flash=30
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
 local sx,sy=project(player.x,1,hover+sin(tick/45)*1.5)
 -- a black edge first, so it stands off the rooftops
 local top=sy-23+player.recoil
 for colour=1,15 do pal(colour,0) end
 for nudge=-1,1,2 do
  sspr(0,64,24,24,sx-12+nudge,top)
  sspr(0,64,24,24,sx-12,top+nudge)
 end
 pal()
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
 sspr(0,64,24,24,sx-12,top)
 pal()
 -- jump jets under the feet: a flame that tapers from a white-hot root
 -- through yellow to an orange tip, flickering, leaning against the way
 -- the mech is moving, and longer under boost
 for jet=-7,7,14 do
  local length=4+rnd(3)+boost*500
  for step=0,length do
   local along=step/length
   circfill(sx+jet-player.vx*step,sy+1+step,2.4*(1-along),
    along<0.3 and 7 or along<0.65 and 10 or 9)
  end
 end
 if player.muzzle>0 then
  circfill(sx-10,sy-24,2,7)
  circfill(sx+9,sy-24,2,7)
 end
 if player.overheated and tick%3==0 then
  burst(sx+rnd(16)-8,sy-16,1,6,0.8,-0.05)
 end
end

-- the cone, laid on the ground so it bends with the hill: dotted edges,
-- an arc at the gun's range in the gun's colour, and brackets around
-- what is locked: yellow if this gun is what it is weak to, red if it
-- will only glance, green otherwise
function draw_aim()
 local weapon=weapon_specs[player.weapon]
 for z=1.4,weapon.range,0.4 do
  for side=-1,1,2 do
   local sx,sy=project(player.x+side*cone_half(z),z,0)
   pset(sx,sy,6)
  end
 end
 line()
 for across=-1,1,0.25 do
  local sx,sy=project(player.x+across*cone_half(weapon.range),weapon.range,0)
  line(sx,sy,weapon.colour)
 end
 local foe=player.target
 if foe then
  local half=8*foe.size*foe.scale
  local cx,cy=foe.sx,foe.sy-half
  half+=2+sin(tick/30)
  local hue=11
  if weapon.name==foe.weak then
   hue=10
  elseif weapon.damage*player.power<foe.armor then
   hue=8
  end
  for side=-1,1,2 do
   for up=-1,1,2 do
    local x,y=cx+side*half,cy+up*half
    line(x,y,x-side*3,y,hue)
    line(x,y,x,y-up*3,hue)
   end
  end
 end
end
