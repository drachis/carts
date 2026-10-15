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
  if thing.wait==0 then sfx(snd_deal) end
 else
  thing.glide_x+=(x-thing.glide_x)/4
  thing.glide_y+=(y-thing.glide_y)/4
 end
 local dx,dy=jiggle(thing)
 thing.x,thing.y=flr(thing.glide_x+dx+.5),flr(thing.glide_y+dy+.5)
 return thing.x,thing.y
end

function draw_back(x,y)
 rectfill(x,y,x+14,y+20,8)
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
 if is_debuffed(card) then
  fillp(░)
  rectfill(x+1,y+1,x+13,y+19,5)
  fillp()
  line(x+2,y+18,x+12,y+2,8)
 end
 clip()
end

function draw_joker(joker,x,y,focused)
 if is_active(joker) then y-=3 end
 x,y=glide(joker,x,y)
 rectfill(x,y,x+30,y+19,7)
 rect(x,y,x+30,y+19,focused and 10 or 13)
 print(joker.name,x+2,y+2,2)
 print(joker.text,x+2,y+8,joker.chips and 12 or 8)
 print(joker.cond or "",x+2,y+14,5)
 if joker.cond=="per" then spr(16+joker.need,x+15,y+14) end
end

function draw_mini_joker(joker,x,y,focused)
 if is_active(joker) then y-=3 end
 x,y=glide(joker,x,y)
 rectfill(x,y,x+19,y+19,7)
 rect(x,y,x+19,y+19,focused and 10 or 13)
 local effect=joker.xmult and "x"..joker.xmult or "+"..(joker.chips or joker.mult)
 print_centre(effect,y+3,joker.chips and 12 or 8,x+10)
 if joker.cond=="per" then spr(16+joker.need,x+8,y+11) else print_centre(joker.tag or "",y+11,5,x+10) end
end

function draw_tooltip(joker)
 local x=mid(40,joker.x-20,66)
 rectfill(x,25,x+60,44,7)
 rect(x,25,x+60,44,0)
 print(joker.name,x+3,27,2)
 print(joker.text,x+3,33,joker.chips and 12 or 8)
 print(joker.cond or "",x+3,39,5)
 if joker.cond=="per" then spr(16+joker.need,x+17,39) end
 print_right("sell $"..sell_price(joker),x+59,39,5)
end

function sidebar_box(x0,y0,x1,y1,heading,value,colour)
 rectfill(x0,y0,x1,y1,0)
 print_centre(heading,y0+1,6,(x0+x1+1)/2)
 print_centre(value,y0+7,colour,(x0+x1+1)/2)
end

function draw_sidebar()
 rectfill(-8,-8,38,135,1)
 line(39,-8,39,135,0)
 rectfill(1,1,37,13,boss_on() and 8 or blind==2 and 9 or 12)
 local words=split(blind_name(blind)," ")
 print_centre(words[1],2,7,19)
 print_centre(words[2],8,7,19)
 sidebar_box(2,15,36,27,"goal",big_text(goal),8)
 sidebar_box(2,29,36,41,"round",big_text(shown_score),7)
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
 sidebar_box(2,67,18,80,"hand",tostr(hands_left),12)
 sidebar_box(20,67,36,80,"disc",tostr(discards_left),8)
 rectfill(2,83,36,94,0)
 local cash="$"..money
 print("\^w"..cash,20-#cash*4,86,10)
 sidebar_box(2,97,18,110,"ante",ante.."/"..#ante_bases,9)
 sidebar_box(20,97,36,110,"rnd",tostr((ante-1)*3+blind),9)
 print_centre("deck "..#deck,114,6,19)
 if #jokers>0 then print_centre(joker_focus and "⬇️hand" or "⬆️joker",121,5,21) end
end

function draw_table_button(text,x0,x1,colour,enabled)
 rectfill(x0,104,x1,113,enabled and colour or 5)
 print_centre(text,107,enabled and 7 or 6,(x0+x1+1)/2)
end

function draw_table()
 draw_swirl(3,1,0)
 draw_sidebar()
 for i=1,joker_slots do
  local x,joker=42+(i-1)*21,jokers[i]
  if joker then draw_mini_joker(joker,x,3,joker_focus==i) else rect(x,3,x+19,22,11) end
 end
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
  draw_card(card,41+(i-1)*10,(card.picked and 71 or 78)+arc)
 end
 local card=hand[cursor]
 if mode=="play" and not joker_focus and card and card.wait==0 then rect(card.x-1,card.y-1,card.x+15,card.y+21,10) end
 local picked=picked_cards()
 draw_table_button("❎play",42,74,12,mode=="play" and #picked>0 and can_play(picked))
 draw_table_button("⬇️disc",77,107,8,mode=="play" and #picked>0 and discards_left>0)
 if #picked==0 then print_centre("⬇️ sort by "..(sort_by_suit and "rank" or "suit"),118,6,74) end
 if joker_focus then draw_tooltip(jokers[joker_focus]) end
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
 print("🅾️ pick card",34,68,7)
 print("❎ play hand",34,76,7)
 print("⬇️ discard, or sort",34,84,7)
 print("⬆️ look at jokers",34,92,7)
 print_centre("press 🅾️ to start",112,10)
end

function _draw()
 if mode=="title" then draw_title() return end
 if mode=="shop" then draw_shop() return end
 shake_camera()
 draw_table()
 camera()
 if mode=="cashout" then draw_banner("blind defeated!","🅾️ cash out $"..earned,11,earnings)
 elseif mode=="won" then draw_banner("you beat ante "..ante.."!","🅾️ play again",10,{})
 elseif mode=="lost" then draw_banner("game over","🅾️ try again",8,{}) end
end
