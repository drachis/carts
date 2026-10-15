function enhanced(text,which)
 local cards=cards_of(text)
 cards[2].enhancement=which
 return cards
end

function tarot_cases()
 reset_levels()
 hand={}
 expect("a mult card adds 4 mult",score_of(enhanced("kh ks","mult")),30*6)
 expect("a bonus card adds 30 chips",score_of(enhanced("kh ks","bonus")),60*2)
 expect("a glass card doubles mult",score_of(enhanced("kh ks","glass")),30*4)
 expect("a wild card makes the flush",evaluate(enhanced("2h ks 9h jh 7h","wild")).name,"flush")
 hand=enhanced("2c 3c","steel")
 expect("a steel card held multiplies by 1.5",score_of(cards_of("kh ks")),30*3)
 hand={}
 run_deck=new_deck()
 pack_hand={run_deck[1],run_deck[2],run_deck[14]}
 run_deck[1].picked,run_deck[2].picked=true,true
 expect("the empress makes two mult cards",tostr(use_tarot(tarot_specs.empress))..","..run_deck[1].enhancement..","..run_deck[2].enhancement,"true,mult,mult")
 run_deck[1].picked,run_deck[2].picked,run_deck[14].picked=true,true,true
 expect("the lovers refuse three cards",tostr(use_tarot(tarot_specs.lovers) or false),"false")
 use_tarot(tarot_specs.star)
 expect("the star turns three to diamonds",run_deck[1].suit..run_deck[2].suit..run_deck[14].suit,"444")
 run_deck[13].picked=true
 pack_hand={run_deck[13]}
 use_tarot(tarot_specs.strength)
 expect("strength takes an ace round to 2",run_deck[13].rank,2)
 local doomed=run_deck[1]
 doomed.picked,pack_hand=true,{doomed}
 use_tarot(tarot_specs["hanged man"])
 expect("the hanged man destroys",#run_deck..","..count(run_deck,doomed),"51,0")
 money=15
 use_tarot(tarot_specs.hermit)
 expect("the hermit doubles money up to $20",money,30)
 money=4
 open_pack(pack_specs.arcana)
 expect("an arcana pack deals a hand to aim at",#pack_choices..","..#pack_hand..","..tostr(pack_choices[1].act!=nil),"3,8,true")
 mode,pack_hand="title",{}
end

function deck_choice_cases()
 local abandoned,checkered,suits=new_deck(deck_specs.abandoned),new_deck(deck_specs.checkered),{0,0,0,0}
 for card in all(checkered) do suits[card.suit]+=1 end
 expect("abandoned has no face cards, checkered only spades and hearts",#abandoned..","..suits[1]..","..suits[2]..","..suits[3]+suits[4],"40,26,26,0")
 deck_choice=2
 start_run()
 expect("the blue deck plays 5 hands",hands_left..","..discards_left,"5,3")
 deck_choice=3
 start_run()
 expect("the yellow deck starts with $14",money,14)
 deck_choice,mode=1,"title"
end

function run_cases()
 tarot_cases()
 deck_choice_cases()
end
