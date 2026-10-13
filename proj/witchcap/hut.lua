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
-- one to the other in two thirds of a second. the hut is drawn side on
-- while turn is past 0.4 either way, and in between it shows its end
-- wall, face on, with its hips closer together. the knees bend by as
-- much as turn, so they swing through straight as it comes round.
--
-- a leg is a thigh and a shank, each `hut_bone` pixels long, meeting at a
-- knee worked out from where the hip and the ankle are. their pictures
-- are sprites, stretched along the bone with tline. tline reads the map,
-- so place_limbs() puts the two pictures in map rows 16..18, under the
-- forest: the thigh in column 0, the shank in column 1.

function place_limbs()
 for row=0,2 do
  mset(0,16+row,142+row*16)
  mset(1,16+row,143+row*16)
 end
end

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
 hut.turn+=mid(-0.05,hut.facing-hut.turn,0.05)
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

-- the limb picture in map column `column`, drawn from one joint to the
-- other at twice its width, as textured lines side by side. the joints
-- are moved to whole pixels and the lines are a whole pixel apart, along
-- x for an upright limb and along y for a level one, so every line
-- covers the same pixels of the picture and nothing shimmers as it moves.
function draw_limb(column,x0,y0,x1,y1)
 x0,y0,x1,y1=flr(x0),flr(y0),flr(x1),flr(y1)
 local dx,dy=x1-x0,y1-y0
 local long=max(abs(dx),abs(dy))
 -- a slanted limb is cut on the slant, so it takes more lines to be as thick
 local half=flr(8*sqrt(dx*dx+dy*dy)/long)
 local upright=abs(dy)>=abs(dx)
 for across=-half,half-1 do
  local shift_x,shift_y=upright and across or 0,upright and 0 or across
  tline(x0+shift_x,y0+shift_y,x1+shift_x,y1+shift_y,
   column+(across+half)/half/2,16,0,3/long)
 end
end

function draw_hut(camera_x)
 local x,turn=hut.x-camera_x,hut.turn
 local flipped,side_on=turn<0,abs(turn)>0.4
 -- the floor of the hut, which rides up and down a little as it goes
 -- and lifts as it turns
 local floor_y=47+sin(t()/2)*1.5+abs(turn)*3
 for foot in all(hut.feet) do
  local foot_x=foot.x-camera_x
  -- a stepping foot is lifted in an arc
  local ankle_y=ground_top(foot.x)-16+sin(foot.step/hut_step_frames/2)*14
  local hip_x,hip_y=x+foot.home*(side_on and 1 or 0.6),floor_y-4
  local dx,dy=foot_x-hip_x,ankle_y-hip_y
  local distance=sqrt(dx*dx+dy*dy)
  -- the knee stands off the line from hip to ankle by what the two
  -- bones have to spare, and bends backwards, as a hen's does
  local half=min(distance/2,hut_bone)
  local bend=sqrt(hut_bone*hut_bone-half*half)*turn
  local knee_x,knee_y=hip_x+dx/2-dy/distance*bend,hip_y+dy/2+dx/distance*bend
  draw_limb(0,hip_x,hip_y,knee_x,knee_y)
  draw_limb(1,knee_x,knee_y,foot_x,ankle_y)
  -- the foot sprite's ankle is 13 pixels in from its heel
  sspr(96,64,16,8,foot_x-(flipped and 19 or 13),ankle_y,32,16,flipped)
 end
 if side_on then
  sspr(0,64,48,20,x-48,floor_y-40,96,40,flipped)
 else
  sspr(48,64,32,20,x-32,floor_y-40,64,40)
 end
end
