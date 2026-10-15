function _init()
 mode,deck_choice,deck_spec="title",1,deck_specs[1]
 shown_score=0
 poke(0x5f5c,8)
 poke(0x5f5d,2)
end

function start_run()
 ante,blind=1,1
 deck_spec=deck_specs[deck_choice]
 money=start_money+deck_spec.money
 jokers,run_deck,hands_left,discards_left,score,chips,mult={},new_deck(deck_spec),0,0,0,0,0
 deck=run_deck
 reset_levels()
 open_select()
end

function open_select()
 if blind==1 then boss=rnd(boss_specs) end
 goal=blind_goal(ante,blind)
 ante_label,round_number=ante.."/"..#ante_bases,(ante-1)*3+blind
 if skip_select then return start_blind() end
 mode,leaving,select_focus,select_panel="select",false,{row=2,columns={1,1}},{glide_x=0,glide_y=110,wait=0}
end

function update_select()
 local row=steer(select_focus,{#jokers,1})
 joker_focus=row==1 and select_focus.columns[1]
 if btnp(4) and row==2 and not leaving then
  leaving=true
  sfx(snd_pick)
  after(select_wait,start_blind)
 end
end

function start_blind()
 deck=shuffled(run_deck)
 hand,flying={},{}
 played,hand_label,chips,mult=nil,nil,0,0
 pops,mode={},"play"
 local active=boss_on()
 hands_left=active and active.hands or hands_per_blind+deck_spec.hands
 discards_left=active and active.discards or discards_per_blind+deck_spec.discards
 score,shown_score=0,0
 cursor,joker_focus,button_focus,leaving=1
 table_focus={row=2,columns={1,1,1}}
 sort_by_suit=false
 draw_up()
end

function draw_up()
 local dealt=0
 while #hand<hand_size and #deck>0 do
  local card=add(hand,deli(deck))
  card.glide_x,card.glide_y,card.wait=deck_x,deck_y,1+dealt*deal_frames
  dealt+=1
 end
 sort_cards(hand,sort_by_suit)
end

function picked_cards()
 local picked={}
 for card in all(hand) do
  if card.picked then add(picked,card) end
 end
 return picked
end

function take_picked()
 local picked=picked_cards()
 for card in all(picked) do
  del(hand,card)
  card.picked=false
 end
 table_focus.columns[2]=mid(1,cursor,#hand)
 return picked
end

function fly_away(cards)
 for i,card in ipairs(cards) do
  card.hold=(i-1)*play_stagger
  add(flying,card)
 end
end

function play_hand()
 hands_left-=1
 played=take_picked()
 for i,card in ipairs(played) do card.hold=play_delay+(i-1)*play_stagger end
 local played_spec,played_scoring=evaluate(played)
 hand_plays[played_spec.name]+=1
 grow_jokers("play",played_scoring)
 local spec,label
 spec,label,scoring_cards,steps=score_steps(played,jokers)
 hand_label,hand_level=hand_title(spec,label)
 chips,mult=hand_base(spec)
 step_index,step_timer,active_step=0,score_delay
 mode="score"
end

function discard_hand()
 discards_left-=1
 grow_jokers("discard")
 fly_away(take_picked())
 draw_up()
end

function steer(focus,sizes)
 local row,moved=focus.row
 for step=-1,1,2 do
  if btnp(step<0 and 2 or 3) then
   local next=row+step
   while sizes[next]==0 do next+=step end
   if sizes[next] then row,moved=next,true end
  end
 end
 local size,column=sizes[row],focus.columns[row] or 1
 if btnp(0) or btnp(1) then column+=btnp(0) and -1 or 1 moved=true end
 column=size>0 and (column-1)%size+1 or 1
 focus.row,focus.columns[row]=row,column
 if moved then sfx(snd_move) end
 return row,column
end

function button_ready(name,picked)
 if name=="play" then return #picked>0 and can_play(picked) end
 if name=="discard" then return #picked>0 and discards_left>0 end
 return true
end

function update_play()
 local row,column=steer(table_focus,{#jokers,#hand,#table_buttons})
 cursor,joker_focus,button_focus=table_focus.columns[2],row==1 and column,row==3 and column
 local card=hand[cursor]
 if btnp(4) and row==2 and card then
  if card.picked or #picked_cards()<max_picked then
   card.picked=not card.picked
   kick(card,1.5)
   sfx(snd_pick)
  end
 end
 local picked=picked_cards()
 hand_label,chips,mult=nil,0,0
 if #picked>0 then
  local spec,_,_,label=evaluate(picked)
  hand_label,hand_level=hand_title(spec,label)
  chips,mult=hand_base(spec)
 end
 local button=btnp(5) and table_buttons.play or btnp(4) and row==3 and table_buttons[column]
 if button and button_ready(button.name,picked) then
  kick(button,3)
  sfx(snd_pick)
  if button.name=="play" then play_hand()
  elseif button.name=="discard" then discard_hand()
  elseif button.name=="info" then mode,info_tab="info",1
  else
   sort_by_suit=not sort_by_suit
   sort_cards(hand,sort_by_suit)
  end
 end
end

function update_score()
 step_timer-=1
 if step_timer>0 then return end
 step_index+=1
 local step=steps[step_index]
 if step then
  chips,mult=apply_step(step,chips,mult)
  active_step=step
  local x,y=thing_position(step.thing)
  local colour=step.chips and 12 or 8
  pop(step.xmult and "x"..step.xmult or "+"..(step.chips or step.mult),x,y,colour)
  emit("spark",x,y+4,colour)
  kick(step.thing,step.under and 3 or 2)
  if step.under then kick(step.under,1.5) end
  if step.chips then chips_bump=2 else mult_bump=2 end
  sfx((step.chips and snd_chips or snd_mult)+min(step_index-1,7))
  local next=steps[step_index+1]
  step_timer=not next and total_gap or next.thing.rank and step_frames or joker_frames
 elseif step_index==#steps+1 then
  active_step=nil
  local total=hand_total(chips,mult)
  after(score_wait,function()
   score+=total
   roll=total/score_roll
  end)
  chips,mult=0,0
  add(pops,{text=big_text(total),x=table_centre,y=50,colour=10,age=0,big=true})
  emit("shower",chips_x,boxes_y)
  emit("shower",mult_x,boxes_y)
  hitstop(min(4+total/goal*4,12))
  if score+total>=goal then flash(3) end
  shake=min(2+total/goal*4,8)
  sfx(snd_total)
  step_timer=total_hold
 else
  finish_hand()
 end
end

function finish_hand()
 for card in all(played) do
  if card.enhancement=="glass" and rnd(4)<1 then
   del(run_deck,card)
   emit("shower",card.x,card.y)
  end
 end
 fly_away(played)
 played,hand_label,chips,mult=nil,nil,0,0
 draw_up()
 if score>=goal then
  if next_blind()>#ante_bases then mode="won" else cash_out() end
 elseif hands_left==0 then
  mode="lost"
 else
  mode="play"
 end
 banner={glide_x=0,glide_y=110,wait=0}
end

function cash_out()
 earnings={
  {blind_name(blind),blind_specs[blind].reward},
  {"hands left",hands_left},
  {"interest",min(money\interest_step,interest_cap)},
  {"gold cards",0}
 }
 for card in all(hand) do
  if card.enhancement=="gold" then earnings[4][2]+=3 end
 end
 earned=0
 for line in all(earnings) do earned+=line[2] end
 money+=earned
 emit("coin",15,86)
 mode="cashout"
end

function play_music(pattern)
 if pattern!=playing_music then music(pattern,500,7) end
 playing_music=pattern
end

function pop(text,x,y,colour)
 add(pops,{text=text,x=x,y=y,colour=colour,age=0})
end

function update_title()
 if btnp(0) or btnp(1) then
  deck_choice=(deck_choice+(btnp(1) and 0 or #deck_specs-2))%#deck_specs+1
  deck_spec=deck_specs[deck_choice]
  sfx(snd_move)
 end
 update_lost()
end

function update_info()
 if btnp(0) or btnp(1) then
  info_tab=3-info_tab
  sfx(snd_move)
 end
 if btnp(4) or btnp(5) or btnp(3) then mode="play" end
end

function update_cashout()
 if btnp(4) and not leaving then
  leaving=true
  after(shop_wait,open_shop)
 end
end

function update_lost()
 if btnp(4) then start_run() end
end
update_won=update_lost

function _update60()
 if freeze>0 then
  freeze-=1
  return
 end
 _ENV["update_"..mode]()
 shown_score=min(score or 0,shown_score+max(roll or 0,0x.0001))
 for p in all(pops) do
  p.age+=1
  if p.age>40 then del(pops,p) end
 end
 update_effects()
 play_music((mode=="title" or mode=="shop" or mode=="pack") and music_calm or music_table)
end
