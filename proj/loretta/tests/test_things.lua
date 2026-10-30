-- test_things.lua : Loretta and the things of the level, each alone:
-- squirrels (a stomp, a bump, a bark), a coin, a bone, a neighbour, the
-- water and a hydrant, the observatory. arena.lua sets the scene.

local function squirrel_at(x)
 return thing_at("squirrel",x,84)
end

cases={
 {
  name="landing on a squirrel starts a chase and bounces her",buttons={},frames=50,
  setup=function()
   arena(90,40)
   result.squirrel,result.bounce=squirrel_at(98),0
  end,
  each=function() result.bounce=min(result.bounce,hero.vy) end,
  check=function() return result.squirrel.state=="spooked" and result.bounce<-1 and hearts==max_hearts,"score "..score..", bounce "..result.bounce..", hearts "..hearts end,
 },
 {
  name="running into a squirrel chases it off: it flees to the tree ahead, climbs it and drops three coins, no heart lost",buttons={1},frames=130,
  setup=function() arena(40) result.squirrel=squirrel_at(90) thing_at("tree",170,88) end,
  check=function()
   local dropped=0
   for thing in all(things) do if thing.land then dropped+=1 end end
   return hearts==max_hearts and result.squirrel.top and abs(result.squirrel.x-168)<4 and dropped+coins==3,"hearts "..hearts..", up at x "..result.squirrel.x..", coins "..dropped.."+"..coins
  end,
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
  name="a coin at her head is collected, once, though it misses her body",buttons={},frames=6,
  setup=function() arena(40) thing_at("coin",hero.hx-3,hero.hy-8) end,
  check=function() return coins==1 and #things==0,"coins "..coins end,
 },
 {
  name="losing the last heart is a game over",buttons={},frames=90,
  setup=function() arena(40) hearts=1 hurt_loretta(hero,hero.x+20) end,
  check=function() _draw() dump_screen("over") return mode=="over","mode "..mode end,
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
}
