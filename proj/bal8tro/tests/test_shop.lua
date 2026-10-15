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

function deck_cases()
 local run=new_deck()
 run[1].suit,run[1].picked=4,true
 local first=shuffled(run)
 local second=shuffled(run)
 local found
 for card in all(second) do if card==run[1] then found=card end end
 expect("a shuffle holds the run's own cards, changes and all",#first..","..#second..","..found.suit..","..tostr(found.picked),"52,52,4,[nil]")
end

function pack_cases()
 reset_levels()
 jokers,run_deck={},new_deck()
 open_pack(pack_specs.celestial)
 local planet=pack_choices[2]
 expect("a celestial pack offers three planets",mode..","..#pack_choices..","..tostr(planet.hand!=nil),"pack,3,true")
 take_choice(2)
 expect("taking a planet levels its hand",hand_levels[planet.hand.name],2)
 open_pack(pack_specs.standard)
 take_choice(1)
 expect("a standard pack's card joins the run deck",#run_deck..","..tostr(run_deck[53]==pack_choices[1]),"53,true")
 jokers=jokers_of("joker,sly,jolly,zany")
 open_pack(pack_specs.buffoon)
 expect("a buffoon pack offers two jokers, refused with the slots full",#pack_choices..","..tostr(take_choice(1) or false),"2,false")
 jokers,mode={},"title"
 reset_levels()
end

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
 deck_choice_cases()
 tarot_cases()
 pack_cases()
 deck_cases()
 vfx_cases()
 local owned={}
 for i=1,#joker_specs-2 do add(owned,setmetatable({},joker_specs[i])) end
 local offered=deal_jokers(3,owned)
 local last,second=joker_specs[#joker_specs],joker_specs[#joker_specs-1]
 local names=offered[1].name..offered[2].name
 expect("shop offers only jokers not owned",#offered..","..tostr(names==second.name..last.name or names==last.name..second.name),"2,true")
 expect("sell price is half the cost",sell_price(jokers_of("the duo")[1]),4)
 expect("a $2 joker sells for $1",sell_price(jokers_of("joker")[1]),1)
end
