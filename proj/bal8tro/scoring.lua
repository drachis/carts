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
 hand_levels={}
 for spec in all(hand_specs) do hand_levels[spec.name]=1 end
end

function hand_base(spec)
 local ups=hand_levels[spec.name]-1
 return spec.chips+ups*spec.level_chips,spec.mult+ups*spec.level_mult
end

function hand_title(spec,label)
 return label.." lv"..hand_levels[spec.name]
end

function joker_fires_on(joker,card)
 return joker.when=="card" and (joker.need==card.suit or joker.need=="face" and is_face(card))
end

function score_steps(played,jokers)
 local spec,scoring,contains,label=evaluate(played)
 local steps={}
 for card in all(scoring) do
  add(steps,{thing=card,chips=card_chips(card)})
  for joker in all(jokers) do
   if joker_fires_on(joker,card) then
    add(steps,{thing=joker,under=card,chips=joker.chips,mult=joker.mult,xmult=joker.xmult})
   end
  end
 end
 for joker in all(jokers) do
  if joker.when=="hand" and (not joker.need or contains[joker.need]) then
   add(steps,{thing=joker,chips=joker.chips,mult=joker.mult,xmult=joker.xmult})
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

function blind_goal(ante,blind)
 return (ante_bases[ante]>>16)*50*blind_specs[blind].factor
end

function next_blind()
 if blind<#blind_specs then return ante,blind+1 end
 return ante+1,1
end

function big_text(number)
 return tostr(number,2)
end
