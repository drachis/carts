-- hut.lua : baba yaga's hut, a giant in the backdrop that walks after the
-- witch on chicken legs. it is taller than the screen: its roof is off
-- the top, and what shows is its eave, its walls, its door and its legs.
-- it touches nothing; it is only company.
--
-- hut.x is its middle, in world pixels, and hut.travel how far it has
-- walked. a foot stays planted while the hut walks over it, and lifts
-- once in every `hut_stride` pixels of travel, the two feet half a stride
-- apart, so they come down in turn and never in the same place.
-- foot.step counts a step's frames down.
--
-- hut.facing is 1 or -1, the way it last walked. hut.turn follows it from
-- one to the other in two thirds of a second. the hut is drawn side on
-- while turn is past 0.4 either way, and in between it shows its front,
-- door forward, with its hips apart. the knees bend by as
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
 hut={x=cauldron_x-100,travel=0,facing=1,turn=1,feet={}}
 hut.body_x=hut.x
 -- it stands with one foot ahead of the other, and the two take their
 -- steps half a stride apart
 for number=1,2 do
  local side=number*2-3
  add(hut.feet,{
   x=hut.x+side*hut_stride/4,hip=side*hut_hips,
   lift_at=number*hut_stride/2,step=0,
  })
 end
end

function update_hut()
 -- slower than the witch: she leaves it behind and it catches her up
 -- while she picks. it settles a little to her left, clear of the moon
 local walk=mid(-hut_speed,(witch.x-24-hut.x)/60,hut_speed)
 hut.x+=walk
 hut.travel+=abs(walk)
 if abs(walk)>0.3 then hut.facing=sgn(walk) end
 hut.turn+=mid(-0.05,hut.facing-hut.turn,0.05)
 for number,foot in ipairs(hut.feet) do
  -- where this foot belongs when the hut is standing
  local standing_x=hut.x+foot.hip*2
  if foot.step>0 then
   foot.x+=(foot.to_x-foot.x)/foot.step
   foot.step-=1
  elseif hut.travel>=foot.lift_at then
   -- each foot lifts once for every stride the hut walks, and swings to
   -- where it will be as far ahead on landing as it was behind on lifting
   foot.lift_at+=hut_stride
   foot.step=hut_step_frames
   foot.to_x=hut.x+sgn(walk)*(hut_stride+abs(walk)*hut_step_frames)/2
  elseif abs(walk)<0.2 and abs(foot.x-standing_x)>10
   and hut.feet[3-number].step==0 then
   -- once it has stopped it brings its feet back under itself
   foot.step=hut_step_frames
   foot.to_x=standing_x
  end
 end
 -- its weight stays over its feet: the body moves over the foot that is
 -- planted while the other swings, and midway between them when both
 -- are down, so it sways forward with each step and never overhangs
 local first,second=hut.feet[1],hut.feet[2]
 local balance=(first.x+second.x)/2
 if first.step>0 then balance=second.x end
 if second.step>0 then balance=first.x end
 hut.body_x+=(balance-hut.body_x)/4
end

-- the limb picture in map column `column`, turned to lie from one joint
-- to the other, `thickness` pixels to either side of the bone. it is
-- drawn as textured lines across the limb at right angles to the bone,
-- one for each row of the picture's length and half a pixel apart so
-- that none are missed: a true turn, with no shear. the joints are moved
-- to whole pixels so that the picture does not crawl as it moves.
function draw_limb(column,thickness,x0,y0,x1,y1)
 x0,y0,x1,y1=flr(x0),flr(y0),flr(x1),flr(y1)
 local dx,dy=x1-x0,y1-y0
 local length=sqrt(dx*dx+dy*dy)
 local side_x,side_y=-dy/length*thickness,dx/length*thickness
 -- the picture is one tile wide, over as many pixels as a line has
 local across_picture=0.5/max(abs(side_x),abs(side_y))
 for along=0,length-0.5,0.5 do
  local x,y=x0+dx*along/length,y0+dy*along/length
  tline(x-side_x,y-side_y,x+side_x,y+side_y,
   column,16+along/length*3,across_picture,0)
 end
end

function draw_hut(camera_x)
 local x,turn=hut.body_x-camera_x,hut.turn
 local flipped,side_on=turn<0,abs(turn)>0.4
 -- the floor of the hut, which rides up and down a little as it goes
 -- and lifts as it turns
 local floor_y=45+sin(t()/2)*1.5+abs(turn)*3
 for foot in all(hut.feet) do
  local foot_x=foot.x-camera_x
  -- a stepping foot is lifted in an arc
  local ankle_y=ground_top(foot.x)+view_drop-16
   +sin(foot.step/hut_step_frames/2)*14
  -- side on, one hip is just behind the other; face on, they are apart
  local hip_x,hip_y=x+foot.hip*(side_on and 1 or 2.5),floor_y-4
  local dx,dy=foot_x-hip_x,ankle_y-hip_y
  local distance=sqrt(dx*dx+dy*dy)
  -- the knee stands off the line from hip to ankle by what the two
  -- bones have to spare, and bends backwards, as a hen's does
  local half=min(distance/2,hut_bone)
  local bend=sqrt(hut_bone*hut_bone-half*half)*turn
  local knee_x,knee_y=hip_x+dx/2-dy/distance*bend,hip_y+dy/2+dx/distance*bend
  draw_limb(0,hut_thigh,hip_x,hip_y,knee_x,knee_y)
  draw_limb(1,8,knee_x,knee_y,foot_x,ankle_y)
  -- the foot sprite's ankle is 13 pixels in from its heel
  sspr(96,64,16,8,foot_x-(flipped and 19 or 13),ankle_y,32,16,flipped)
 end
 -- the body, and over it the foot of the roof, made of the eave's own
 -- thatch drawn again a little narrower, up to the top of the screen
 if side_on then
  sspr(0,64,48,3,x-42,floor_y-52,84,12,flipped)
  sspr(0,64,48,20,x-48,floor_y-40,96,40,flipped)
 else
  sspr(48,64,32,3,x-27,floor_y-52,54,12)
  sspr(48,64,32,20,x-32,floor_y-40,64,40)
 end
end
