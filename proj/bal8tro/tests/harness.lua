-- harness.lua : shared by the test carts that script the game, included
-- after the game's modules and dump.lua. scripted buttons, silence and no
-- saving, and a runner for a list of cases.
--
-- the cart defines `cases`. each case has:
--   name     what it claims, as a sentence ("climbs a ledge three tiles high")
--   buttons  the buttons held for the whole case ({1,4} is right and o)
--   frames   how many frames of the game it lasts
--   setup    called once, first: wipe an arena, place only what the case needs
--   check    called last: returns whether it passed, and what it measured
--   each     optional, called every frame (to track a highest point, say)
--   every_frame  optional: see below
--
-- pico-8 runs in real time, so the runner plays four frames of the game
-- for each frame pico-8 shows and draws only the last of them. a case that
-- looks at the screen every frame, or measures the frame rate, sets
-- every_frame.
--
-- this wraps _update60; a 30fps game wraps _update instead.

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
   -- the window stays open until the runner stops it: idle harmlessly
   cases,case_number={{frames=32000,buttons={},setup=cases[1].setup}},1
   return
  end
 end
 if case_frame==0 then
  case.setup()
  speed=case.every_frame and 1 or 4
 end
 -- not on a case's first frame: nothing of it has been drawn yet, and
 -- the screen is still the last case's
 if case.each and case_frame>0 then case.each() end
 hold(case.buttons)
 case_frame+=1
end

local function work()
 for frame=1,speed do
  step()
  game_update()
  -- a case that wants every frame drawn gets it from its first: without
  -- this its first frames would run out the batch the last case began,
  -- and look at that case's picture
  if speed==1 then break end
 end
 game_draw()
 -- what the last update and the draw cost, for a case to report beside
 -- stat(7), which is the frame rate pico-8 is holding
 frame_cpu=stat(1)
end

function _draw() end

function _update60()
 run_frame(work)
end
