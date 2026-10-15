-- golden.lua : the whole real game played through one fixed run, a
-- checksum of the screen and the main state printed every frame, so a
-- refactor of the drawing can be proved to change nothing (golden-refactor
-- skill). The clock is the frame count and rnd is seeded, so every run
-- prints the same lines. It covers the title, deck choice, blind select,
-- the deal, the joker row's tooltip, a pick and a play, scoring with four
-- jokers, the cash-out, the shop (tooltip, a buy, a pack opened and
-- skipped, next blind), the second select, the info overlay's two tabs
-- and a lost hand. Not covered: the won screen, other packs, tarot use.
-- Too tight for dump.lua: it prints to its own log directly.
--   py golden_compare.py save    --run "py run_tests.py tests/golden.p8" --log tests/golden.p8l --base tests/golden.base
--   py golden_compare.py compare --run "py run_tests.py tests/golden.p8" --log tests/golden.p8l --base tests/golden.base

local n,held=0,{}
skip_intro=true
function t() return n/60 end
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx

local presses=parse_record[[
20=1
22=0
40=4
60=4
250=2
256=3
260=4
262=1
264=4
290=5
1000=4
1280=2
1290=3
1300=4
1340=3
1350=4
1520=0
1530=4
1620=2
1625=0
1630=0
1640=4
1700=4
1900=3
1902=0
1904=4
1930=1
1950=4
1966=2
1970=4
1980=5
]]

local game_update,game_draw=_update60,_draw
function _draw() end

function _update60()
 n+=1
 if n==1 then
  srand(7)
  printh("started","golden",true)
 end
 held={[presses[n] or 9]=true}
 if n==200 then
  jokers={}
  for name in all(split"joker,greedy,sly,jolly") do add(jokers,setmetatable({},joker_specs[name])) end
  money,score=50,goal-0x.0001
 end
 if n==1960 then hands_left=1 end
 game_update()
 game_draw()
 local sum=0
 for address=0x6000,0x7ffc,4 do sum=bxor(rotl(sum,1),$address) end
 printh(n.." "..tostr(sum,true).." "..mode.." "..tostr(money).." "..big_text(score or 0).." "..tostr(hands_left),"golden")
 if n==2700 then
  printh("ok golden","golden")
  extcmd("shutdown")
 end
end
