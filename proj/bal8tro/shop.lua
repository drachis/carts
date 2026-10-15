function planet_item()
 local hand=rnd(hand_specs)
 return {hand=hand,name=hand.planet,cost=planet_cost}
end

function deal_shop()
 shop_items=deal_jokers(shop_slots,jokers)
 for i=1,#shop_items do
  if rnd()<planet_chance then shop_items[i]=planet_item() end
 end
end

function open_pack(pack)
 pack_open,pack_choices,pack_hand,pack_focus=pack,{},{},{row=2,columns={1,1,1}}
 local kind=pack.kind
 if kind=="joker" then pack_choices=deal_jokers(pack.choices,jokers) end
 for i=1,kind!="joker" and pack.choices or 0 do
  add(pack_choices,kind=="planet" and planet_item() or kind=="tarot" and setmetatable({},rnd(tarot_specs)) or {rank=2+flr(rnd(13)),suit=1+flr(rnd(4))})
 end
 for i,item in ipairs(pack_choices) do item.glide_x,item.glide_y,item.wait,item.hold=table_centre-10,40,0,pack_hold+(i-1)*play_stagger end
 if kind=="tarot" then
  local cards=shuffled(run_deck)
  for i=1,hand_size do add(pack_hand,cards[i]) end
  sort_cards(pack_hand)
 end
 mode="pack"
end

function use_tarot(tarot)
 local picked={}
 for card in all(pack_hand) do
  if card.picked then add(picked,card) end
 end
 if tarot.act=="money" then
  money+=min(money,20)
  return true
 end
 if #picked<1 or #picked>tarot.most then return end
 for card in all(picked) do
  card.picked=false
  kick(card,4)
  local act=tarot.act
  if act=="rank" then card.rank=card.rank==14 and 2 or card.rank+1
  elseif act=="destroy" then
   del(run_deck,card)
   del(pack_hand,card)
  else card[act]=tarot.value end
 end
 return true
end

function take_choice(item)
 if item.hand then
  hand_levels[item.hand.name]+=1
 elseif item.rank then
  add(run_deck,item)
 elseif item.act then
  if not use_tarot(item) then return end
 else
  if #jokers>=joker_slots then return end
  kick(add(jokers,item),4)
 end
 emit("shower",item.x or table_centre,item.y or 50)
 return true
end

