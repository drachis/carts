local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
local started_music
function music(pattern) started_music=pattern end

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

local function jokers_named(names)
 local named={}
 for name in all(split(names)) do add(named,setmetatable({},joker_specs[name])) end
 return named
end

local function index_of(text,letter)
 for i=1,#text do
  if sub(text,i,i)==letter then return i end
 end
end

local function cards_named(names)
 local cards={}
 for name in all(split(names,"|",false)) do
  add(cards,{rank=1+index_of("23456789tjqka",sub(name,1,1)),suit=index_of("shcd",sub(name,2,2))})
 end
 return cards
end

local function known_hand()
 hand={}
 for pair in all(split("13,1|13,2|9,3|7,4|5,1|4,2|3,3|2,4","|")) do
  local values=split(pair)
  add(hand,{rank=values[1],suit=values[2]})
 end
 jokers=jokers_named"joker,greedy,sly"
end

local presses=parse_record[[
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
260=3
262=0
264=4
266=1
268=4
280=2
282=1
286=3
288=3
289=0
290=4
292=2
294=4
296=3
297=0
298=4
309=2
310=4
314=5
490=4
510=4
512=5
620=4
622=3
624=3
626=1
628=4
650=4
652=5
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
 if n==245 then
  shop_items=jokers_named"jolly"
  add(shop_items,{hand=hand_specs.pair,name="mercury",cost=planet_cost})
  money=10
 end
 if n==308 then hands_left=1 end
 if n==500 or n==640 then
  ante=n==500 and 1 or #ante_bases
  blind=#blind_specs
  boss=boss_specs[n==500 and "the needle" or "the club"]
  start_blind()
  score=goal
  if n==640 then
   hand=cards_named"kc|9c|9h|5d|3s|2c|2h|2d"
   jokers=jokers_named"scary,glutton"
  end
 end
 game_update()
 game_draw()
 if n==5 then dump_screen("boot_title") end
 if n==5 or n==41 or n==242 then
  expect("music at frame "..n,started_music,n==41 and music_table or music_calm)
 end
 if n==41 or n==80 then
  local waiting=0
  for card in all(hand) do if card.wait>0 then waiting+=1 end end
  expect("cards still on the deck at frame "..n,waiting,n==41 and 7 or 0)
 end
 if n==41 then
  expect_mode("play")
  expect("a run starts with no jokers",#jokers,0)
  expect("a run starts with $4",money,4)
 end
 if n==51 then expect("a picked card glides, not jumps (y "..hand[1].y..")",hand[1].y>=72 and hand[1].y<=76,true) end
 if n==57 then expect("a picked card has risen (y "..hand[1].y..")",hand[1].y<=74,true) end
 if n==57 then dump_screen("boot_pick") expect("hand picked",hand_label..hand_level,"pair1") end
 if n==281 then expect("up looks at the jokers",joker_focus,1) end
 if n==283 then dump_screen("boot_tooltip") end
 if n==287 then expect("down goes back to the hand",table_focus.row,2) end
 if n==289 then expect("left from the first button wraps to sort",button_focus,3) dump_screen("boot_buttons") end
 if n==291 then expect("pressing sort sorts by suit",sort_by_suit,true) end
 if n==298 then expect("the discard button remembers its row",button_focus,2) end
 if n==150 then
  printh("cpu while scoring with flames: "..stat(1).." at "..stat(7).." fps")
  dump_screen("boot_score")
 end
 if n==120 or n==148 then
  local flames=0
  for p in all(particles) do if p.spec.name=="flame" then flames+=1 end end
  expect("flames at frame "..n.." (on once 80x6 beats 300)",flames>0,n==148)
 end
 if n==89 then
  expect("a scoring card throws sparks and bumps chips",#particles>0 and chips_bump>0,true)
  expect("a scoring card is kicked",played[1].kick>0,true)
 end
 if n==125 then expect("a joker shakes when it fires",jokers[1].kick>0,true) end
 if n==161 then expect("the total holds the game for a beat",freeze>0,true) end
 if n==43 then
  local turning=0
  for card in all(hand) do if (card.flip or 1)<1 then turning+=1 end end
  expect("a dealt card turns over as it flies",turning>0,true)
  dump_screen("boot_deal")
 end
 if n==162 then
  local big
  for p in all(pops) do if p.big then big=p.text end end
  expect("the total pops up big",big,"480")
  expect("the total shakes the screen",shake>1,true)
  dump_screen("boot_total")
 end
 if n==230 then
  expect_mode("cashout")
  expect("score of kings with joker and sly",big_text(score),"480")
  expect("money after $3 blind, 3 hands, no interest",money,4+3+3)
  dump_screen("boot_cashout")
 end
 if n==242 then expect_mode("shop") expect("shop offers",#shop_items,2) end
 if n==247 then dump_screen("boot_shop") end
 if n==249 then expect("bought jolly for $3",#jokers..",$"..money,"4,$7") end
 if n==251 then expect("mercury bought with the joker slots full",#jokers..",$"..money..",lv"..hand_levels.pair,"4,$4,lv2") end
 if n==257 then expect("sold greedy for $2",#jokers..",$"..money..","..jokers[2].name,"3,$6,sly") end
 if n==261 then expect("down twice reaches the buttons",shop_row..","..shop_column,"3,2") end
 if n==263 then dump_screen("boot_shop_buttons") end
 if n==265 then expect("rerolled for $5",money..","..reroll_cost..","..#shop_items,"1,6,2") end
 if n==270 then expect_mode("play") expect("blind",blind,2) expect("jokers kept",#jokers,3) end
 if n==299 then expect("the discard flies off",#flying,1) dump_screen("boot_discard") end
 if n==301 then expect("discards left",discards_left,2) expect("hand refilled",#hand,8) end
 if n==330 then expect("the discard has left the screen",#flying,0) end
 if n==480 then expect_mode("lost") dump_screen("boot_lost") end
 if n==492 then expect("restart clears jokers",#jokers,0) end
 if n==505 then expect("the needle gives one hand",hands_left,1) end
 if n==648 then dump_screen("boot_boss") end
 if n==615 then expect_mode("cashout") expect("the boss pays $5",earnings[1][2],5) end
 if n==621 then dump_screen("boot_shop_ante") end
 if n==630 then
  expect_mode("play")
  expect("after the boss",ante..","..blind..","..big_text(goal),"2,1,800")
  dump_screen("boot_ante_2")
 end
 if n==790 then
  expect_mode("won") dump_screen("boot_won")
  chips,mult,step_timer,score=1000,500,999,0
  mode="score"
 end
 if n==797 then
  expect("a hand of 5x the goal sets the floor alight",heat>=4,true)
  dump_screen("boot_inferno")
 end
 if n==800 then
  printh("ok boot")
  extcmd("shutdown")
 end
end
