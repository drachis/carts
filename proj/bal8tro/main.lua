function _init()
 mode="title"
 shown_score=0
end

function start_run()
 ante,blind=1,1
 money=start_money
 jokers={}
 reset_levels()
 start_blind()
end

function start_blind()
 deck=new_deck()
 hand,flying={},{}
 played,hand_label,chips,mult=nil,nil,0,0
 pops={}
 if blind==1 then boss=rnd(boss_specs) end
 local active=boss_on()
 hands_left=active and active.hands or hands_per_blind
 discards_left=active and active.discards or discards_per_blind
 score,shown_score=0,0
 goal=blind_goal(ante,blind)
 ante_label,round_number=ante.."/"..#ante_bases,(ante-1)*3+blind
 cursor,joker_focus=1
 sort_by_suit=false
 draw_up()
 mode="play"
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
 cursor=mid(1,cursor,#hand)
 return picked
end

function fly_away(cards)
 for card in all(cards) do add(flying,card) end
end

function play_hand()
 hands_left-=1
 played=take_picked()
 local played_spec,played_scoring=evaluate(played)
 hand_plays[played_spec.name]+=1
 grow_jokers("play",played_scoring)
 local spec,label
 spec,label,scoring_cards,steps=score_steps(played,jokers)
 hand_label,hand_level=hand_title(spec,label)
 chips,mult=hand_base(spec)
 step_index,step_timer,active_step=0,30
 mode="score"
end

function discard_hand()
 discards_left-=1
 grow_jokers("discard")
 fly_away(take_picked())
 draw_up()
end

function update_play()
 if joker_focus then
  if btnp(0) then joker_focus=max(joker_focus-1,1) end
  if btnp(1) then joker_focus=min(joker_focus+1,#jokers) end
  if btnp(3) or #jokers==0 then joker_focus=nil end
  return
 end
 if btnp(0) then cursor=max(cursor-1,1) end
 if btnp(1) then cursor=min(cursor+1,#hand) end
 if btnp(2) and #jokers>0 then joker_focus=1 end
 local card=hand[cursor]
 if btnp(4) and card then
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
  if btnp(5) and can_play(picked) then play_hand()
  elseif btnp(3) and discards_left>0 then discard_hand() end
 elseif btnp(3) then
  sort_by_suit=not sort_by_suit
  sort_cards(hand,sort_by_suit)
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
  step_timer=step_frames
 elseif step_index==#steps+1 then
  active_step=nil
  local total=hand_total(chips,mult)
  score+=total
  add(pops,{text=big_text(total),x=table_centre,y=50,colour=10,age=0,big=true})
  emit("shower",chips_x,boxes_y)
  emit("shower",mult_x,boxes_y)
  hitstop(min(4+total/goal*4,12))
  if score>=goal then flash(3) end
  shake=min(2+total/goal*4,8)
  sfx(snd_total)
  step_timer=45
 else
  finish_hand()
 end
end

function finish_hand()
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
end

function cash_out()
 earnings={
  {blind_name(blind),blind_specs[blind].reward},
  {"hands left",hands_left},
  {"interest",min(money\interest_step,interest_cap)}
 }
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

function _update60()
 if freeze>0 then
  freeze-=1
  return
 end
 if mode=="title" then
  if btnp(4) then start_run() end
 elseif mode=="play" then
  update_play()
 elseif mode=="score" then
  update_score()
 elseif mode=="shop" then
  update_shop()
 elseif btnp(4) then
  if mode=="cashout" then
   open_shop()
  else
   start_run()
  end
 end
 shown_score=min(score or 0,shown_score+max(((score or 0)-shown_score)>>3,0x.0001))
 for p in all(pops) do
  p.age+=1
  if p.age>40 then del(pops,p) end
 end
 update_effects()
 play_music((mode=="title" or mode=="shop") and music_calm or music_table)
end
