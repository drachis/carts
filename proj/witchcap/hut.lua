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
-- one to the other in two thirds of a second.
--
-- the hut is a box seen from three quarters on: its long side, and at
-- the end it is walking towards, its front, with the door and the skull,
-- narrowed by the angle. as it turns the front widens and the side
-- narrows, until at the middle of the turn the front is flat to the
-- camera; then the other side opens out behind it. the knees bend by as
-- much as turn, so they swing through straight as it comes round.
--
-- a leg is a thigh and a shank, each `hut_bone` pixels long, meeting at a
-- knee worked out from where the hip and the ankle are. they are drawn
-- solid, as rows of filled circles (draw_limb), so that nothing can show
-- through them and nothing shimmers when they move.

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

-- a limb from one joint to another, solid: a row of filled circles close
-- enough to run together, shrinking from one radius to the other. it is
-- drawn twice, first in `edge` and then a pixel smaller in `colour`,
-- which leaves it a dark outline.
function draw_limb(x0,y0,x1,y1,from_radius,to_radius,colour,edge)
 for pass=0,1 do
  for share=0,1,0.05 do
   circfill(x0+(x1-x0)*share,y0+(y1-y0)*share,
    from_radius+(to_radius-from_radius)*share-pass,
    pass==0 and edge or colour)
  end
 end
end

function draw_hut(camera_x)
 local x,turn=hut.body_x-camera_x,hut.turn
 local flipped,square=turn<0,abs(turn)
 -- the floor of the hut, which rides up and down a little as it goes
 -- and lifts as it turns
 local floor_y=45+sin(t()/2)*1.5+square*3
 for foot in all(hut.feet) do
  local foot_x=foot.x-camera_x
  -- a stepping foot is lifted in an arc
  local ankle_y=ground_top(foot.x)+view_drop-16
   +sin(foot.step/hut_step_frames/2)*14
  -- from the side one hip is just behind the other; from the front
  -- they are apart
  local hip_x,hip_y=x+foot.hip*(2.5-square*1.5),floor_y-4
  local dx,dy=foot_x-hip_x,ankle_y-hip_y
  local distance=sqrt(dx*dx+dy*dy)
  -- the knee stands off the line from hip to ankle by what the two
  -- bones have to spare, and bends backwards, as a hen's does
  local half=min(distance/2,hut_bone)
  local bend=sqrt(hut_bone*hut_bone-half*half)*turn
  local knee_x,knee_y=hip_x+dx/2-dy/distance*bend,hip_y+dy/2+dx/distance*bend
  -- a pink shank with a knob of a knee, and over it a thick brown
  -- thigh, feathered to a ragged hem at the knee
  draw_limb(knee_x,knee_y,foot_x,ankle_y+2,4,3,14,2)
  draw_limb(hip_x,hip_y,knee_x,knee_y,hut_thigh,6,4,2)
  for feather=-1,1 do
   line(knee_x+feather*4,knee_y,knee_x+feather*6,knee_y+7,4)
  end
  -- its toes: spread on the ground, half curled as it lifts and as it
  -- comes down, clenched in the air between. the three pictures are one
  -- under another, and the ankle is 13 pixels in from the heel.
  local through=foot.step/hut_step_frames
  local toes=0
  if through>0 then
   toes=(through>0.25 and through<0.75) and 16 or 8
  end
  sspr(96,64+toes,16,8,foot_x-(flipped and 19 or 13),ankle_y,32,16,flipped)
 end
 -- the body: its side, as wide as the turn leaves it, and its front,
 -- which is narrow at three quarters and full width when it faces the
 -- camera. the front is at the end the hut is walking towards.
 local side_width,front_width=76*square,64-40*square
 local left=x-(side_width+front_width)/2
 local side_x,front_x=left,left+side_width
 if flipped then
  side_x,front_x=left+front_width,left
 end
 -- over each, the foot of the roof: the eave's own thatch drawn again
 -- up to the top of the screen. each wall's picture has three columns
 -- at its ends that are empty on some row; the ends that meet are left
 -- off, so that the walls join at the corner with no gap.
 sspr(0,64,45,3,side_x,floor_y-52,side_width,12,flipped)
 sspr(0,64,45,20,side_x,floor_y-40,side_width,40,flipped)
 sspr(51,64,29,3,front_x,floor_y-52,front_width,12,flipped)
 sspr(51,64,29,20,front_x,floor_y-40,front_width,40,flipped)
end
