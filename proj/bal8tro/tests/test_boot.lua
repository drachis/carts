local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
music=sfx

local n=0
local game_update,game_draw=_update60,_draw

local function expect_mode(wanted)
 if mode!=wanted then
  printh("error: frame "..n.." is in mode "..tostr(mode)..", wanted "..wanted)
 end
end

local function expect(what,got,wanted)
 printh((got==wanted and "pass: " or "error: ")..what.." (got "..tostr(got)..", wanted "..tostr(wanted)..")")
end

local function known_hand()
 hand={}
 for pair in all(split("13,1|13,2|9,3|7,4|5,1|4,2|3,3|2,4","|")) do
  local values=split(pair)
  add(hand,{rank=values[1],suit=values[2]})
 end
 jokers={}
 for name in all(split"joker,greedy,sly") do add(jokers,setmetatable({},joker_specs[name])) end
end

local presses=parse_record[[
40=4
50=4
52=1
54=4
58=5
240=4
250=4
252=3
270=4
274=5
440=4
460=4
462=5
]]

function _draw() end

function _update60()
 run_frame(boot_frame)
end

function boot_frame()
 n+=1
 held={}
 if presses[n] then held[presses[n]]=true end
 if n==45 then known_hand() end
 if n==268 then hands_left=1 end
 if n==450 then
  blind=#blind_specs
  start_blind()
  score=goal
 end
 game_update()
 game_draw()
 if n==5 then dump_screen("boot_title") end
 if n==41 then expect_mode("play") end
 if n==57 then dump_screen("boot_pick") expect("hand picked",hand_label,"pair") end
 if n==150 then dump_screen("boot_score") end
 if n==230 then
  expect_mode("cleared")
  expect("score of kings with joker and sly",big_text(score),"480")
  dump_screen("boot_cleared")
 end
 if n==245 then expect_mode("play") expect("blind",blind,2) end
 if n==255 then expect("discards left",discards_left,2) expect("hand refilled",#hand,8) end
 if n==430 then expect_mode("lost") dump_screen("boot_lost") end
 if n==660 then expect_mode("won") dump_screen("boot_won") end
 if n==670 then
  printh("ok boot")
  extcmd("shutdown")
 end
end
