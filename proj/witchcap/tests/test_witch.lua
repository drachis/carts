-- test_witch.lua : the witch's movement and the recipe's rules, one case
-- at a time on flat ground with only what the case needs. each case holds
-- some buttons for a number of frames and then checks where that left her.

local function arena()
 start_run()
 memset(0x2000,0,0x800)
 for column=0,127 do
  mset(column,12,16)
  for row=13,15 do mset(column,row,17) end
 end
 mushrooms={}
 -- the arena's ground is not where the forest's was
 reset_witch()
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
  name="the world goes round: she runs left past its edge on solid ground",
  buttons={0},frames=600,
  setup=arena,
  check=function()
   return witch.x<-150 and witch.y==96 and bare_frames==0,
    "at "..witch.x..","..witch.y..", "..bare_frames.." frames without ground drawn under her"
  end,
 },
 {
  name="a mushroom a lap away is the same mushroom",
  buttons={},frames=1,
  setup=function()
   arena()
   recipe={{kind=1,state=0}}
   add(mushrooms,{x=1000,y=96,kind=1})
   witch.x=-24
   pick_mushroom()
  end,
  check=function()
   return recipe[1].state==1 and #mushrooms==0,"slot state "..recipe[1].state
  end,
 },
 {
  name="the poison's sway never shows what is under the ground",
  buttons={},frames=120,
  setup=function()
   arena()
   witch.poison=poison_frames
  end,
  check=function()
   return bare_frames==0,
    "the bottom of the screen was not ground on "..bare_frames.." frames of 120"
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
  name="the hut shows its end wall in the middle of a turn",
  buttons={},frames=2,
  setup=function()
   arena()
   hut.x,hut.turn=witch.x-24,-0.1
   hut.body_x=hut.x
   for foot in all(hut.feet) do foot.x=hut.x+foot.hip*3 end
  end,
  check=function()
   dump_screen("hut_front")
   return abs(hut.turn)<0.4,"turned "..hut.turn
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
   -- and it stands with a foot either side of its middle
   local feet=hut.feet
   return abs(witch.x-24-hut.x)<8 and stat(7)==60
    and feet[1].x<hut.body_x and feet[2].x>hut.body_x and feet[2].x-feet[1].x<50,
    "hut "..witch.x-hut.x.." pixels to her left, feet at "..feet[1].x-hut.body_x
    .." and "..feet[2].x-hut.body_x.." from its body, "
    ..stat(7).." frames a second, cpu "..frame_cpu
  end,
 },
 {
  name="picks what the recipe wants, and no more of it than that",
  buttons={},frames=1,
  setup=function()
   arena()
   recipe={{kind=1,state=0},{kind=5,state=0}}
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
   recipe={{kind=1,state=2},{kind=5,state=1},{kind=9,state=1}}
   witch.x=300
   grow(6)
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
   recipe={{kind=1,state=1},{kind=5,state=1}}
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
  bare_frames=0
 elseif pget(64,116)<2 then
  -- the last frame drawn had sky or a tree where the earth should be
  bare_frames+=1
 end
 highest=min(highest,witch.y)
 if case.each then case.each() end
 hold(case.buttons)
 case_frame+=1
end
