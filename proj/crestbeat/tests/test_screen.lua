local game_draw=_draw
function sfx() end
music=sfx

local function check(name,passed,detail)
 printh((passed and "pass: " or "error: ")..name.." ("..tostr(detail)..")")
end

local function screen()
 reset("play")
 start_stage(#stages)
 titan.rise=1
 clock=10
 send_alien(0,10-0.85)
 update_aliens()
 game_draw()
 local rising=0
 for x=58,70 do
  for y=crest_y-10,crest_y-1 do
   if pget(x,y)==11 then rising+=1 end
  end
 end
 check("an alien rising over the crest is drawn in front of the queen",rising>10,rising.." green pixels")
 local below=pget(64,crest_y+10)
 check("the queen stands behind the crest, not on the road",below!=titan.colour and below!=2,"colour "..below)
 dump_screen("screen_queen")
 local function wing_rows()
  local top
  for y=0,crest_y do
   for x=30,48 do
    if pget(x,y)==2 and not top then top=y end
   end
  end
  return top or -1
 end
 start_stage(3)
 titan.rise,titan.bars,crest_y=1,0,titan_horizon
 clock=10.5
 game_draw()
 local up=wing_rows()
 clock=11.5
 game_draw()
 local down=wing_rows()
 check("the giant's wings flap",up>=0 and down>=0 and abs(up-down)>=4,"wing tops at "..up.." and "..down)

 reset("play")
 local before=""
 for y=0,35,5 do for x=0,35,5 do before..=sget(x,y) end end
 cls()
 robot.recoil,robot.lift,pulse=0,0,0
 draw_robot()
 local after,red=""
 for y=0,35,5 do for x=0,35,5 do after..=sget(x,y) end end
 for y=84,119 do for x=46,81 do if pget(x,y)==8 then red=true end end end
 check("the robot is drawn from the map at its full size",red,"red found: "..tostr(red))
 check("and the sprite sheet it borrowed is put back",before==after,"sheet "..(before==after and "restored" or "changed"))

 reset("play")
 robot.lane=1
 local furthest,settled=64
 for frame=1,30 do
  robot.vx=(robot.vx+(64+robot.lane*40-robot.x)*robot_spring)*robot_damping
  robot.x+=robot.vx
  furthest=max(furthest,robot.x)
  if not settled and abs(robot.x-104)<1 and abs(robot.vx)<0.5 then settled=frame end
 end
 check("the robot springs between streets, a little past and back",furthest>105 and furthest<108 and settled and settled<=12,"overshoots to "..furthest..", settles in "..tostr(settled).." frames")

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
 local gx,gy,gscale=project(0,spit_along(hazards[1]))
 local glob=pget(gx,gy-8*gscale)
 check("spit is drawn in front of an alien farther up its street",glob==7,"colour "..glob.." over the alien at t "..aliens[1].t)

 reset("play")
 send_alien(0,0)
 send_alien(1,0)
 clock=kinds.alien.walk+1.5
 update_aliens()
 check("an alien reaching the robot's street is body-blocked: a heart, but downed; one elsewhere leaks",robot.hp==max_hp-2 and stats.kills==1,"hp "..robot.hp..", downed "..stats.kills)

 reset("play")
 for i=1,10 do award("kills") end
 award("golds")
 award("civilians")
 award("civilians")
 start_payout(true)
 local lowest=panel_y
 for i=1,200 do
  update_payout()
  lowest=min(lowest,panel_y)
 end
 local expected=10*payouts.kills.each+payouts.golds.each+2*payouts.civilians.each+payouts.saved.each
 check("the payout adds up each row at level one and pays tickets on the curve",rows[5].value==expected and tickets==22,rows[5].value.." points, "..tickets.." tickets")
 check("and dispenses every one",dispensed==tickets and payout_done(),dispensed.." dispensed")
 check("its panel springs up past its rest and settles",lowest<payout_rest-1 and abs(panel_y-payout_rest)<0.5,"lowest "..lowest..", rests at "..panel_y)
 reset("play")
 start_payout(false)
 check("a run with nothing pays one ticket",tickets==1,tickets.." tickets")
 local curve=""
 for share in all({1,0.99,0.5}) do
  stats.kills_tickets=perfect_points*share
  start_payout(false)
  curve..=tickets.." "
 end
 check("tickets rise exponentially to 500 for a perfect run only",curve=="500 490 166 ",curve)
 printh("ok screen")
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
