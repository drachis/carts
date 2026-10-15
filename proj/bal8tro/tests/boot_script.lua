-- boot_script.lua : the scripted run shared by test_boot, test_mid and
-- test_late. Each of those carts includes the whole real game, dump.lua,
-- this, then its own check(n) for the frames it owns and last_frame. The
-- game plus every check passed 8192 tokens in one cart, so the checks are
-- split by frame; every cart replays the same run from the title.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
function music(pattern) started_music=pattern end

local n=0
parse_record("step_frames=18,joker_frames=18,score_delay=30,total_gap=18,total_hold=45,shop_wait=0,exit_wait=0,pack_wait=0,pack_hold=0,shop_return=0,skip_select=1,score_wait=0,score_roll=8,play_delay=0,play_stagger=0,deal_frames=4",",",_ENV)
local game_update,game_draw=_update60,_draw

function expect_mode(wanted)
 if mode!=wanted then
  printh("error: frame "..n.." is in mode "..tostr(mode)..", wanted "..wanted)
 end
end

function expect(what,got,wanted)
 printh((got==wanted and "pass: " or "error: ")..what.." (got "..tostr(got)..", wanted "..tostr(wanted)..")")
end

function jokers_named(names)
 local named={}
 for name in all(split(names)) do add(named,setmetatable({},joker_specs[name])) end
 return named
end

local function cards_from(text)
 local cards={}
 for pair in all(split(text,"|")) do
  local values=split(pair)
  add(cards,{rank=values[1],suit=values[2]})
 end
 return cards
end

local presses=parse_record[[
10=0
12=0
14=1
16=1
40=4
50=4
52=1
54=4
58=5
240=4
248=4
250=4
252=2
254=1
256=4
258=3
264=4
266=0
268=4
280=2
282=1
286=3
288=3
289=0
290=4
292=1
294=4
295=0
296=4
300=2
302=4
304=3
305=0
306=4
309=2
310=4
314=5
490=4
510=4
512=5
620=4
622=3
624=4
628=0
630=4
632=2
634=0
636=0
638=4
670=4
672=5
]]

function _draw() end

function _update60()
 run_frame(boot_frame)
end

function boot_frame()
 n+=1
 held={}
 if presses[n] then held[presses[n]]=true end
 if n==45 then
  hand=cards_from"13,1|13,2|9,3|7,4|5,1|4,2|3,3|2,4"
  jokers=jokers_named"joker,greedy,sly"
 end
 if n==245 then
  shop_items=jokers_named"jolly"
  add(shop_items,{hand=hand_specs.pair,name="mercury",cost=planet_cost})
  money=10
 end
 if n==308 then hands_left=1 end
 if n==623 then shop_packs[1]=setmetatable({},pack_specs.arcana) end
 if n==500 or n==660 then
  ante=n==500 and 1 or #ante_bases
  blind=#blind_specs
  boss=boss_specs[n==500 and "the needle" or "the club"]
  start_blind()
  score=goal
  if n==660 then
   hand=cards_from"13,3|9,3|9,2|5,4|3,1|2,3|2,2|2,4"
   jokers=jokers_named"scary,glutton"
  end
 end
 game_update()
 game_draw()
 check(n)
 if n==last_frame then
  printh("ok "..sub(log_name,5))
  extcmd("shutdown")
 end
end
