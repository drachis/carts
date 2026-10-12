-- test_charge.lua : the overcharge, alone. a brute with no weakness and
-- far too much health to die stands still in the cone. for each gun in
-- turn the mech holds up past a full charge and lets go, and the damage
-- the brute takes is printed against the most that gun's row in
-- alt_specs could do. it must be at least one shot's worth, no more than
-- all of it, and (for the first gun) cost twice a normal shot's heat.
-- then, with the pulse gun:
--   up let go early: nothing is fired;
--   fire held while up is held: nothing is fired.
-- it does not judge whether an overcharge feels good or is worth the wait.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx
function update_waves() end

local n=0
local game_update,game_draw=_update60,_draw
local brute,hp_before
local slot=140

function _draw() end

function check(what,passed,detail)
 printh((passed and "pass: " or "error: ")..what.." ("..detail..")")
end

function _update60()
 n+=1
 held={}
 if n==1 then
  reset()
  state="play"
  wave=8
  brute=spawn_foe(enemy_specs.brute,0,2.5,0)
  -- false, not nil: nil would read through to the brute's own row
  brute.sway,brute.speed,brute.brood,brute.weak=0,0,false,false
 end
 brute.z,brute.hp=2.5,max(brute.hp,500)
 scroll_rate,safety=0,false

 local turn,frame=(n-1)\slot+1,(n-1)%slot
 local weapon=weapon_specs[turn]
 if weapon then
  local alt=alt_specs[weapon.name]
  if frame==0 then
   player.weapon,player.heat,player.overheated=turn,0,false
   weapon.wait,weapon.rounds=0,weapon.ammo
   brute.hp=900
   hp_before=900
  end
  if frame>=2 and frame<56 then held[2]=true end
  if frame==55 then
   check(weapon.name..": a held charge fires nothing",#shots==0,"shots "..#shots)
  end
  if frame==slot-1 then
   local took,most=hp_before-brute.hp,alt.damage*alt.count*(1+alt.stream)
   check(weapon.name.." overcharged",took>=alt.damage and took<=most,
    "did "..took.." of at most "..most)
  end
 else
  -- the two cases with the pulse gun
  local late=n-#weapon_specs*slot
  if late==1 then
   player.weapon,player.heat=1,0
   hp_before=brute.hp
  end
  if late>=5 and late<25 then held[2]=true end
  if late==80 then
   check("let go early: nothing fired",brute.hp==hp_before,"hp "..brute.hp)
  end
  if late>=90 and late<120 then held[2],held[4]=true,true end
  if late==119 then
   check("fire is held back while charging",brute.hp==hp_before,"hp "..brute.hp)
  end
  if late==125 then
   printh("ok charge")
   extcmd("shutdown")
  end
 end

 game_update()
 game_draw()
 if n==58 then
  check("an overcharged shot costs twice the heat",
   player.heat>weapon_specs.pulse.heat*2-1,"heat "..player.heat)
 end
 -- a picture of each overcharge a third of a second after it is let go
 if weapon and frame==76 then dump_screen("charge_"..weapon.name) end
end
