function update_intro()
 intro_t+=1
 while intro_spawns[#intro_cards+1]==intro_t do
  local i=#intro_cards+1
  add(intro_cards,{i=i,born=intro_t,angle=rnd(),size=(2-i/300)*(rnd()+1),life=max(2-i*.005,.001)*60})
 end
 if intro_t==120 then emit("dissolve",64,64) end
 if btnp(4) or intro_t>=intro_end then mode,intro_t="title",intro_end end
end

function draw_intro()
 draw_swirl(0,intro_t>240 and 12 or intro_t>120 and 1 or 0,0)
 if intro_t>20 and intro_t<120 then draw_joker_card(55,52,1.2) end
 for card in all(intro_cards) do
  local left=(intro_t-card.born)/card.life
  local distance,width=(1-min(left/.9,1))*(18+card.size)*6.4,card.size*15*max(1-left,0)
  local edge=max(1-distance/150,0)
  local turn=card.angle+(.08+intro_t/2513)*edge*edge*(3-2*edge)
  local x,y=64+distance*sin(turn)-width/2,64+distance*cos(turn)-width*.7
  if card.i%5<1 then
   box(x,y,width,width*1.4,8,7)
  else
   sspr(0,32,15,21,x,y,width,width*1.4)
   sspr(card.i%4*8+8,0,8,8,x+width/4,y+width*.45,width/2,width/2)
  end
 end
 local bloom=max(intro_t-600,0)/156
 if intro_t>180 then circfill(64,64,4+bloom*bloom*92,7) end
 draw_particles()
end
