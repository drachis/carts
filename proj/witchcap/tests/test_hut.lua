-- test_hut.lua : baba yaga's hut on flat ground, one case at a time: how
-- it follows, steps, balances, turns and stands, and what it costs to
-- draw. the cases and the arena are run by harness.lua.

-- stands the hut beside the witch, as it is when it has caught her up
local function hut_beside_her()
 arena()
 hut.x=witch.x-24
 hut.body_x=hut.x
 for foot in all(hut.feet) do foot.x=hut.x+foot.hip*2 end
end

cases={
 {
  name="the hut falls behind her at a run, with its feet under it",
  buttons={1},frames=300,
  setup=arena,
  check=function()
   local gap=witch.x-hut.x
   local spread=max(abs(hut.feet[1].x-hut.x),abs(hut.feet[2].x-hut.x))
   return gap>150 and hut.x>cauldron_x+100 and spread<50,
    "hut "..gap.." pixels behind, a foot "..spread.." from its middle"
  end,
 },
 {
  name="the hut's feet come down in turn, each well beyond the other",
  buttons={1},frames=400,
  setup=function()
   arena()
   landings,was_stepping,overhang={},{},0
  end,
  each=function()
   -- how far its body is outside the span of its feet
   local back=min(hut.feet[1].x,hut.feet[2].x)
   local front=max(hut.feet[1].x,hut.feet[2].x)
   overhang=max(overhang,max(back-hut.body_x,hut.body_x-front))
   for number,foot in ipairs(hut.feet) do
    if was_stepping[number] and foot.step==0 then
     add(landings,{number,foot.x})
    end
    was_stepping[number]=foot.step>0
   end
  end,
  check=function()
   local closest,in_turn=999,true
   for i=2,#landings do
    closest=min(closest,landings[i][2]-landings[i-1][2])
    if landings[i][1]==landings[i-1][1] then in_turn=false end
   end
   return #landings>6 and in_turn and closest>24 and overhang<4,
    #landings.." landings, the closest "..closest.." pixels beyond the one before; its body never past its feet by more than "..overhang
  end,
 },
 {
  name="the hut turns to face the way it walks",
  buttons={0},frames=200,
  setup=arena,
  check=function()
   dump_screen("hut_left")
   return hut.facing==-1 and hut.turn<-0.9,
    "facing "..hut.facing..", turned "..hut.turn
  end,
 },
 {
  name="the hut shows its front in the middle of a turn",
  buttons={},frames=2,every_frame=true,
  setup=function()
   hut_beside_her()
   hut.turn=-0.1
  end,
  check=function()
   dump_screen("hut_front")
   return abs(hut.turn)<0.4,"turned "..hut.turn
  end,
 },
 {
  name="the hut catches her up when she stands still, a foot either side of its middle",
  buttons={},frames=420,
  setup=function()
   arena()
   frames_left=3600
  end,
  check=function()
   local feet=hut.feet
   return abs(witch.x-24-hut.x)<8
    and feet[1].x<hut.body_x and feet[2].x>hut.body_x and feet[2].x-feet[1].x<50,
    "hut "..witch.x-hut.x.." pixels to her left, feet at "..feet[1].x-hut.body_x
    .." and "..feet[2].x-hut.body_x.." from its body"
  end,
 },
 {
  name="the game holds 60 frames a second with the hut on the screen",
  buttons={},frames=60,every_frame=true,
  setup=hut_beside_her,
  check=function()
   dump_screen("hut")
   return stat(7)==60,stat(7).." frames a second, cpu "..frame_cpu
  end,
 },
}
