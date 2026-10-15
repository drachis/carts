last_frame=200

function check(n)
 if n==5 then dump_screen("boot_title") end
 if n==11 or n==13 or n==17 then expect("deck choice at frame "..n,deck_choice,n==11 and 5 or n==13 and 4 or 1) end
 if n==13 then dump_screen("boot_decks") end
 if n==5 or n==41 then
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
 if n==43 then
  local turning=0
  for card in all(hand) do if (card.flip or 1)<1 then turning+=1 end end
  expect("a dealt card turns over as it flies",turning>0,true)
  dump_screen("boot_deal")
 end
 if n==51 then expect("a picked card glides, not jumps (y "..hand[1].y..")",hand[1].y>=74 and hand[1].y<=78,true) end
 if n==57 then
  expect("a picked card has risen (y "..hand[1].y..")",hand[1].y<=76,true)
  dump_screen("boot_pick")
  expect("hand picked",hand_label..hand_level,"pair1")
 end
 if n==89 then
  expect("a scoring card throws sparks and bumps chips",#particles>0 and chips_bump>0,true)
  expect("a scoring card is kicked",played[1].kick>0,true)
 end
 if n==120 or n==148 then
  local flames=0
  for p in all(particles) do if p.spec.name=="flame" then flames+=1 end end
  expect("flames at frame "..n.." (on once 80x6 beats 300)",flames>0,n==148)
 end
 if n==125 then expect("a joker shakes when it fires",jokers[1].kick>0,true) end
 if n==150 then
  printh("cpu while scoring with flames: "..stat(1).." at "..stat(7).." fps")
  dump_screen("boot_score")
 end
 if n==161 then expect("the total holds the game for a beat",freeze>0,true) end
 if n==162 then
  local big
  for p in all(pops) do if p.big then big=p.text end end
  expect("the total pops up big",big,"480")
  expect("the total shakes the screen",shake>1,true)
  dump_screen("boot_total")
 end
end
