-- motion.lua : plays bal8tro through the same sequence as balatro_ref's
-- harness (deal, two jokers, a discard of the last two cards, a pair played
-- and scored, the cash-out) at the same times, and logs every card every
-- frame in the harness's format, so balatro_ref/motion_metrics.py and
-- compare_motion.py can set the two games side by side:
--   card <seconds> <id> <area> <x> <y> <scale> <rotation>
-- x and y in card widths (15) and heights (21) from the hand's top left
-- (41,78); a card's swell (in card heights) stands in for Balatro's scale. Run it by name:
--   py run_tests.py tests/motion.p8

local held,n,ids,next_id={},0,{},0
skip_intro=true
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx

local start=40
local presses=parse_record[[
40=4
60=4
1600=4
2560=4
2920=4
3160=4
3540=4
4800=4
]]

local events=parse_record[[
60=deal
3196=select_shown
370=joker
430=pick_discard
470=discard
610=pick
760=play
1600=cash_out
2560=pack_open
2920=pack_skip
3160=shop_exit
3540=select_blind
3900=lose_play
4800=new_run
5160=win
]]

local game_update,game_draw=_update60,_draw
function _draw() end

local function log_card(card,area)
 if not card.x then return end
 if not ids[card] then
  next_id+=1
  ids[card]=next_id
 end
 printh("card "..(n/60).." "..ids[card].." "..area.." "..((card.x-41)/15).." "..((card.y-78)/21).." "..(1+(card.swell or 0)/21).." 0")
end

local function motion_frame()
 n+=1
 held={}
 if presses[n] then held[presses[n]]=true end
 if events[n] then printh("event "..(n/60).." "..events[n]) end
 if n==370 then jokers=jokers_of("joker,jolly") end
 if n==430 then hand[#hand].picked,hand[#hand-1].picked=true,true end
 if n==470 then discard_hand() end
 if n==610 then
  hand[1].rank,hand[2].rank,hand[1].suit,hand[2].suit=13,13,1,2
  hand[1].picked,hand[2].picked=true,true
 end
 if n==760 then play_hand() end
 if n==2559 then
  money,shop_focus.row,shop_focus.columns[3]=50,3,1
 end
 if n==2919 then pack_focus.row,pack_focus.columns[2]=2,#pack_choices+1 end
 if n==3159 then shop_focus.row,shop_focus.columns[2]=2,1 end
 if n==3900 then
  hands_left,hand[1].picked=1,true
  play_hand()
 end
 if n==5160 then
  end_run"won"
 end
 game_update()
 game_draw()
 if n==1605 or n==1640 or n==1700 or n==1800 then dump_screen("motion_cashout_"..n) end
 if n>=start then
  for card in all(hand) do if card.wait==0 then log_card(card,"hand") end end
  for card in all(played) do log_card(card,"play") end
  for card in all(flying) do log_card(card,"discard") end
  for joker in all(jokers) do log_card(joker,"jokers") end
  printh("hud "..(n/60).." "..chips.." "..mult.." "..big_text(score or 0))
  if mode=="cashout" and banner.y then printh("ui "..(n/60).." cash_out 0 "..((40+banner.y-78)/21)) end
  if end_specs[mode] and banner.y then printh("ui "..(n/60).." overlay 0 "..((28+banner.y-78)/21)) end
  if mode=="shop" and shop_panel.y then
   printh("ui "..(n/60).." shop 0 "..((27+shop_panel.y-78)/21))
   for item in all(shop_items) do log_card(item,"shop_jokers") end
   for pack in all(shop_packs) do log_card(pack,"shop_booster") end
  end
  if mode=="select" and select_panel.y then printh("ui "..(n/60).." blind_select 0 "..((27+select_panel.y-78)/21)) end
  if mode=="pack" then
   for item in all(pack_choices) do log_card(item,"pack") end
  end
 end
 if n==5300 then
  printh("ok motion")
  extcmd("shutdown")
 end
end

function jokers_of(text)
 local named={}
 for name in all(split(text,",",false)) do add(named,setmetatable({},joker_specs[name])) end
 return named
end

function _update60()
 run_frame(motion_frame)
end
