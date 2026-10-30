-- test_poses.lua : Loretta's poses as pictures, each checked to be the
-- state it shows: the sploot with her belly down (pose_sploot), sitting
-- pretty (pose_sit), her ears standing at rest at their length, and a film strip of her trot (gait_1..6).

cases={
 {
  name="a jump like a dog over a hurdle, a film strip",buttons={4},frames=60,every_frame=true,
  setup=function() arena(40) result.frame=0 end,
  each=function()
   result.frame+=1
   if result.frame%7==0 then dump_screen("hurdle_"..result.frame\7) end
  end,
  check=function() return true,"hurdle_1..8 dumped" end,
 },
 {
  name="turning round, her head swings through facing the camera",buttons={},frames=12,every_frame=true,
  setup=function() arena(40) hero.facing,result.frame,result.front=-1,0,false end,
  each=function()
   result.frame+=1
   if abs(hero.turn)<0.02 then result.front=true end
   if result.frame%3==0 then dump_screen("turn_"..result.frame\3) end
  end,
  check=function() return result.front and hero.turn<0,"passed the front "..tostr(result.front)..", turn "..hero.turn end,
 },
 {
  name="her ears stand up at rest, sweep back running and stay their length",buttons={},frames=60,
  setup=function() arena(16) end,
  each=function()
   local ear=hero.ears[2]
   local dx,dy=ear.x-ear.bx,ear.y-ear.by
   result.length=sqrt(dx*dx+dy*dy)
  end,
  check=function()
   local ear=hero.ears[2]
   result.rest=ear.x-ear.bx
   return ear.y<ear.by-8 and abs(result.length-ear_length)<0.1,"tip "..flr(ear.y-ear.by).."px above its base, "..flr(result.rest).." across, length "..result.length
  end,
 },
 {
  name="left alone she sploots, belly on the ground, hind legs out behind",buttons={},frames=idle_sit+60,
  setup=function() arena(40) end,
  check=function()
   _draw()
   dump_screen("pose_sploot")
   return hero.state=="sploot" and hero.sag>3,"state "..hero.state..", belly sag "..hero.sag
  end,
 },
 {
  name="sitting pretty, patted by a neighbour",buttons={3},frames=62,
  setup=function() arena(40) thing_at("neighbour",70,88) end,
  check=function()
   _draw()
   dump_screen("pose_sit")
   return hero.state=="sit","state "..hero.state
  end,
 },
 {
  name="a film strip of her trot",buttons={1},frames=50,every_frame=true,
  setup=function() arena(16) result.frame=0 end,
  each=function()
   result.frame+=1
   if result.frame>=32 and result.frame%3==2 then dump_screen("gait_"..(result.frame-29)\3) end
  end,
  check=function() return true,"gait_1..6 dumped" end,
 },
}
