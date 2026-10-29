-- test_motion.lua : Loretta drawn every frame through a scripted run (90
-- frames standing, 120 trotting right, 60 stopping, then a fall to a
-- landing), logging one "m" line a frame: frame, x, vx, gait, the body's
-- bob and rump, the head's bob, the belly's sag, each ear tip and the
-- tongue tip from their roots, and how her pixels changed: "churn" (pixels
-- different from the frame before) and "flicker" (pixels back to what they
-- were two frames before, the mark of jitter). She is drawn on a plain
-- background with the camera on her whole-pixel x, so only her own shape
-- counts ("own"), then again through the game's own camera ("game").
-- py motion_report.py sums the log up by phase. it fails if, trotting,
-- her place on the screen goes back and forth, her chest bobs, or her ear
-- or tongue tip turns back more often than a swing would: the jitter the
-- user saw came from each of those.

function sfx() end
music=sfx
dset=sfx

local frame,crops,game_draw=0,{},_draw
local plan=split"90,0,120,2,60,0,60,0"

local function crop(left)
 local pixels={}
 for y=40,100 do
  for x=left,left+56 do add(pixels,pget(x,y)) end
 end
 return pixels
end

local bands
local function changes(now,before,older)
 local churn,flicker=0,0
 bands={0,0,0}
 for i,colour in ipairs(now) do
  if before and colour!=before[i] then
   churn+=1
   if older and colour==older[i] then
    flicker+=1
    local band=min(3,(i-1)\57\20+1)
    bands[band]+=1
   end
  end
 end
 return churn,flicker
end

local tracks={}
local function track(name,value)
 local track=tracks[name] or {flips=0,reversals=0}
 tracks[name]=track
 if track.value then
  local step=value-track.value
  if flr(value+0.5)!=flr(track.value+0.5) then track.flips+=1 end
  if abs(step)>0.01 then
   if track.step and step*track.step<0 then track.reversals+=1 end
   track.step=step
  end
 end
 track.value=value
end

local function expect(name,what,most)
 local count=tracks[name][what]
 printh((count<=most and "pass: " or "error: ").."trotting, "..name.." "..what.." "..count.." times (at most "..most..")")
end

local function input()
 local at=frame
 for i=1,#plan,2 do
  if at<=plan[i] then return plan[i+1] end
  at-=plan[i]
 end
end

function _update60()
 run_frame(function()
  frame+=1
  if frame==1 then
   start_level()
   mode,things="play",{}
   hero=new_loretta(40,82)
   hero.held=0
  end
  if frame==271 then hero.x,hero.y,hero.vx,hero.vy=hero.x,30,0,0 end
  update_loretta(hero,input() or 0)
  update_camera(view,hero)
  local ear,tongue=hero.ears[2],hero.tongue
  local bob,rump=body_bob(hero)
  if frame>100 and frame<=210 then
   track("her place on screen",flr(hero.x+0.5)-camera_x())
   track("her chest",bob)
   track("her ear tip",ear.x-ear.bx)
   track("her tongue tip",tongue[5].x-tongue[1].x)
  end
  if frame==211 then
   expect("her place on screen","reversals",2)
   expect("her chest","flips",0)
   expect("her ear tip","reversals",15)
   expect("her tongue tip","reversals",15)
  end
  local line="m "..frame.." "..hero.x.." "..hero.vx.." "..hero.gait.." "..bob.." "..rump.." "..hero.head_bob.." "..hero.sag.." "..(ear.x-ear.bx).." "..(ear.y-ear.by).." "..(tongue[5].x-tongue[1].x).." "..(tongue[5].y-tongue[1].y)
  for pass=1,2 do
   if pass==1 then
    cls(1)
    camera(flr(hero.x+0.5)-16,0)
    draw_loretta(hero)
    camera()
    if frame>=150 and frame<158 then dump_screen("trot_"..frame) end
   else
    game_draw()
   end
   local left=pass==1 and 4 or mid(0,flr(hero.x-view.x+0.5)-12,70)
   local now=crop(left)
   local churn,flicker=changes(now,crops[pass],crops[pass+2])
   crops[pass+2],crops[pass]=crops[pass],now
   line..=" "..churn.." "..flicker
   if pass==1 then line..=" "..bands[1].." "..bands[2].." "..bands[3] end
  end
  printh(line)
  if frame%30==0 and frame<=300 then dump_screen("motion_"..frame) end
  if frame==330 then
   printh("ok motion")
   extcmd("shutdown")
  end
 end)
end

function _draw() end
