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
 local thing,biggest,smallest={},0,0
 kick(thing,4)
 for i=1,juice_frames do
  jiggle(thing)
  biggest,smallest=max(biggest,thing.swell),min(smallest,thing.swell)
 end
 expect("a kick swells past 2px and shrinks back past -1px, like Balatro's juice",biggest>2 and smallest<-1,true)
 jiggle(thing)
 expect("a kick settles after juice_frames",thing.swell,0)
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
 take_choice(pack_choices[2])
 expect("taking a planet levels its hand",hand_levels[planet.hand.name],2)
 open_pack(pack_specs.standard)
 take_choice(pack_choices[1])
 expect("a standard pack's card joins the run deck",#run_deck..","..tostr(run_deck[53]==pack_choices[1]),"53,true")
 jokers=jokers_of("joker,sly,jolly,zany")
 open_pack(pack_specs.buffoon)
 expect("a buffoon pack offers two jokers, refused with the slots full",#pack_choices..","..tostr(take_choice(pack_choices[1]) or false),"2,false")
 jokers,mode={},"title"
 reset_levels()
end

function run_cases()
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
