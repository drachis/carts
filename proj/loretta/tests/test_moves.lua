-- test_moves.lua : each of Loretta's verbs alone, on the real level: the
-- street (flat ground at y 96, an awning at x 112..175 with its top at
-- y 72), the lawn's slopes, the stream and the observatory lawn, with what
-- each measured printed.

local ground_y,result=82,{}

local function arena(x,y)
 start_level()
 mode,things,hero="play",{},new_loretta(x,y or ground_y)
 hero.held=0
 view=new_camera(hero)
end

local function thing_at(name,x,y)
 return add(things,setmetatable({x=x,y=y,vx=0,vy=0,age=0,petting=0},thing_specs[name]))
end

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

local function backdrop_row(cam_x,shift)
 view.x=cam_x
 camera()
 draw_backdrop(cam_x)
 local row=""
 for y in all{25,122} do
  for x=8,23 do row..=pget(x+shift,y) end
 end
 return row
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
  setup=function() arena(128) end,
  check=function() return hero.y==58 and not hero.air,"y "..hero.y.." (the awning's top is 58)" end,
 },
 {
  name="down and jump on an awning drops through it to the ground",buttons={3,4},frames=60,
  setup=function() arena(128,58) end,
  check=function() return hero.y==ground_y,"y "..hero.y end,
 },
 {
  name="landing on a squirrel bonks it, scores and bounces",buttons={},frames=50,
  setup=function()
   arena(56,40)
   result.squirrel,result.bounce=squirrel_at(64),0
  end,
  each=function() result.bounce=min(result.bounce,hero.vy) end,
  check=function() return result.squirrel.state=="bonked" and score==stomp_points and result.bounce<-1 and hearts==max_hearts,"score "..score..", bounce "..result.bounce..", hearts "..hearts end,
 },
 {
  name="running into a squirrel costs a heart, knocks her back and she blinks",buttons={1},frames=50,
  setup=function() arena(40) squirrel_at(90) end,
  check=function() return hearts==max_hearts-1 and hero.hurt>0 and hero.x<62,"hearts "..hearts..", x "..hero.x..", blinking "..hero.hurt end,
 },
 {
  name="a bark spooks a squirrel in reach and not one beyond it",buttons={5},frames=50,
  setup=function()
   arena(16)
   result.near,result.far=squirrel_at(16+hero_w+bark_reach-14),squirrel_at(16+hero_w+bark_reach+30)
  end,
  check=function() return result.near.state=="spooked" and not result.far.state,"reach "..bark_reach..", near "..tostr(result.near.state)..", far "..tostr(result.far.state) end,
 },
 {
  name="a coin counts and scores",buttons={1},frames=40,
  setup=function() arena(16) thing_at("coin",60,84) end,
  check=function() return coins==1 and score==coin_points,"coins "..coins..", score "..score end,
 },
 {
  name="a bone gives back a heart",buttons={1},frames=40,
  setup=function() arena(16) hearts=2 thing_at("bone",60,90) end,
  check=function() return hearts==3,"hearts "..hearts end,
 },
 {
  name="sitting beside a neighbour fills her hearts",buttons={3},frames=100,
  setup=function()
   arena(40)
   hearts=1
   result.neighbour=thing_at("neighbour",60,88)
  end,
  check=function() return hearts==min(1+pet_hearts,max_hearts) and result.neighbour.petted,"hearts "..hearts..", petted "..tostr(result.neighbour.petted) end,
 },
 {
  name="the water costs a heart and she comes back at the last hydrant",buttons={},frames=90,
  setup=function()
   arena(600,100)
   respawn_x,respawn_y=500,ground_y
  end,
  check=function() return hearts==max_hearts-1 and hero.x==500 and respawn==0,"hearts "..hearts..", back at x "..hero.x end,
 },
 {
  name="running into the observatory wins",buttons={1},frames=60,
  setup=function()
   arena(1890,50)
   load_level()
   for thing in all(things) do
    if thing.name!="gate" then del(things,thing) end
   end
  end,
  check=function() return mode=="win","mode "..mode end,
 },
 {
  name="the backdrop's dither stays put on the screen as the camera moves",buttons={},frames=1,
  setup=function() arena(16) end,
  check=function()
   local still,moved,shifted=backdrop_row(300,0),backdrop_row(301,0),backdrop_row(300,1)
   return still==moved and still!=shifted,"same at camera 300 and 301: "..tostr(still==moved)..", the rows are dithered (differ a pixel over): "..tostr(still!=shifted)
  end,
 },
}
