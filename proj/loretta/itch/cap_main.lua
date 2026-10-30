local frame,sec,left=0,0,0
function sfx() end
music,dset=sfx,sfx
local game_update=_update60

local function go(wanted,x)
 level,score,coins=wanted,0,0
 start_level()
 mode="play"
 hero.x=x or hero.x
 view.x=focus_x(hero,view)
end

local function runner()
 local front=hero.x+hero_w+3
 local input=2
 if (area_has(front,hero.y,2,hero_h-4,0) or not area_has(front+8,hero.y+hero_h,2,40,0)) and frame%16<4 then input|=16 end
 if frame%100==40 then input|=32 end
 if frame%170==90 then input|=8 end
 return input
end

local sections={
 {"chase",function() go(1,40) end,runner},
 {"hills",function() go(2,3*256-16) end,runner},
 {"pet",function()
   go(1,600)
   for thing in all(things) do
    if thing.name=="neighbour" then hero.x=thing.x-44 end
   end
   view.x=focus_x(hero,view)
  end,function() return 8 end},
 {"finale",function() go(#levels,0) hero.x,hero.y=level_w-150,20 view.x=focus_x(hero,view) end,function() return 2 end},
}

function read_input() return sections[sec][3]() end

function _update60()
 if sec>#sections then
  left-=1
  if left==0 then printh("ok cap_main","cap_main") end
  return
 end
 if left==0 then
  if sec>0 then extcmd("video") end
  sec+=1
  if not sections[sec] then
   left=180
   return
  end
  frame,left=0,480
  srand(7)
  sections[sec][2]()
  extcmd("set_filename","loretta_"..sections[sec][1])
  extcmd("rec")
 end
 frame+=1
 left-=1
 game_update()
 if frame==240 then extcmd("screen") end
end

set_palette()
printh("started","cap_main",true)
