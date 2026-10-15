last_frame=820

function check(n)
 if n==480 then expect_mode("lost") dump_screen("boot_lost") end
 if n==492 then expect("restart clears jokers",#jokers,0) end
 if n==505 then expect("the needle gives one hand",hands_left,1) end
 if n==615 then expect_mode("cashout") expect("the boss pays $5",earnings[1][2],5) end
 if n==621 then dump_screen("boot_shop_ante") end
 if n==626 then expect_mode("pack") dump_screen("boot_pack") end
 if n==631 then expect_mode("shop") end
 if n==645 then
  expect_mode("play")
  expect("after the boss",ante..","..blind..","..big_text(goal),"2,1,800")
  dump_screen("boot_ante_2")
 end
 if n==668 then dump_screen("boot_boss") end
 if n==810 then
  expect_mode("won")
  dump_screen("boot_won")
  chips,mult,step_timer,score=1000,500,999,0
  mode="score"
 end
 if n==817 then
  expect("a hand of 5x the goal sets the floor alight",heat>=4,true)
  dump_screen("boot_inferno")
 end
end
