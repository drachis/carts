function index_of(text,letter)
 for i=1,#text do
  if sub(text,i,i)==letter then return i end
 end
end

function cards_of(text)
 local cards={}
 for word in all(split(text," ",false)) do
  add(cards,{
   rank=1+index_of("23456789tjqka",sub(word,1,1)),
   suit=index_of("shcd",sub(word,2,2))
  })
 end
 return cards
end

function jokers_of(text)
 local jokers={}
 for name in all(split(text,",",false)) do
  add(jokers,setmetatable({},joker_specs[name]))
 end
 return jokers
end

function expect(what,got,wanted)
 printh((got==wanted and "pass: " or "error: ")..what.." (got "..tostr(got)..", wanted "..tostr(wanted)..")")
end

hand_cases={
 {"ah","high",1},
 {"ah kh","high",1},
 {"kh ks 2c","pair",2},
 {"kh ks 2c 2d 5s","two",4},
 {"7h 7s 7c 2d","three",3},
 {"5h 6s 7c 8d 9s","straight",5},
 {"ah 2s 3c 4d 5s","straight",5},
 {"ah ks qc jd ts","straight",5},
 {"qh ks ac 2d 3s","high",1},
 {"2h 7h 9h jh kh","flush",5},
 {"kh ks kc 2d 2s","full",5},
 {"9h 9s 9c 9d 2s","four",4},
 {"5h 6h 7h 8h 9h","sflush",5},
 {"2h 3h 4h 5h","high",1},
}

score_cases={
 {"kh ks","joker,sly",480},
 {"kh ks","joker,the duo",360},
 {"kd kh","greedy",150},
 {"kd kh","scary",180},
 {"2h 7h 9h jh kh","tribe,lusty",(35+38)*((4+15)*2)},
 {"kh ks 2c 2d 5s","mad,clever",(20+24+80)*(2+10)},
}

function boss_cases()
 blind=#blind_specs
 boss=boss_specs["the club"]
 local spec,_,_,steps=score_steps(cards_of("kc kh"),{})
 local chips,mult=hand_base(spec)
 for step in all(steps) do chips,mult=apply_step(step,chips,mult) end
 expect("the club: a debuffed king still makes the pair but scores nothing",spec.name..","..chips*mult,"pair,40")
 boss=boss_specs["the flint"]
 chips,mult=hand_base(hand_specs.pair)
 expect("the flint halves the pair's base",chips..","..mult,"5,1")
 boss=boss_specs["the psychic"]
 expect("the psychic refuses four cards",can_play(cards_of("2h 3h 4h 5h")),false)
 expect("the psychic takes five",can_play(cards_of("2h 3h 4h 5h 7s")),true)
 boss=boss_specs["the wall"]
 expect("the wall at ante 8",big_text(blind_goal(8,3)),"200000")
 expect("the needle and the wall are boss names",blind_name(3),"the wall")
 blind=1
 expect("small blinds are never debuffed",is_debuffed(cards_of("kc")[1]),false)
 expect("small blinds take one card",can_play(cards_of("kc")),true)
 boss=boss_specs["the club"]
end

function run_cases()
 reset_levels()
 boss_cases()
 for case in all(hand_cases) do
  local spec,scoring=evaluate(cards_of(case[1]))
  expect(case[1].." is",spec.name,case[2])
  expect(case[1].." scores cards",#scoring,case[3])
 end
 local _,_,_,label=evaluate(cards_of("ah kh qh jh th"))
 expect("royal flush label",label,"royal flush")
 for case in all(score_cases) do
  local spec,_,_,steps=score_steps(cards_of(case[1]),jokers_of(case[2]))
  local chips,mult=hand_base(spec)
  for step in all(steps) do chips,mult=apply_step(step,chips,mult) end
  expect(case[1].." with "..case[2],chips*mult,case[3])
 end
 hand_levels.pair=3
 local chips,mult=hand_base(hand_specs.pair)
 expect("pair at level 3 (mercury twice)",chips..","..mult,"40,4")
 expect("pair's title at level 3",hand_title(hand_specs.pair,"pair"),"pair lv3")
 hand_levels.sflush=2
 chips,mult=hand_base(hand_specs.sflush)
 expect("straight flush at level 2 (neptune)",chips..","..mult,"140,12")
 reset_levels()
 expect("big total",big_text(hand_total(300,200)),"60000")
 expect("bigger total",big_text(hand_total(1000,1000)),"1000000")
 local hand=cards_of("2s kh 2h as")
 sort_cards(hand)
 expect("sorted by rank",hand[1].rank..","..hand[4].suit,"14,1")
 sort_cards(hand,true)
 expect("sorted by suit",hand[1].suit..","..hand[1].rank,"2,13")
 for case in all(split("1,1,300|1,3,600|2,2,1200|4,3,10000|5,2,16500|8,1,50000|8,3,100000","|")) do
  local values=split(case,",",false)
  expect("goal of ante "..values[1].." blind "..values[2],big_text(blind_goal(tonum(values[1]),tonum(values[2]))),values[3])
 end
 local owned={}
 for i=1,#joker_specs-2 do add(owned,setmetatable({},joker_specs[i])) end
 local offered=deal_jokers(3,owned)
 expect("shop offers only jokers not owned",#offered..","..offered[1].cost..","..offered[2].cost,"2,8,8")
 expect("sell price is half the cost",sell_price(offered[1]),4)
 expect("a $2 joker sells for $1",sell_price(jokers_of("joker")[1]),1)
end

function _update60()
 run_frame(function()
  run_cases()
  printh("ok hands")
  extcmd("shutdown")
  _update60=function() end
 end)
end
