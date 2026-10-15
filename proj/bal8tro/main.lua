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
 hands_left,discards_left=hands_per_blind,discards_per_blind
 score,shown_score=0,0
 goal=blind_goal(ante,blind)
 cursor=1
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
 local spec,label
 spec,label,scoring_cards,steps=score_steps(played,jokers)
 hand_label=hand_title(spec,label)
 chips,mult=hand_base(spec)
 step_index,step_timer,active_step=0,30
 mode="score"
end

function discard_hand()
 discards_left-=1
 fly_away(take_picked())
 draw_up()
end

function update_play()
 if btnp(0) then cursor=max(cursor-1,1) end
 if btnp(1) then cursor=min(cursor+1,#hand) end
 local card=hand[cursor]
 if btnp(4) and card then
  if card.picked or #picked_cards()<max_picked then
   card.picked=not card.picked
   sfx(snd_pick)
  end
 end
 if btnp(2) then
  sort_by_suit=not sort_by_suit
  sort_cards(hand,sort_by_suit)
 end
 local picked=picked_cards()
 hand_label,chips,mult=nil,0,0
 if #picked>0 then
  local spec,_,_,label=evaluate(picked)
  hand_label=hand_title(spec,label)
  chips,mult=hand_base(spec)
  if btnp(5) then play_hand()
  elseif btnp(3) and discards_left>0 then discard_hand() end
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
  burst(x,y+4,colour,8)
  if step.chips then chips_bump=2 else mult_bump=2 end
  sfx((step.chips and snd_chips or snd_mult)+min(step_index-1,7))
  step_timer=step_frames
 elseif step_index==#steps+1 then
  active_step=nil
  local total=hand_total(chips,mult)
  score+=total
  add(pops,{text=big_text(total),x=64,y=78,colour=10,age=0,big=true})
  burst(64,28,10,24)
  burst(64,28,9,16)
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
  {blind_specs[blind].name,blind_specs[blind].reward},
  {"hands left",hands_left},
  {"interest",min(money\interest_step,interest_cap)}
 }
 earned=0
 for line in all(earnings) do earned+=line[2] end
 money+=earned
 mode="cashout"
end

function pop(text,x,y,colour)
 add(pops,{text=text,x=x,y=y,colour=colour,age=0})
end

function _update60()
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
end
