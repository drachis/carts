function thing_position(thing)
 if thing.rank then return thing.x+7,thing.y-7 end
 return thing.x+15,thing.y+22
end

function print_right(text,x,y,colour)
 print(text,x-#text*4,y,colour)
end

function print_centre(text,y,colour)
 print(text,64-#text*2,y,colour)
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
 thing.x,thing.y=flr(thing.glide_x+.5),flr(thing.glide_y+.5)
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
 if card.wait>0 then draw_back(x,y) return end
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

function draw_panel()
 rectfill(-8,-8,135,41,1)
 print(blind_name(blind),2,2,boss_on() and 8 or 7)
 print("goal "..big_text(goal),2,9,9)
 print_right("ante "..ante.."/"..#ante_bases,102,2,13)
 print("$"..money,2,17,10)
 print_right("score",126,2,6)
 print_right(big_text(shown_score),126,9,7)
 draw_flames()
 rectfill(28-chips_bump,24-chips_bump,60+chips_bump,32+chips_bump,12)
 rectfill(68-mult_bump,24-mult_bump,100+mult_bump,32+mult_bump,8)
 print_right(tostr(chips),58,26,7)
 print("x",62,26,7)
 print(tostr(mult),70,26,7)
 if hand_label then
  print_centre(hand_label,18,0)
  print_centre(hand_label,17,7)
 elseif boss_on() then
  print_centre(boss.text,17,8)
 end
 print("hands "..hands_left,2,35,12)
 print("discards "..discards_left,40,35,8)
 print_right("deck "..#deck,126,35,6)
end

function draw_table()
 draw_swirl(3,1,42)
 draw_panel()
 for i=1,joker_slots do
  local x,joker=1+(i-1)*32,jokers[i]
  if joker then draw_joker(joker,x,44) else rect(x,44,x+30,63,11) end
 end
 if played then
  local left=64-#played*8
  for i,card in ipairs(played) do
   local scores=count(scoring_cards,card)>0
   draw_card(card,left+(i-1)*16,scores and 68 or 72)
  end
 end
 for i=0,min(#deck\13,3) do draw_back(deck_x-i,deck_y-i) end
 for card in all(flying) do
  draw_card(card,150,80)
  if card.x>127 then del(flying,card) end
 end
 for i,card in ipairs(hand) do
  local arc=(i-4.5)*(i-4.5)\4+sin(t()/3+i/8)*.8
  draw_card(card,(i-1)*16,(card.picked and 96 or 103)+arc)
  if mode=="play" and i==cursor and card.wait==0 then rect(card.x-1,card.y-1,card.x+15,card.y+21,10) end
 end
 draw_sparks()
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
 local bottom=82+#lines*8
 rectfill(14,52,113,bottom,0)
 rect(14,52,113,bottom,colour)
 print_centre(title,58,colour)
 for i,entry in ipairs(lines) do
  print(entry[1],20,62+i*8,7)
  print_right("$"..entry[2],108,62+i*8,10)
 end
 print_centre(line,bottom-10,7)
end

function draw_title()
 draw_swirl(1,2,0)
 print("\^w\^tbal8tro",36,14,10)
 for i=1,5 do
  draw_card({rank=9+i,suit=i%4+1},24+(i-1)*16,36)
 end
 print("🅾️ pick card",34,68,7)
 print("❎ play hand",34,76,7)
 print("⬇️ discard",34,84,7)
 print("⬆️ sort rank/suit",34,92,7)
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
