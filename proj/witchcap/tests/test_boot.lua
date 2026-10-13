-- test_boot.lua : the real cart, with nothing stubbed but the buttons,
-- the sound and the save: the title, a press, some seconds of running and
-- jumping (poisoned for part of it), then both endings, all drawn.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx

local n=0
local game_update,game_draw=_update60,_draw

local function expect_mode(wanted)
 if mode!=wanted then
  printh("error: frame "..n.." is in mode "..mode..", wanted "..wanted)
 end
end

function _draw() end

function _update60()
 n+=1
 held={}
 if n==40 or n==450 then held[5]=true end
 if n>40 and n<400 then
  held[1],held[4],held[5]=true,n%60<30,n%45==0
 end
 if n==200 then witch.poison=poison_frames end
 if n==400 then end_run(true) end
 if n==500 then frames_left=1 end
 game_update()
 game_draw()
 if n==5 then expect_mode("title") dump_screen("boot_title") end
 if n==190 then expect_mode("play") dump_screen("boot_play") end
 if n==410 then expect_mode("brewed") dump_screen("boot_brewed") end
 if n==460 then expect_mode("play") end
 if n==510 then expect_mode("cold") dump_screen("boot_cold") end
 if n==520 then
  printh("ok boot")
  extcmd("shutdown")
 end
end
