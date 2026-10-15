function deal_jokers(count,owned)
 local pool,dealt={},{}
 for spec in all(joker_specs) do add(pool,spec) end
 for joker in all(owned) do del(pool,getmetatable(joker)) end
 for i=1,min(count,#pool) do
  local spec=rnd(pool)
  del(pool,spec)
  add(dealt,setmetatable({},spec))
 end
 return dealt
end

function reset_levels()
 hand_levels,hand_plays={},{}
 for spec in all(hand_specs) do hand_levels[spec.name],hand_plays[spec.name]=1,0 end
end

function joker_scale(joker,spec,owned)
 local per=joker.per
 if per=="jokers" then return #owned end
 if per=="discards" then return discards_left end
 if per=="plays" then return spec and hand_plays[spec.name] or 1 end
 if per=="count" then return joker.count or 0 end
 return 1
end

function grow_jokers(event,scoring)
 local face
 for card in all(scoring) do face=face or is_face(card) end
 for joker in all(jokers) do
  local before=joker.count or 0
  if joker.grow=="green" then joker.count=max(before+(event=="play" and 1 or -1),0) end
  if joker.grow=="bus" and event=="play" then joker.count=face and 0 or before+1 end
  if joker.x and joker.count and joker.count!=before then
   local x,y=thing_position(joker)
   pop(joker.count>before and "+1" or "reset",x,y,joker.count>before and 8 or 6)
   kick(joker,3)
  end
 end
end

function boss_on()
 return blind==#blind_specs and (mode=="play" or mode=="score") and boss
end

function is_debuffed(card)
 local active=boss_on()
 return active and active.debuff==card.suit
end

function can_play(picked)
 local active=boss_on()
 return #picked>=(active and active.must or 1)
end

function hand_base(spec)
 local ups,active=hand_levels[spec.name]-1,boss_on()
 local chips,mult=spec.chips+ups*spec.level_chips,spec.mult+ups*spec.level_mult
 if active and active.halve then return ceil(chips/2),ceil(mult/2) end
 return chips,mult
end

function hand_title(spec,label)
 return label=="royal flush" and "royal" or spec.short,hand_levels[spec.name]
end

function joker_fires_on(joker,card)
 return joker.when=="card" and (joker.need=="face" and is_face(card) or joker.need!="face" and is_suit(card,joker.need))
end

function score_steps(played,jokers)
 local spec,scoring,contains,label=evaluate(played)
 local steps={}
 for card in all(scoring) do
  if not is_debuffed(card) then
   local boost=enhancement_specs[card.enhancement] or {}
   add(steps,{thing=card,chips=card_chips(card)+(boost.chips or 0)})
   if (boost.mult or boost.xmult) and (boost.name!="lucky" or rnd(5)<1) then
    add(steps,{thing=card,mult=boost.mult,xmult=boost.xmult})
   end
   for joker in all(jokers) do
    if joker_fires_on(joker,card) then
     add(steps,{thing=joker,under=card,chips=joker.chips,mult=joker.mult,xmult=joker.xmult})
    end
   end
  end
 end
 for card in all(hand) do
  if card.enhancement=="steel" then add(steps,{thing=card,xmult=1.5}) end
 end
 contains.small,contains.nodisc=#played<=3,discards_left==0
 for joker in all(jokers) do
  local scale=joker_scale(joker,spec,jokers)
  if joker.when=="hand" and (not joker.need or contains[joker.need]) and scale>0 then
   add(steps,{thing=joker,chips=joker.chips and joker.chips*scale,mult=joker.mult and joker.mult*scale,xmult=joker.xmult})
  end
 end
 return spec,label,scoring,steps
end

function apply_step(step,chips,mult)
 return chips+(step.chips or 0),(mult+(step.mult or 0))*(step.xmult or 1)
end

function hand_total(chips,mult)
 return (chips>>16)*mult
end

function blind_goal(ante,which)
 local factor=which==#blind_specs and boss.factor or blind_specs[which].factor
 return (ante_bases[ante]>>16)*50*factor
end

function blind_name(which)
 return which==#blind_specs and boss.name or blind_specs[which].name
end

function next_blind()
 if blind<#blind_specs then return ante,blind+1 end
 return ante+1,1
end

function big_text(number)
 return tostr(number,2)
end
