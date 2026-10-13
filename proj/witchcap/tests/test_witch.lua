-- test_witch.lua : the witch's movement and the recipe's rules, one case
-- at a time on flat ground with only what the case needs. each case holds
-- some buttons for a number of frames and then checks where that left her.
-- the cases and the arena are run by harness.lua.

cases={
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
  name="the broom carries her a screen's width and sets her down",
  buttons={2},frames=70,
  setup=arena,
  check=function()
   local flown=witch.x-cauldron_x
   return flown>120 and flown<136 and witch.y==96 and highest>=80,
    "flew "..flown.." pixels, "..96-highest.." above the ground at most"
  end,
 },
 {
  name="the broom lifts her over a ledge four tiles high",
  buttons={2},frames=70,
  setup=function() ledge(8) end,
  check=function()
   return witch.x>600 and witch.y==64,"at "..witch.x..","..witch.y
  end,
 },
 {
  name="the broom has to rest, and will not fly her poisoned",
  buttons={2},frames=200,
  setup=function()
   arena()
   witch.poison=poison_frames
  end,
  check=function()
   -- poisoned for 180 frames, then one flight, which is still resting
   local flown=witch.x-cauldron_x
   return flown>0 and flown<136 and witch.broom_wait>0,
    "flew "..flown.." pixels in 200 frames, "..witch.broom_wait.." frames of rest to go"
  end,
 },
 {
  name="the world goes round: she runs left past its edge on solid ground",
  buttons={0},frames=200,every_frame=true,
  setup=function()
   arena()
   witch.x=60
  end,
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
  buttons={},frames=120,every_frame=true,
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
  name="a lookalike poisons her and spoils one from the basket, which grows again",
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
    and recipe[3].state==1 and #mushrooms==1 and mushrooms[1].kind==5,
    "poison "..witch.poison..", slots "..recipe[1].state..recipe[2].state..recipe[3].state
    ..", "..#mushrooms.." growing"
  end,
 },
 {
  name="at the pot the basket takes to the air, and the potion waits for it",
  buttons={},frames=20,
  setup=function()
   arena()
   recipe={{kind=1,state=1},{kind=5,state=1},{kind=9,state=1}}
  end,
  check=function()
   dump_screen("deposit")
   return mode=="play" and recipe[1].state==3 and #flights==3,
    "mode "..mode..", "..#flights.." in the air"
  end,
 },
 {
  name="the potion is brewed when the last mushroom lands in the pot",
  buttons={},frames=60,
  setup=function()
   arena()
   recipe={{kind=1,state=1},{kind=5,state=1}}
  end,
  check=function()
   return mode=="brewed" and recipe[2].state==2 and run_frames>30,
    "mode "..mode.." after "..run_frames.." frames"
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
