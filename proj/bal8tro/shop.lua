function deal_shop()
 shop_items=deal_jokers(shop_slots,jokers)
 for i=1,#shop_items do
  if rnd()<planet_chance then
   local hand=rnd(hand_specs)
   shop_items[i]={hand=hand,name=hand.planet,cost=planet_cost}
  end
 end
end

function open_shop()
 deal_shop()
 reroll_cost=reroll_base
 shop_row,shop_column=2,1
 mode="shop"
end

function sell_price(joker)
 return max(1,joker.cost\2)
end

function shop_row_size(row)
 return row==1 and #jokers or row==2 and #shop_items or 2
end

function move_shop_row(step)
 local row=shop_row+step
 while row>=1 and row<=3 do
  if shop_row_size(row)>0 then
   shop_row=row
   return
  end
  row+=step
 end
end

function shop_message()
 local column=shop_column
 if shop_row==1 then return "🅾️ sell for $"..sell_price(jokers[column]) end
 if shop_row==2 then
  local item=shop_items[column]
  if not item.hand and #jokers>=joker_slots then return "joker slots full" end
  if money<item.cost then return "not enough money" end
  return "🅾️ buy for $"..item.cost
 end
 if column==1 then return money<reroll_cost and "not enough money" or "🅾️ reroll for $"..reroll_cost end
 return "🅾️ go to the next blind"
end

function update_shop()
 if btnp(2) then move_shop_row(-1) end
 if btnp(3) then move_shop_row(1) end
 if btnp(0) then shop_column-=1 end
 if btnp(1) then shop_column+=1 end
 shop_column=mid(1,shop_column,shop_row_size(shop_row))
 if not btnp(4) then return end
 local column=shop_column
 if shop_row==1 then
  money+=sell_price(jokers[column])
  deli(jokers,column)
 elseif shop_row==2 then
  local item=shop_items[column]
  if money>=item.cost then
   if item.hand then
    money-=item.cost
    hand_levels[item.hand.name]+=1
    deli(shop_items,column)
   elseif #jokers<joker_slots then
    money-=item.cost
    add(jokers,deli(shop_items,column))
   end
  end
 elseif column==1 then
  if money>=reroll_cost then
   money-=reroll_cost
   reroll_cost+=1
   deal_shop()
  end
 else
  ante,blind=next_blind()
  start_blind()
  return
 end
 sfx(snd_pick)
 if shop_row_size(shop_row)==0 then move_shop_row(1) end
 shop_column=mid(1,shop_column,shop_row_size(shop_row))
end

function draw_planet(item,x,y,focused)
 local hand=item.hand
 rectfill(x,y,x+30,y+19,13)
 rect(x,y,x+30,y+19,focused and 10 or 6)
 print(item.name,x+2,y+2,7)
 print(hand.short,x+2,y+8,10)
 print("lv"..hand_levels[hand.name].."+1",x+2,y+14,7)
end

function draw_button(text,x,colour,focused)
 rectfill(x,88,x+52,98,colour)
 print(text,x+27-#text*2,91,7)
 if focused then rect(x-1,87,x+53,99,10) end
end

function draw_shop()
 cls(1)
 print("shop",2,2,7)
 print_right("$"..money,126,2,10)
 print("jokers "..#jokers.."/"..joker_slots,2,12,6)
 for i,joker in ipairs(jokers) do
  draw_joker(joker,1+(i-1)*32,19,shop_row==1 and i==shop_column)
 end
 print("for sale",2,44,6)
 for i,item in ipairs(shop_items) do
  local x,focused=64-#shop_items*16+(i-1)*32,shop_row==2 and i==shop_column
  if item.hand then draw_planet(item,x,51,focused) else draw_joker(item,x,51,focused) end
  print("$"..item.cost,x+12,73,10)
 end
 draw_button("reroll $"..reroll_cost,8,3,shop_row==3 and shop_column==1)
 draw_button("next blind",68,8,shop_row==3 and shop_column==2)
 local next_ante,next=next_blind()
 print_centre("next: ante "..next_ante.." "..blind_specs[next].name,100,6)
 print_centre("goal "..big_text(blind_goal(next_ante,next)),108,9)
 print_centre(shop_message(),116,7)
end
