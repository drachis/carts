-- test_weapons.lua : every weapon against a foe standing in the cone, near,
-- far, flying and big, wherever the weapon's range covers where it starts. the mech stands still and holds fire, and is kept
-- cool and loaded, so this measures whether shots land and how long a kill takes; it
-- says nothing about heat or about aiming by moving.
-- then a staged scene with every kind of foe, for a screenshot.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx
function update_waves() end

local setups={"skitter,2","wing,2.5","skitter,5.8","wing,4","brute,4.5","ship,5"}
local n,weapon_index,setup_index=0,1,0
local victim,started
local staged
local game_update,game_draw=_update60,_draw

function _draw() end

function next_case()
 setup_index+=1
 if setup_index>#setups then
  setup_index=1
  weapon_index+=1
 end
 if weapon_index>#weapon_specs then return false end
 local parts=split(setups[setup_index])
 if parts[2]>weapon_specs[weapon_index].range then return next_case() end
 foes,shots={},{}
 player.x,player.vx,player.armor,player.weapon=0,0,100,weapon_index
 for weapon in all(weapon_specs) do weapon.wait=0 end
 victim=spawn_foe(enemy_specs[parts[1]],0,parts[2],0)
 victim.sway=0
 victim.brood,victim.halt=false
 started=n
 return true
end

function stage_scene()
 staged=n
 foes,shots={},{}
 wave=8
 player.x,player.weapon=-20,5
 spawn_group("skitter",8)
 spawn_group("wing",5)
 spawn_group("wyrm",7)
 spawn_foe(enemy_specs.brute,-45,2.2,0).age=250
 spawn_foe(enemy_specs.tyrant,28,3.2,0)
 spawn_foe(enemy_specs.ship,-10,4,0)
 spawn_foe(enemy_specs.skitter,-22,1.6,0)
 for i,foe in ipairs(foes) do
  if i<=20 then foe.z-=0.8+i%5*0.9 end
 end
end

function _update60()
 n+=1
 if n==1 then
  reset()
  state="play"
  wave=8
  next_case()
 end
 held={[4]=true}
 player.heat,player.overheated=0,false
 for weapon in all(weapon_specs) do weapon.rounds=weapon.ammo end

 if staged then
  held[1]=true
  if n==staged+70 then
   charge=alpha_cost
   held[2]=true
  end
 elseif victim.hp<=0 then
  printh(weapon_specs[weapon_index].name.." kills "
   ..setups[setup_index].." in "..(n-started).." frames")
  if not next_case() then stage_scene() end
 elseif n-started>900 or player.armor<100 then
  printh("error: "..weapon_specs[weapon_index].name.." did not kill "
   ..setups[setup_index].." (hp "..victim.hp.." z "..victim.z..")")
  extcmd("shutdown")
 end

 game_update()
 game_draw()
 if staged and n==staged+50 then
  printh("cpu at 60fps with "..#foes.." foes: "..stat(1))
  dump_screen("scene")
 end
 if staged and n==staged+110 then
  dump_screen("scene_later")
  printh("ok weapons")
  extcmd("shutdown")
 end
end
