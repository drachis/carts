-- hut.lua : baba yaga's hut, a giant in the backdrop that walks after the
-- witch on chicken legs. it is taller than the screen: its roof is off
-- the top, and what shows is its eave, its walls, its door and its legs.
-- it touches nothing; it is only company.
--
-- hut.x is its middle, in world pixels. each foot stays planted on the
-- ground until the hut has walked `hut_stride` pixels past it, then steps
-- ahead, one foot at a time. foot.step counts a step's frames down.
--
-- hut.facing is 1 or -1, the way it last walked. hut.turn follows it from
-- one to the other over a moment, and the hut is drawn as wide as turn is
-- large, so it swings round like a door.

function reset_hut()
 hut={x=cauldron_x-100,facing=1,turn=1,feet={}}
 for side=-1,1,2 do
  add(hut.feet,{x=hut.x+side*hut_stance,home=side*hut_stance,step=0})
 end
end

function update_hut()
 -- slower than the witch: she leaves it behind and it catches her up
 -- while she picks. it settles a little to her left, clear of the moon
 local walk=mid(-hut_speed,(witch.x-24-hut.x)/60,hut_speed)
 hut.x+=walk
 if abs(walk)>0.3 then hut.facing=sgn(walk) end
 hut.turn+=(hut.facing-hut.turn)/12
 for number,foot in ipairs(hut.feet) do
  local behind=hut.x+foot.home-foot.x
  if foot.step>0 then
   foot.x+=(foot.to_x-foot.x)/foot.step
   foot.step-=1
  elseif abs(behind)>hut_stride and hut.feet[3-number].step==0 then
   foot.step=hut_step_frames
   foot.to_x=foot.x+behind+sgn(behind)*hut_stride
  end
 end
end

function draw_hut(camera_x)
 local x,turn=hut.x-camera_x,hut.turn
 local flipped=turn<0
 -- the floor of the hut, which rides up and down a little as it goes
 local floor_y=40+sin(t()/2)*1.5
 for foot in all(hut.feet) do
  local foot_x=foot.x-camera_x
  -- a stepping foot is lifted in an arc
  local ankle_y=ground_top(foot.x)-16+sin(foot.step/hut_step_frames/2)*14
  local hip_x=x+foot.home*max(abs(turn),0.3)
  -- the knee bends backwards, as a hen's does
  local knee_x,knee_y=(hip_x+foot_x)/2-12*turn,(floor_y+10+ankle_y)/2
  for thickness=-1,1 do
   line(hip_x+thickness,floor_y+8,knee_x+thickness,knee_y,4)
   line(knee_x+thickness,knee_y,foot_x+thickness,ankle_y,9)
  end
  circfill(knee_x,knee_y,2,9)
  -- the foot sprite's ankle is 13 pixels in from its heel
  sspr(48,32,16,8,foot_x-(flipped and 19 or 13),ankle_y,32,16,flipped)
  sspr(64,32,8,8,hip_x-8,floor_y-2,16,16)
 end
 local width=abs(turn)*96
 sspr(0,32,48,16,x-width/2,floor_y-32,width,32,flipped)
end
