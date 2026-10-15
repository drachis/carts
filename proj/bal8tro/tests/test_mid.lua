last_frame=284

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
end
