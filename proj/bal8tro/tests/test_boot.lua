last_frame=60

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
end
