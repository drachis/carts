-- test_boot.lua : the real cart, nothing stubbed but input and sound, from
-- its first frame, every frame drawn: the title, a start, a bot pacing,
-- firing, boosting and venting, the shop, the boss arriving and dying, an
-- alpha strike, drops, the city falling, a restart and the win.
--
-- it is kept short (480 frames, two screens dumped): headless pico-8
-- crashes far more on long, fully drawn tests. see DESIGN.md.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx

local n=0
local game_update,game_draw=_update60,_draw

function _draw() end

function _update60()
 n+=1
 held={}
 if n==10 or n==425 then held[4]=true end
 if n>10 and n<330 then
  held[n\40%2]=true
  held[4]=n%30<20
  held[5]=n%50==0
  held[2]=n%90<20
  if n%120<16 then held[4],held[5]=true,true end
 end
 if n==150 then open_shop() end
 if n==200 then
  state="play"
  spawn_group("tyrant",1)
 end
 if n==230 then
  boss.z=2.5
  charge=alpha_cost
  held[3]=true
  add(drops,{x=player.x,z=1.2,kind="cool",colour=12})
  add(drops,{x=0,z=3,kind="flak",colour=9,weapon=weapon_specs.flak})
 end
 if n==250 then hurt_foe(boss,9999) end
 if n==330 then hurt_city(999) end
 if n==450 then end_game(true,"the hive is broken") end
 game_update()
 game_draw()
 if n==5 then dump_screen("boot_title") end
 if n==245 then dump_screen("boot_play") end
 if n==480 then
  printh("ok boot")
  extcmd("shutdown")
 end
end
