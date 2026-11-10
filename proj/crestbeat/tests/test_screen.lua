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
 local lit=""
 for lane in all({-1,1,0}) do
  hit_spot(titan.spots[lane+2],1,judgements[1])
  lit..=lamps_lit().." "
 end
 check("one shot on each hot spot rings the bell",lit=="1 2 3 " and score==bell_bonus and titan.rung,"lamps "..lit.."score "..score)
 for spot in all(titan.spots) do spot.lit=nil end
 for spot in all(titan.spots) do hit_spot(spot,1,judgements[1]) end
 check("the bell rings only once a giant",stats.bells==1,stats.bells.." bells")
 reset("play")
 start_stage(3)
 hit_spot(titan.spots[1],1,judgements[1])
 hit_spot(titan.spots[1],1,judgements[1])
 check("a second shot on a lit spot puts the lamps out",lamps_lit()==0,"lamps "..lamps_lit())
 hit_spot(titan.spots[2],1,judgements[1])
 hit_spot(titan.spots[1],99,judgements[1])
 hit_spot(titan.spots[3],1,judgements[1])
 check("destroying a hot spot before the bell takes the bell away",stats.bells==0 and titan.bell_lost,stats.bells.." bells")

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
 local sx,sy=spot_xy(spot)
 local ox,oy=spot_xy(titan.spots[3])
 check("a closed street's shield is drawn, an open one's is not",pget(sx,sy+7)==12 and pget(ox,oy+7)!=12,"colours "..pget(sx,sy+7).." "..pget(ox,oy+7))

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
