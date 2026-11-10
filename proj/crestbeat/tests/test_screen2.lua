local game_draw=_draw
function sfx() end
music=sfx

local function check(name,passed,detail)
 printh((passed and "pass: " or "error: ")..name.." ("..tostr(detail)..")")
end

local function screen()
 reset("play")
 send_alien(0,0)
 local last,least,most,total,frames=nil,99,0,0,0
 while clock<8 do
  clock+=1/frames_per_beat
  update_aliens()
  local t=aliens[1].t
  if last and t>=0 then
   local step=t-last
   least,most,total,frames=min(least,step),max(most,step),total+step,frames+1
  end
  last=t
 end
 local mean=total/frames
 check("an alien moves smoothly: always forward, no frame more than 3x the mean",least>0 and most<mean*3,"steps "..least.." to "..most..", mean "..mean)


 reset("play")
 start_stage(3)
 titan.rise,clock,robot.last_tick=1,4,7
 update_gun()
 local spot=titan.spots[2]
 check("a shot at a shielded street is blocked by the shield",#beams==1 and spot.hp==4*8/3 and spot.flash>0,#beams.." beams, hp "..spot.hp)
 titan.spots[1].hp=0
 open_spot(1,4)
 clock,spot.flash=5,0
 cls()
 draw_titan()
 dump_screen("screen_shields")
 local x,bar_y,lit=titan_x(),max(10,titan_y()-26),{}
 for lane=-1,1 do
  local red=0
  for dx=-8,8 do
   if pget(x+lane*16+dx,bar_y)==8 then red+=1 end
  end
  add(lit,red)
 end
 check("one segmented bar a street over its head, empty once the street is destroyed",lit[1]==0 and lit[2]>4 and lit[3]>4,"red pixels "..lit[1].." "..lit[2].." "..lit[3])
 local blue={}
 for lane=-1,1 do
  local count=0
  for dx=lane*3-3,lane*3+3 do
   for y=titan_y()-4,titan_y()+28 do
    if pget(x+lane*15.6+dx,y)==12 then count+=1 end
   end
  end
  add(blue,count)
 end
 check("a honeycomb shield stands in a closed street, none in an open or destroyed one",blue[1]==0 and blue[2]>40 and blue[3]==0,"blue pixels "..blue[1].." "..blue[2].." "..blue[3])

 reset("play")
 start_stage(3)
 titan.rise,crest_y,clock=1,titan_horizon,10
 send_alien(1,9)
 send_alien(0,7)
 spit(0,9.6)
 spit(1,9.2)
 update_aliens()
 clock=11
 update_aliens()
 game_draw()
 dump_screen("screen_spit")
 local fire,x=0,project(0,spit_along(hazards[1]))
 cls()
 draw_pillar(hazards[1])
 for y=0,83 do
  for dx=-12,12 do
   local colour=pget(x+dx,y)
   if colour==8 or colour==9 or colour==10 then fire+=1 end
  end
 end
 check("the titan's fire pillar towers past the mech",fire>150,fire.." fire pixels above the robot")


 printh("ok screen2")
 extcmd("shutdown")
end

local done
function _update()
 if not done then
  done=true
  run_frame(screen)
 end
end
function _draw() end
