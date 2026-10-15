last_frame=83

function check(n)
 if n==5 then dump_screen("boot_title") end
 if n==5 or n==41 then
  expect("music at frame "..n,started_music,n==41 and music_table or music_calm)
 end
 if n==11 or n==13 or n==17 then expect("deck choice at frame "..n,deck_choice,n==11 and 5 or n==13 and 4 or 1) end
 if n==13 then dump_screen("boot_decks") end
 if n==41 or n==80 then
  local waiting=0
  for card in all(hand) do if card.wait>0 then waiting+=1 end end
  expect("cards still on the deck at frame "..n,waiting,n==41 and 7 or 0)
 end
end
