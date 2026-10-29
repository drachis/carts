-- test_moves.lua : each of Loretta's verbs alone, on the real level: the
-- street (the bookshop's awning at x 168..231 with its top at y 72), the
-- lawn's slopes, the stream and the observatory lawn, with what each
-- measured printed. arena.lua sets the scene; her body is in test_body.

local function squirrel_at(x)
 return thing_at("squirrel",x,84)
end

local function track_height()
 result.top=min(result.top,hero.y)
 if hero.air then result.air+=1 end
end

local function jump_case(name,buttons,each)
 return {
  name=name,buttons=buttons,frames=150,
  setup=function()
   arena(16)
   hero.buffer=jump_buffer
   result.top,result.air=ground_y,0
  end,
  each=function() track_height() if each then each() end end,
  check=function()
   result[name]={ground_y-result.top,result.air}
   return hero.y==ground_y,"rose "..(ground_y-result.top).."px, "..result.air.." frames in the air"
  end,
 }
end

cases={
 {
  name="runs up to top speed and holds it",buttons={1},frames=60,
  setup=function() arena(16) end,
  check=function() return hero.vx==run_max,"vx "..hero.vx.." of "..run_max..", the screen crossed in "..flr(128/run_max).." frames" end,
 },
 jump_case("tapped jump",{}),
 jump_case("held jump, no paddle",{4},function() hero.paddle=0 end),
 jump_case("held jump with paddle",{4}),
 {
  name="a held jump rises higher than a tap, and paddling hangs longer",buttons={},frames=1,
  setup=function() end,
  check=function()
   local tap,held,paddle=result["tapped jump"],result["held jump, no paddle"],result["held jump with paddle"]
   return held[1]>tap[1]+12 and held[1]>=36 and held[1]<=56 and paddle[2]>held[2]+20,"tap "..tap[1].."px, held "..held[1].."px, air "..held[2].." frames, paddling "..paddle[2]
  end,
 },
 {
  name="runs over the lawn's hill, up and down its slopes, never leaving the ground",buttons={1},frames=170,
  setup=function() arena(290) result.air,result.top=0,ground_y end,
  each=track_height,
  check=function() return result.air==0 and hero.x>440 and hero.y==ground_y and result.top==ground_y-16,"frames in the air "..result.air..", highest "..(ground_y-result.top).."px, x "..hero.x end,
 },
 {
  name="jumps up through an awning from below and lands on it",buttons={4},frames=200,
  setup=function() arena(184) end,
  check=function() return hero.y==58 and not hero.air,"y "..hero.y.." (the bookshop awning's top is 58)" end,
 },
 {
  name="down and jump on an awning drops through it to the ground",buttons={3,4},frames=60,
  setup=function() arena(184,58) end,
  check=function() return hero.y==ground_y,"y "..hero.y end,
 },
}
