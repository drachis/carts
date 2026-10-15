-- helpers.lua : shared by the test carts that call the game's rules directly
-- (test_hands, test_shop). A cart includes the game, dump.lua, this, then its
-- own cases, which define run_cases(). The game plus every case passed 8192
-- tokens in one cart, so the cases are split across carts.

function index_of(text,letter)
 for i=1,#text do
  if sub(text,i,i)==letter then return i end
 end
end

function cards_of(text)
 local cards={}
 for word in all(split(text," ",false)) do
  add(cards,{
   rank=1+index_of("23456789tjqka",sub(word,1,1)),
   suit=index_of("shcd",sub(word,2,2))
  })
 end
 return cards
end

function jokers_of(text)
 local jokers={}
 for name in all(split(text,",",false)) do
  add(jokers,setmetatable({},joker_specs[name]))
 end
 return jokers
end

function expect(what,got,wanted)
 printh((got==wanted and "pass: " or "error: ")..what.." (got "..tostr(got)..", wanted "..tostr(wanted)..")")
end

function score_of(cards,jokers)
 local spec,_,_,steps=score_steps(cards,jokers or {})
 local chips,mult=hand_base(spec)
 for step in all(steps) do chips,mult=apply_step(step,chips,mult) end
 return chips*mult
end

function total_of(cards,names)
 return score_of(cards_of(cards),jokers_of(names))
end

function _update60()
 run_frame(function()
  run_cases()
  printh("ok "..sub(log_name,5))
  extcmd("shutdown")
  _update60=function() end
 end)
end
