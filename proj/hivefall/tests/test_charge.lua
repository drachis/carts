-- test_charge.lua : the overcharge, alone. a brute stands still in the
-- cone with its armour on (so it will not die), and the mech has the pulse
-- gun. three cases:
--   up held past full, then let go: one shot, over_damage times as hard,
--     and twice a normal shot's heat;
--   up let go early: nothing is fired;
--   fire held while up is held: nothing is fired until up is let go.
-- it does not judge whether charging feels good or is worth doing.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx
function update_waves() end

local n=0
local game_update,game_draw=_update60,_draw
local brute,hp_before

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
  safety=false
  brute=spawn_foe(enemy_specs.brute,0,2.5,0)
  brute.sway,brute.brood,brute.speed=0
  hp_before=brute.hp
 end
 brute.z=2.5
 scroll_rate=0

 -- case 1: a full charge, frames 5..64, let go at 65
 if n>=5 and n<65 then held[2]=true end
 if n==64 then
  check("a held charge fires nothing",brute.hp==hp_before and #shots==0,
   "hp "..brute.hp.." shots "..#shots)
  player.heat=0
 end
 if n==120 then
  local pulse=weapon_specs.pulse
  check("let go when full: one shot at "..over_damage.." times the damage",
   hp_before-brute.hp==pulse.damage*over_damage,
   "took "..hp_before-brute.hp.." wanted "..pulse.damage*over_damage)
  hp_before=brute.hp
 end
 -- case 2: let go early, frames 130..150
 if n>=130 and n<150 then held[2]=true end
 if n==200 then
  check("let go early: nothing fired",brute.hp==hp_before,"hp "..brute.hp)
 end
 -- case 3: fire held under a charge, frames 210..240
 if n>=210 and n<240 then held[2],held[4]=true,true end
 if n==239 then
  check("fire is held back while charging",brute.hp==hp_before,"hp "..brute.hp)
 end

 game_update()
 game_draw()
 if n==66 then
  check("an overcharged shot costs twice the heat",
   player.heat>weapon_specs.pulse.heat*2-1,"heat "..player.heat)
 end
 if n==50 then dump_screen("charge") end
 if n==245 then
  printh("ok charge")
  extcmd("shutdown")
 end
end
