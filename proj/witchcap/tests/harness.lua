-- harness.lua : shared by the test carts that script the witch, included
-- after the game's modules and dump.lua. scripted buttons, silence and no
-- saving; an arena of flat ground; and a runner for a list of cases.
--
-- the cart defines `cases`. each case has a name, the buttons to hold, a
-- number of frames, a setup, and a check that returns whether it passed
-- and what it measured. `each`, if a case has one, is called every frame.
--
-- pico-8 runs in real time, so the runner plays four frames of the game
-- for each frame pico-8 shows and draws only the last of them. a case
-- that looks at the screen every frame, or measures the frame rate, sets
-- every_frame.

held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
music=sfx

local game_update,game_draw=_update60,_draw

function hold(buttons)
 held={}
 for button in all(buttons) do held[button]=true end
end

function arena()
 -- the saved progress on this machine is the player's: tests name their
 -- own level
 level,unlocked=5,5
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
function ledge(top_row)
 arena()
 for column=70,90 do
  mset(column,top_row,16)
  for row=top_row+1,12 do mset(column,row,17) end
 end
end

function grow(kind)
 add(mushrooms,{x=witch.x,y=witch.y,kind=kind})
end

local case_number,case_frame,speed=1,0,1

local function step()
 local case=cases[case_number]
 if case_frame==case.frames then
  local passed,detail=case.check()
  printh((passed and "pass: " or "error: ")..case.name.." ("..detail..")")
  case_number+=1
  case_frame=0
  case=cases[case_number]
  if not case then
   printh("ok "..log_name)
   extcmd("shutdown")
   cases,case_number={{frames=32000,buttons={},setup=arena}},1
   return
  end
 end
 if case_frame==0 then
  case.setup()
  highest=witch.y
  bare_frames=0
  speed=case.every_frame and 1 or 4
 elseif pget(64,116)<2 then
  -- the last frame drawn had sky or a tree where the earth should be
  bare_frames+=1
 end
 highest=min(highest,witch.y)
 if case.each then case.each() end
 hold(case.buttons)
 case_frame+=1
end

function _draw() end

local function work()
 for frame=1,speed do
  step()
  game_update()
 end
 game_draw()
 -- what the last update and the draw cost, for a case to report
 frame_cpu=stat(1)
end

function _update60()
 run_frame(work)
end
