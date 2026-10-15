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

function vfx_cases()
 particles={}
 emit("spark",10,10,8)
 emit("flame",10,10,nil,3)
 expect("a spark preset throws its count, a flame its amount",#particles,11)
 local fired
 after(3,function() fired=true end)
 update_effects()
 update_effects()
 expect("a timer has not fired after 2 of 3 frames",fired,nil)
 update_effects()
 expect("a timer fires on its frame",fired,true)
 local thing={}
 kick(thing,4)
 local _,lift=jiggle(thing)
 expect("a kick lifts by half its size",lift,-2)
 for i=1,20 do jiggle(thing) end
 expect("a kick settles",thing.kick,0)
 hitstop(5)
 hitstop(2)
 expect("a shorter hitstop does not cut a longer one",freeze,5)
 freeze,particles=0,{}
end

function total_of(cards,names)
 local spec,_,_,steps=score_steps(cards_of(cards),jokers_of(names))
 local chips,mult=hand_base(spec)
 for step in all(steps) do chips,mult=apply_step(step,chips,mult) end
 return chips*mult
end

function growing_cases()
 reset_levels()
 discards_left=2
 expect("abstract: +3 mult for each of 3 jokers",total_of("kh ks","abstract,joker,sly"),(30+50)*(2+9+4))
 expect("banner: +30 chips for each of 2 discards",total_of("kh ks","banner"),(30+60)*2)
 expect("summit asleep with discards left",total_of("kh ks","summit"),30*2)
 discards_left=0
 expect("summit: +15 mult with no discards",total_of("kh ks","summit"),30*17)
 expect("half: +20 mult on 2 cards",total_of("kh ks","half"),30*22)
 expect("half asleep on 4 cards",total_of("kh ks 2c 3d","half"),30*2)
 hand_plays.pair=3
 expect("nova: +1 mult per pair played (3)",total_of("kh ks","nova"),30*5)
 jokers=jokers_of("green,bus")
 grow_jokers("play",cards_of("2h"))
 grow_jokers("play",cards_of("3h"))
 grow_jokers("discard")
 expect("green: two plays and a discard",jokers[1].count,1)
 expect("bus: two hands with no face card",jokers[2].count,2)
 grow_jokers("play",cards_of("kh"))
 expect("bus: a scoring face card resets it",jokers[2].count,0)
 local spec,_,_,steps=score_steps(cards_of("kh ks"),jokers)
 expect("green at 2 adds 2 mult; bus at 0 adds nothing",#steps..","..steps[3].mult,"3,2")
 jokers={}
 reset_levels()
end

function run_cases()
 vfx_cases()
 growing_cases()
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
 local title,level=hand_title(hand_specs.pair,"pair")
 expect("pair's title at level 3",title.." "..level,"pair 3")
 expect("a royal flush's title",hand_title(hand_specs.sflush,"royal flush"),"royal")
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
 local last,second=joker_specs[#joker_specs],joker_specs[#joker_specs-1]
 local names=offered[1].name..offered[2].name
 expect("shop offers only jokers not owned",#offered..","..tostr(names==second.name..last.name or names==last.name..second.name),"2,true")
 expect("sell price is half the cost",sell_price(jokers_of("the duo")[1]),4)
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
