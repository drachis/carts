last_frame=340

function check(n)
 if n==230 then
  expect_mode("cashout")
  expect("score of kings with joker and sly",big_text(score),"480")
  expect("money after $3 blind, 3 hands, no interest",money,4+3+3)
  dump_screen("boot_cashout")
 end
 if n==242 then
  expect_mode("shop")
  expect("shop offers",#shop_items,2)
  expect("music in the shop",started_music,music_calm)
 end
 if n==247 then dump_screen("boot_shop") end
 if n==249 then expect("bought jolly for $3",#jokers..",$"..money,"4,$7") end
 if n==251 then expect("mercury bought with the joker slots full",#jokers..",$"..money..",lv"..hand_levels.pair,"4,$4,lv2") end
 if n==257 then expect("sold greedy for $2",#jokers..",$"..money..","..jokers[2].name,"3,$6,sly") end
 if n==261 then expect("after selling, down lands on reroll",shop_focus.row..","..shop_focus.columns[2],"2,2") end
 if n==263 then dump_screen("boot_shop_buttons") end
 if n==265 then expect("rerolled for $5",money..","..reroll_cost..","..#shop_items,"1,6,2") end
 if n==270 then
  expect_mode("play")
  expect("blind",blind,2)
  expect("jokers kept",#jokers,3)
 end
 if n==281 then expect("up looks at the jokers",joker_focus,1) end
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
end
