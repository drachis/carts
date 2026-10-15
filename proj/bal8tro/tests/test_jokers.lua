function boss_cases()
 mode="play"
 blind=#blind_specs
 boss=boss_specs["the club"]
 local spec=evaluate(cards_of("kc kh"))
 expect("the club: a debuffed king still makes the pair but scores nothing",spec.name..","..score_of(cards_of("kc kh")),"pair,40")
 boss=boss_specs["the flint"]
 local chips,mult=hand_base(hand_specs.pair)
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
 mode,ante,blind,boss,deck_spec,run_deck="shop",1,3,boss_specs["the needle"],deck_specs[1],new_deck()
 start_blind()
 expect("the needle's one hand applies when its blind starts from the shop",hands_left,1)
 boss,mode=boss_specs["the club"],"title"
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
 reset_levels()
 boss_cases()
 growing_cases()
end
