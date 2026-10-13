-- test_witch.lua : the witch's movement and the recipe's rules, one case
-- at a time on flat ground with only what the case needs. each case holds
-- some buttons for a number of frames and then checks where that left her.

local function arena()
 start_run()
 memset(0x2000,0,0x1000)
 for column=0,127 do
  mset(column,12,16)
  for row=13,15 do mset(column,row,17) end
 end
 mushrooms={}
end

-- a step up in the ground, 60 pixels to her right, its top at `top_row`
local function ledge(top_row)
 arena()
 for column=70,90 do
  mset(column,top_row,16)
  for row=top_row+1,12 do mset(column,row,17) end
 end
end

local function grow(kind)
 add(mushrooms,{x=witch.x,y=witch.y,kind=kind})
end

local highest

local cases={
 {
  name="climbs a ledge three tiles high",
  buttons={1,4},frames=120,
  setup=function() ledge(9) end,
  check=function()
   return witch.y<=72 and witch.x>564,"at "..witch.x..","..witch.y
  end,
 },
 {
  name="cannot climb a ledge four tiles high",
  buttons={1,4},frames=240,
  setup=function() ledge(8) end,
  check=function()
   return witch.x<560,"at "..witch.x..","..witch.y
  end,
 },
 {
  name="jumps up through a branch three tiles up and stands on it",
  buttons={4},frames=50,
  setup=function()
   arena()
   for column=61,63 do mset(column,9,18) end
  end,
  check=function()
   return witch.y<=72,"feet at "..witch.y
  end,
 },
 {
  name="a full jump",
  buttons={4},frames=45,
  setup=arena,
  check=function()
   return highest<=70,"rose "..96-highest.." pixels"
  end,
 },
 {
  name="a tapped jump is a short hop",
  buttons={},frames=45,
  setup=function()
   arena()
   witch.vy,witch.air_frames=-jump_speed,coyote_frames
  end,
  check=function()
   return highest>85,"rose "..96-highest.." pixels"
  end,
 },
 {
  name="runs",
  buttons={1},frames=60,
  setup=arena,
  check=function()
   return witch.x-cauldron_x>58,"went "..witch.x-cauldron_x.." pixels in a second"
  end,
 },
 {
  name="runs at half speed when poisoned",
  buttons={1},frames=60,
  setup=function()
   arena()
   witch.poison=poison_frames
  end,
  check=function()
   return witch.x-cauldron_x<45,"went "..witch.x-cauldron_x.." pixels in a second"
  end,
 },
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
  name="the hut catches her up when she stands still",
  buttons={},frames=420,
  setup=function()
   arena()
   frames_left=3600
  end,
  check=function()
   dump_screen("hut")
   return abs(witch.x-hut.x)<8,"hut "..witch.x-hut.x.." pixels away"
  end,
 },
 {
  name="picks what the recipe wants, and no more of it than that",
  buttons={},frames=1,
  setup=function()
   arena()
   recipe={{kind=1,state=0},{kind=3,state=0}}
   witch.x=300
   grow(1)
   pick_mushroom()
   grow(1)
   pick_mushroom()
  end,
  check=function()
   return recipe[1].state==1 and #mushrooms==1,
    "slot state "..recipe[1].state..", "..#mushrooms.." left growing"
  end,
 },
 {
  name="a lookalike poisons her and spoils one from the basket",
  buttons={},frames=1,
  setup=function()
   arena()
   recipe={{kind=1,state=2},{kind=3,state=1},{kind=5,state=1}}
   witch.x=300
   grow(4)
   pick_mushroom()
  end,
  check=function()
   return witch.poison>0 and recipe[1].state==2 and recipe[2].state==0
    and recipe[3].state==1 and #mushrooms==0,
    "poison "..witch.poison..", slots "..recipe[1].state..recipe[2].state..recipe[3].state
  end,
 },
 {
  name="the basket goes into the pot and a full recipe is brewed",
  buttons={},frames=2,
  setup=function()
   arena()
   recipe={{kind=1,state=1},{kind=3,state=1}}
  end,
  check=function()
   return mode=="brewed" and recipe[2].state==2,"mode "..mode
  end,
 },
 {
  name="an unfinished recipe goes cold when the time runs out",
  buttons={},frames=3,
  setup=function()
   arena()
   frames_left=2
  end,
  check=function()
   return mode=="cold","mode "..mode
  end,
 },
}

local case_number,case_frame=1,0

function step()
 local case=cases[case_number]
 if case_frame==case.frames then
  local passed,detail=case.check()
  printh((passed and "pass: " or "error: ")..case.name.." ("..detail..")")
  case_number+=1
  case_frame=0
  case=cases[case_number]
  if not case then
   printh("ok witch")
   extcmd("shutdown")
   cases,case_number={{frames=32000,buttons={},setup=arena}},1
   return
  end
 end
 if case_frame==0 then
  case.setup()
  highest=witch.y
 end
 highest=min(highest,witch.y)
 hold(case.buttons)
 case_frame+=1
end
