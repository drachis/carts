-- golden.lua : on demand, py golden_compare.py. a scripted run of Loretta
-- through every state, frame-counter clock, seeded random; one line a frame
-- of her state and a checksum of the screen. for proving a compaction
-- changed nothing.
function sfx() end
music,dset=sfx,sfx
local frame,game_update_frame,game_draw=0,_update60,_draw
function t() return frame/60 end
function _draw() end
local plan=split"60,0,120,2,30,0,60,1,40,18,50,2,30,0,120,8,60,0,20,32,30,2,40,16,60,0,700,0,40,8,10,24,80,2,20,1,60,2"
local at,left=-1,0
local function line_of(h)
 local sum=0
 for a=0x6000,0x7ffc,4 do sum=bxor(rotl(sum,1),$a) end
 local out=frame.." "..tostr(sum,1).." "..h.state
 for v in all{h.x,h.y,h.vx,h.vy,h.gait,h.turn,h.sag,h.hx,h.hy,h.flop,h.ears[1].x,h.ears[1].y,h.ears[2].x,h.ears[2].y,h.tongue[3].x,h.tongue[3].y} do out..=" "..tostr(v,1) end
 printh("g "..out)
end
function _update60()
 run_frame(function()
  if frame==0 then
   srand(7)
   level,score,coins=1,0,0
   start_level()
   mode="play"
  end
  frame+=1
  if left==0 then at+=2 left=plan[at] or 30000 end
  left-=1
  local input=plan[at+1] or 0
  function read_input() return input end
  if frame==1400 then hearts=1 fall_in(hero) end
  game_update_frame()
  game_draw()
  line_of(hero)
  if not plan[at] then printh("ok golden") extcmd("shutdown") end
 end)
end
