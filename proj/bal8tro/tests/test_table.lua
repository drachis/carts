last_frame=340

function check(n)
 if n==283 then dump_screen("boot_tooltip") end
 if n==287 then expect("down goes back to the hand",table_focus.row,2) end
 if n==289 then expect("left from the first button wraps to info",button_focus,4) dump_screen("boot_buttons") end
 if n==291 then expect_mode("info") dump_screen("boot_info") end
 if n==293 then expect("right shows the deck tab",info_tab,2) dump_screen("boot_deck") end
 if n==295 then expect_mode("play") end
 if n==297 then expect("pressing sort sorts by suit",sort_by_suit,true) end
 if n==306 then expect("the discard button is left of sort",button_focus,2) end
 if n==307 then expect("the discard flies off",#flying,1) dump_screen("boot_discard") end
 if n==309 then expect("discards left (red deck: 4, one used)",discards_left,3) expect("hand refilled",#hand,8) end
 if n==338 then expect("the discard has left the screen",#flying,0) end
 if n==339 then
  cls(0)
  camera(0,-110)
  print_centre("blind defeated!",50,11,60)
  camera()
  local stray=0
  for y=0,30 do for x=0,127 do stray+=pget(x,y)>0 and 1 or 0 end end
  expect("centred text under a sliding panel leaves the top rows clean (the user saw cash-out text top left)",stray,0)
 end
end
