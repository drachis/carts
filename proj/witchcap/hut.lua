-- hut.lua : baba yaga's hut, a giant in the backdrop that walks after the
-- witch on chicken legs. it is taller than the screen: its roof is off
-- the top, and what shows is its walls, its lit window and its legs. it
-- touches nothing; it is only company.
--
-- hut.x is its middle, in world pixels. each foot stays planted on the
-- ground until the hut has walked `hut_stride` pixels past it, then steps
-- ahead, one foot at a time. foot.step counts a step's frames down.

function reset_hut()
 hut={x=cauldron_x-100,feet={}}
 for side=-1,1,2 do
  add(hut.feet,{x=hut.x+side*hut_stance,home=side*hut_stance,step=0})
 end
end

function update_hut()
 -- slower than the witch: she leaves it behind and it catches her up
 -- while she picks. it settles a little to her left, clear of the moon
 hut.x+=mid(-hut_speed,(witch.x-24-hut.x)/60,hut_speed)
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
 local x=hut.x-camera_x
 for foot in all(hut.feet) do
  local foot_x=foot.x-camera_x
  -- a stepping foot is lifted in an arc
  local foot_y=ground_top(foot.x)-1+sin(foot.step/hut_step_frames/2)*14
  local hip_x=x+foot.home
  -- the knee bends backwards, as a hen's does
  local knee_x,knee_y=(hip_x+foot_x)/2-12,(30+foot_y)/2
  for thickness=-1,1 do
   line(hip_x+thickness,26,knee_x+thickness,knee_y,4)
   line(knee_x+thickness,knee_y,foot_x+thickness,foot_y,9)
  end
  -- three toes ahead and a spur behind
  line(foot_x-5,foot_y,foot_x+10,foot_y,9)
  line(foot_x,foot_y-1,foot_x+8,foot_y-3,9)
  line(foot_x,foot_y-1,foot_x-4,foot_y-3,9)
 end
 -- the top ten rows of the hut sprite, five times the size
 sspr(96,16,16,10,x-40,-22,80,50)
end
