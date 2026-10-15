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

function draw_card(card,x,y)
 if is_active(card) then y-=3 end
 card.x,card.y=x,y
 rectfill(x,y,x+14,y+20,7)
 rect(x,y,x+14,y+20,6)
 pset(x,y,0) pset(x+14,y,0) pset(x,y+20,0) pset(x+14,y+20,0)
 local colour=suit_colors[card.suit]
 print(rank_names[card.rank-1],x+2,y+2,colour)
 spr(16+card.suit,x+2,y+8)
 spr(card.suit,x+7,y+12)
end

function draw_joker(joker,x,y,focused)
 if is_active(joker) then y-=3 end
 joker.x,joker.y=x,y
 rectfill(x,y,x+30,y+19,7)
 rect(x,y,x+30,y+19,focused and 10 or 13)
 print(joker.name,x+2,y+2,2)
 print(joker.text,x+2,y+8,joker.chips and 12 or 8)
 print(joker.cond or "",x+2,y+14,5)
 if joker.cond=="per" then spr(16+joker.need,x+15,y+14) end
end

function draw_panel()
 rectfill(0,0,127,41,1)
 print(blind_specs[blind].name,2,2,7)
 print("goal "..big_text(goal),2,9,9)
 print_right("ante "..ante.."/"..#ante_bases,102,2,13)
 print("$"..money,2,17,10)
 print_right("score",126,2,6)
 print_right(big_text(shown_score),126,9,7)
 if hand_label then print_centre(hand_label,17,7) end
 rectfill(28,24,60,32,12)
 rectfill(68,24,100,32,8)
 print_right(tostr(chips),58,26,7)
 print("x",62,26,7)
 print(tostr(mult),70,26,7)
 print("hands "..hands_left,2,35,12)
 print("discards "..discards_left,40,35,8)
 print_right("deck "..#deck,126,35,6)
end

function draw_table()
 cls(3)
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
 for i,card in ipairs(hand) do
  local x,y=(i-1)*16,card.picked and 97 or 104
  draw_card(card,x,y)
  if mode=="play" and i==cursor then rect(x-1,y-1,x+15,y+21,10) end
 end
 for p in all(pops) do
  local y=p.y-p.age\4
  rectfill(p.x-#p.text*2-1,y-1,p.x+#p.text*2-1,y+5,0)
  print(p.text,p.x-#p.text*2,y,p.colour)
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
 cls(1)
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
 draw_table()
 if mode=="cashout" then draw_banner("blind defeated!","🅾️ cash out $"..earned,11,earnings)
 elseif mode=="won" then draw_banner("you beat ante "..ante.."!","🅾️ play again",10,{})
 elseif mode=="lost" then draw_banner("game over","🅾️ try again",8,{}) end
end
