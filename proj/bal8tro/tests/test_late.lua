last_frame=629

function check(n)
 if n==480 then expect_mode("lost") dump_screen("boot_lost") end
 if n==492 then expect("restart clears jokers",#jokers,0) end
 if n==505 then expect("the needle gives one hand",hands_left,1) end
 if n==615 then expect_mode("cashout") expect("the boss pays $5",earnings[1][2],"$5") end
 if n==621 then dump_screen("boot_shop_ante") end
 if n==626 then expect_mode("pack") dump_screen("boot_pack") end
end
