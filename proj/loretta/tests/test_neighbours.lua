-- test_neighbours.lua : a neighbour's pats, treat and where they stand; hedges.

cases={
 {
  name="sitting beside a neighbour fills her hearts",buttons={3},frames=170,
  setup=function()
   arena(40)
   hearts=1
   result.neighbour=thing_at("neighbour",60,88)
  end,
  check=function() return hearts==min(1+pet_hearts,max_hearts) and result.neighbour.petted,"hearts "..hearts..", petted "..tostr(result.neighbour.petted) end,
 },
 {
  name="sitting near the edge of the neighbour's zone still brings them over, her head beside their legs",buttons={3},frames=60,
  setup=function() arena(40) result.neighbour=thing_at("neighbour",100,88) end,
  check=function() local n=result.neighbour return n.petting>0 and n.x+n.step+8-hero.hx>=20,"petting "..n.petting..", head from their middle "..abs(hero.hx-n.x-n.step-8) end,
 },
 {
  name="a neighbour on her other side stays on that side to pat",buttons={3},frames=60,
  setup=function() arena(80) result.neighbour=thing_at("neighbour",50,88) end,
  check=function() local n=result.neighbour return n.petting>0 and hero.hx-n.x-n.step-8>=20,"head past their middle by "..hero.hx-n.x-n.step-8 end,
 },
 {
  name="once the treat is given, staying by the neighbour gets more pats but no more hearts",buttons={3},frames=600,every_frame=true,
  setup=function()
   arena(40)
   hearts,result.pats=1,0
   result.neighbour=thing_at("neighbour",60,88)
   result.neighbour.petted=true
  end,
  each=function() if result.neighbour.petting>0 then result.pats+=1 end end,
  check=function() return hearts==1 and result.pats>0,"hearts "..hearts..", pats "..result.pats end,
 },
 {
  name="a belly slide goes through a hedge wall",buttons={1,3},frames=70,
  setup=function() arena(40) mset(12,10,14) mset(12,11,14) hero.vx=1.3 end,
  check=function() mset(12,10,0) mset(12,11,0) return hero.x>100,"x "..hero.x end,
 },
 {
  name="inside a hedge she can still walk out",buttons={1},frames=40,
  setup=function() arena(88) mset(12,10,14) mset(12,11,14) end,
  check=function() mset(12,10,0) mset(12,11,0) return hero.x>110,"x "..hero.x end,
 },
}