function update_pack()
 local row,column=steer(pack_focus,{#jokers,#pack_choices+1,#pack_hand})
 if not btnp(4) then return end
 local card=row==3 and pack_hand[column]
 if card then
  local picked=0
  for other in all(pack_hand) do picked+=other.picked and 1 or 0 end
  if card.picked or picked<3 then card.picked=not card.picked kick(card,1.5) end
 elseif row==2 and (column>#pack_choices or take_choice(pack_choices[column])) then
  sfx(snd_pick)
  mode,leaving="shop"
  shop_panel.hold=shop_return
 end
end

function open_shop()
 deal_shop()
 shop_packs={}
 for i=1,2 do shop_packs[i]=setmetatable({},rnd(pack_specs)) end
 reroll_cost=reroll_base
 shop_focus={row=2,columns={1,3}}
 mode,leaving,exiting,shop_panel,sign="shop",false,false,panel_at(110),panel_at(-14)
end

function sell_price(joker)
 return max(1,joker.cost\2)
end

function shop_offer()
 local row,column=shop_focus.row,shop_focus.columns[shop_focus.row]
 local item=shop_items[column-2]
 if row==1 then
  item=jokers[column]
  return item and -sell_price(item),"sell for",function()
   emit("coin",item.x+10,item.y+10)
   deli(jokers,column)
  end
 end
 if row==3 then
  item=shop_packs[column]
  return item.cost,"open "..item.label,function()
   deli(shop_packs,column)
   leaving=true
   after(pack_wait,function() open_pack(item) end)
  end
 end
 if column==1 then
  return 0,"next blind",function()
   leaving,exiting=true,true
   after(exit_wait,function()
    ante,blind=next_blind()
    open_select()
   end)
  end
 end
 if column==2 then
  return reroll_cost,"reroll for",function()
   reroll_cost+=1
   deal_shop()
  end
 end
 if not item.hand and #jokers>=joker_slots then return nil,"joker slots full" end
 return item.cost,"buy for",function()
  take_choice(item)
  deli(shop_items,column-2)
 end
end

function shop_message()
 local cost,words=shop_offer()
 if not cost then return words end
 return money<cost and "not enough money" or "🅾️ "..words..(cost==0 and "" or " $"..abs(cost))
end

function update_shop()
 if leaving then return end
 local row,column=steer(shop_focus,{#jokers,2+#shop_items,#shop_packs})
 local cost,_,act=shop_offer()
 if btnp(4) and cost and money>=cost then
  money-=cost
  act()
  sfx(snd_pick)
  shop_focus.columns[row]=min(column,({#jokers,2+#shop_items,#shop_packs})[row])
 end
end

function draw_mini_planet(item,x,y,focused)
 x,y=glide(item,x,y)
 box(x,y,19,19,13,focused and 10 or 6)
 circfill(x+10,y+7,4,item.hand.level_chips%7+8)
 line(x+3,y+8,x+17,y+6,7)
 print_centre("lv"..hand_levels[item.hand.name]+1,y+13,7,x+10)
end

function draw_mini_tarot(tarot,x,y,focused)
 x,y=glide(tarot,x,y)
 box(x,y,19,19,2,focused and 10 or 14)
 print_centre("★",y+3,10,x+10)
 print_centre(sub(tarot.name,1,4),y+12,7,x+10)
end

function draw_booster(pack,x,y,focused)
 x,y=glide(pack,x,y)
 box(x,y,17,23,pack.colour,focused and 10 or 7)
 print_centre(sub(pack.label,1,4),y+6,1,x+9)
 print_centre("pack",y+13,1,x+9)
end

function draw_item(item,x,y,focused)
 if item.kind then draw_booster(item,x+1,y-1,focused)
 elseif item.hand then draw_mini_planet(item,x,y,focused)
 elseif item.act then draw_mini_tarot(item,x,y,focused)
 elseif item.rank then
  draw_card(item,x+2,y-(focused and 3 or 0))
  if focused then outline(item) end
 else draw_mini_joker(item,x,y,focused) end
end

function draw_pack()
 draw_swirl(pack_open.colour,1,0)
 draw_sidebar()
 local row,column=pack_focus.row,pack_focus.columns[pack_focus.row]
 draw_joker_row(row==1 and column)
 local total=#pack_choices
 for i,item in ipairs(pack_choices) do
  draw_item(item,table_centre-total*12+(i-1)*24+2,28,row==2 and column==i)
 end
 rectfill(48,51,120,64,0)
 print_centre(pack_open.label.." pack",53,7,table_centre)
 print_centre("choose 1",59,6,table_centre)
 rectfill(72,67,96,76,row==2 and column>total and 10 or 5)
 print_centre("skip",70,0,table_centre)
 for i,card in ipairs(pack_hand) do
  local hovered=row==3 and column==i
  draw_card(card,41+(i-1)*10,(card.picked and 94 or 101)-(hovered and 3 or 0))
 end
 local card=row==3 and pack_hand[column]
 if card then outline(card) end
 local tip=row==1 and jokers[column] or row==2 and pack_choices[column]
 if tip and not tip.rank then draw_tooltip(tip,row==1 and 25 or 78) end
 draw_particles()
end

function draw_shop()
 draw_swirl(3,1,0)
 draw_sidebar()
 draw_joker_row(shop_focus.row==1 and shop_focus.columns[1])
 slide(shop_panel)
 box(41,27,85,73,1,8)
 local focus=shop_focus.row==2 and shop_focus.columns[2]
 for i,label in ipairs{"next","roll"} do
  local y=31+(i-1)*17
  rectfill(44,y,64,y+13,i==1 and 8 or money<reroll_cost and 5 or 3)
  print_centre(label,y+2,7,55)
  print_centre(i==1 and "blind" or "$"..reroll_cost,y+8,i==1 and 7 or 10,55)
  if focus==i then rect(43,y-1,65,y+14,10) end
 end
 for row=2,3 do
  for i,item in ipairs(row==2 and shop_items or shop_packs) do
   local x,y,focused=72+(i-1)*26,row*33-36,shop_focus.row==row and shop_focus.columns[row]==i+6-row*2
   rectfill(x+3,y,x+16,y+6,0)
   print_centre("$"..item.cost,y+1,10,x+10)
   draw_item(item,x,y+9,focused)
  end
 end
 local tip=shop_focus.row==1 and jokers[shop_focus.columns[1]] or focus and focus>2 and shop_items[focus-2]
 if tip then draw_tooltip(tip,shop_focus.row==1 and 25 or 72) end
 camera()
 for i=0,min(#run_deck\13,3) do draw_back(deck_x-i,deck_y-i) end
 draw_particles()
 print_centre(shop_message(),118,7,74)
end
