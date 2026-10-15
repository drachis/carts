function thing_position(thing)
 if thing.rank then return thing.x+7,thing.y-7 end
 return thing.x+10,thing.y+22
end

function print_right(text,x,y,colour)
 print(text,x-#text*4,y,colour)
end

function print_centre(text,y,colour,centre)
 print(text,(centre or 64)-print(text,0,-99)/2,y,colour)
end

function is_active(thing)
 return active_step and (active_step.thing==thing or active_step.under==thing)
end

function glide(thing,x,y)
 if not thing.glide_x then thing.glide_x,thing.glide_y,thing.wait=x,y,0 end
 if thing.wait>0 then
  thing.wait-=1
  if thing.wait==0 then
   sfx(snd_deal)
   turn_over(thing)
  end
 else
  thing.glide_x+=(x-thing.glide_x)/4
  thing.glide_y+=(y-thing.glide_y)/4
 end
 local dx,dy=jiggle(thing)
 thing.x,thing.y=flr(thing.glide_x+dx+.5),flr(thing.glide_y+dy+.5)
 return thing.x,thing.y
end

function draw_back(x,y)
 rectfill(x,y,x+14,y+20,deck_spec.colour)
 fillp(░)
 rectfill(x+2,y+2,x+12,y+18,0x82)
 fillp()
 rect(x,y,x+14,y+20,7)
end

function draw_card(card,x,y)
 if is_active(card) then y-=3 end
 x,y=glide(card,x,y)
 local turn=card.flip or 1
 if turn<1 then
  card.flip+=.0625
  local width=abs(cos(turn/2))*7.5
  clip(x+7.5-width,y,width*2+1,21)
 end
 if card.wait>0 or turn<.5 then
  draw_back(x,y)
  clip()
  return
 end
 rectfill(x,y,x+14,y+20,7)
 rect(x,y,x+14,y+20,6)
 pset(x,y,0) pset(x+14,y,0) pset(x,y+20,0) pset(x+14,y+20,0)
 local colour=suit_colors[card.suit]
 print(rank_names[card.rank-1],x+2,y+2,colour)
 spr(16+card.suit,x+2,y+8)
 spr(card.suit,x+7,y+12)
 local boost=enhancement_specs[card.enhancement]
 if boost then
  rect(x,y,x+14,y+20,boost.colour)
  print(sub(boost.name,1,1),x+11,y+2,boost.colour)
 end
 if is_debuffed(card) then
  fillp(░)
  rectfill(x+1,y+1,x+13,y+19,5)
  fillp()
  line(x+2,y+18,x+12,y+2,8)
 end
 clip()
end

function draw_mini_joker(joker,x,y,focused)
 if is_active(joker) then y-=3 end
 x,y=glide(joker,x,y)
 rectfill(x,y,x+19,y+19,7)
 rect(x,y,x+19,y+19,focused and 10 or 13)
 local effect=joker.xmult and "x"..joker.xmult or "+"..(joker.chips or joker.mult)*joker_scale(joker,nil,jokers)
 spr(joker.sprite,x+6,y+2)
 print_centre(effect,y+12,joker.chips and 12 or 8,x+10)
end

function draw_tooltip(thing,y)
 local x,hand=mid(40,thing.x-20,66),thing.hand
 rectfill(x,y,x+60,y+19,7)
 rect(x,y,x+60,y+19,0)
 print(thing.name,x+3,y+2,2)
 if hand then
  print(hand.label,x+3,y+8,12)
  print("lvl "..hand_levels[hand.name].." > "..hand_levels[hand.name]+1,x+3,y+14,5)
  return
 end
 print(thing.text,x+3,y+8,thing.chips and 12 or 8)
 print(thing.cond or "",x+3,y+14,5)
 if thing.cond=="per" then spr(16+thing.need,x+17,y+14) end
 if count(jokers,thing)>0 then print_right("sell $"..sell_price(thing),x+59,y+14,5) end
end

function draw_joker_row(focused)
 for i=1,joker_slots do
  local x,joker=42+(i-1)*21,jokers[i]
  if joker then draw_mini_joker(joker,x,3,focused==i) else rect(x,3,x+19,22,11) end
 end
end

function sidebar_box(box)
 local value,centre=_ENV[box.name],(box.left+box.right+1)/2
 rectfill(box.left,box.top,box.right,box.top+12,0)
 print_centre(box.heading,box.top+1,6,centre)
 print_centre(box.big and big_text(value) or tostr(value),box.top+7,box.colour,centre)
end

function draw_sidebar()
 rectfill(-8,-8,38,135,1)
 line(39,-8,39,135,heat>=2 and rnd(split"8,9,10") or 0)
 local in_shop=mode=="shop" or mode=="pack"
 rectfill(1,1,37,13,in_shop and 10 or boss_on() and 8 or blind==2 and 9 or 12)
 local words=split(in_shop and "the shop" or blind_name(blind)," ")
 print_centre(words[1],2,in_shop and 8 or 7,19)
 print_centre(words[2],8,in_shop and 8 or 7,19)
 for box in all(sidebar_boxes) do sidebar_box(box) end
 draw_flames()
 rectfill(chips_x-chips_bump,boxes_y-chips_bump,chips_x+16+chips_bump,boxes_y+8+chips_bump,12)
 rectfill(mult_x-mult_bump,boxes_y-mult_bump,mult_x+16+mult_bump,boxes_y+8+mult_bump,8)
 print_centre(tostr(chips),boxes_y+2,7,chips_x+9)
 print_centre(tostr(mult),boxes_y+2,7,mult_x+9)
 if hand_label then
  for line in all{{hand_label,44,7,19},{"lvl "..hand_level,50,6,19}} do
   print_centre(line[1],line[2]+1,0,19)
   print_centre(unpack(line))
  end
 end
 rectfill(2,83,36,94,0)
 local cash="$"..money
 print("\^w"..cash,20-#cash*4,86,10)
 print_centre("deck "..#deck,114,6,19)
 if #jokers>0 then print_centre(joker_focus and "⬇️hand" or "⬆️joker",121,5,21) end
end

function draw_table_button(button,enabled,focused)
 local dx,dy=jiggle(button)
 local x,y=button.left+dx,104+dy-(focused and 1 or 0)
 rectfill(x,y,x+20,y+9,enabled and button.colour or 5)
 print_centre(button.label,y+3,enabled and 7 or 6,x+11)
 if focused then rect(x-1,y-1,x+21,y+10,10) end
end

function draw_table()
 draw_swirl(3,1,0)
 draw_sidebar()
 draw_joker_row(joker_focus)
 if played then
  local left=table_centre-#played*8
  for i,card in ipairs(played) do
   local scores=count(scoring_cards,card)>0
   draw_card(card,left+(i-1)*16,scores and 44 or 48)
  end
 elseif boss_on() and not joker_focus then
  print_centre(boss.text,31,0,table_centre)
  print_centre(boss.text,30,8,table_centre)
 end
 for i=0,min(#deck\13,3) do draw_back(deck_x-i,deck_y-i) end
 for card in all(flying) do
  draw_card(card,150,60)
  if card.x>127 then del(flying,card) end
 end
 for i,card in ipairs(hand) do
  local arc=(i-4.5)*(i-4.5)\6+sin(t()/3+i/8)*.8
  local hovered=mode=="play" and table_focus.row==2 and i==cursor
  draw_card(card,41+(i-1)*10,(card.picked and 71 or 78)+arc-(hovered and 3 or 0))
 end
 local card=hand[cursor]
 if mode=="play" and table_focus.row==2 and card and card.wait==0 then rect(card.x-1,card.y-1,card.x+15,card.y+21,10) end
 local picked=picked_cards()
 for i,button in ipairs(table_buttons) do
  draw_table_button(button,mode=="play" and button_ready(button.name,picked),button_focus==i)
 end
 local hints=split"⬇️ back to hand,🅾️pick ❎play,🅾️ press"
 if mode=="play" then print_centre(hints[table_focus.row],118,6,74) end
 if joker_focus then draw_tooltip(jokers[joker_focus],25) end
 draw_floor_fire()
 draw_particles()
 for p in all(pops) do
  local y,half,tall=p.y-p.age\4,#p.text*2,5
  if p.big then
   half,tall,y=#p.text*4,10,p.y
   rectfill(p.x-half-2,y-2,p.x+half,y+tall+1,0)
   print("\^w\^t"..p.text,p.x-half,y,p.age%8<4 and 10 or 7)
  else
   rectfill(p.x-half-1,y-1,p.x+half-1,y+tall,0)
   print(p.text,p.x-half,y,p.colour)
  end
 end
end

function draw_banner(title,line,colour,lines)
 local bottom=70+#lines*8
 rectfill(42,40,125,bottom,0)
 rect(42,40,125,bottom,colour)
 print_centre(title,46,colour,table_centre)
 for i,entry in ipairs(lines) do
  print(entry[1],46,50+i*8,7)
  print_right("$"..entry[2],122,50+i*8,10)
 end
 print_centre(line,bottom-10,7,table_centre)
end

function draw_title()
 draw_swirl(1,2,0)
 print("\^w\^tbal8tro",36,14,10)
 for i=1,5 do
  draw_card({rank=9+i,suit=i%4+1},24+(i-1)*16,36)
 end
 print("🅾️ pick, press   ❎ play\n⬆️⬇️ rows   ⬅️➡️ along",14,62,6)
 draw_back(16,78)
 print_centre("⬅️ "..deck_spec.name.." deck ➡️",82,7,68)
 print_centre(deck_spec.text,90,9,68)
 print_centre("press 🅾️ to start",112,10)
end

function _draw()
 if mode=="title" then draw_title() return end
 if mode=="shop" then draw_shop() return end
 if mode=="pack" then draw_pack_screen() return end
 shake_camera()
 draw_table()
 camera()
 if mode=="cashout" then draw_banner("blind defeated!","🅾️ cash out $"..earned,11,earnings)
 elseif mode=="won" then draw_banner("you beat ante "..ante.."!","🅾️ play again",10,{})
 elseif mode=="lost" then draw_banner("game over","🅾️ try again",8,{}) end
end
