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

function run_cases()
 reset_levels()
 boss=boss_specs["the club"]
 for case in all(hand_cases) do
  local spec,scoring=evaluate(cards_of(case[1]))
  expect(case[1].." is",spec.name,case[2])
  expect(case[1].." scores cards",#scoring,case[3])
 end
 local _,_,_,label=evaluate(cards_of("ah kh qh jh th"))
 expect("royal flush label",label,"royal flush")
 for case in all(score_cases) do
  expect(case[1].." with "..case[2],total_of(case[1],case[2]),case[3])
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
end
