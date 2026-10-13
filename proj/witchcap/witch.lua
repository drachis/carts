-- witch.lua : the player. x is her middle and y her feet, in pixels.
--
-- the ground is solid all the way down, so a single point at her feet is
-- enough to stop her at a step; branches never block, they only catch her
-- when she comes down onto them from above.

function reset_witch()
 witch={
  x=cauldron_x,y=ground_top(cauldron_x),vx=0,vy=0,facing=1,
  grounded=true,air_frames=0,jump_buffer=0,poison=0,
 }
end

function update_witch()
 local w=witch
 local top_speed=w.poison>0 and run_speed/2 or run_speed
 w.poison=max(w.poison-1)

 local direction=0
 if btn(0) then direction=-1 end
 if btn(1) then direction=1 end
 if direction==0 then
  w.vx*=0.8
 else
  w.facing=direction
  w.vx=mid(-top_speed,w.vx+direction*run_accel,top_speed)
 end
 local new_x=w.x+w.vx
 if ground_at(new_x+sgn(w.vx)*3,w.y-1) then
  w.vx=0
 else
  w.x=new_x
 end

 -- a jump pressed just before landing, or just after walking off an
 -- edge, still counts
 if btnp(4) then w.jump_buffer=6 end
 if w.jump_buffer>0 and w.air_frames<coyote_frames then
  w.vy=-jump_speed
  w.air_frames=coyote_frames
  w.jump_buffer=0
  sfx(0)
 end
 w.jump_buffer=max(w.jump_buffer-1)
 -- letting go early makes a short hop
 if not btn(4) and w.vy<-1 then w.vy=-1 end

 w.vy=min(w.vy+gravity,4)
 local old_y=w.y
 w.y+=w.vy
 w.grounded=false
 if w.vy>=0 then
  for side=-2,2,4 do
   local tile=tile_at(w.x+side,w.y)
   local tile_top=w.y\8*8
   if fget(tile,0) or fget(tile,1) and old_y<=tile_top then
    w.y,w.vy,w.grounded=tile_top,0,true
   end
  end
 end
 w.air_frames=w.grounded and 0 or min(w.air_frames+1,coyote_frames)
end

function draw_witch()
 local w=witch
 -- frame 0 stands, 1..4 walk, 5 rises and 6 falls
 local frame=0
 if not w.grounded then
  frame=w.vy<0 and 5 or 6
 elseif abs(w.vx)>0.2 then
  frame=1+w.x\5%4
 end
 -- a green face while the poison lasts
 if w.poison>0 then pal(15,11) end
 spr(32+frame*2,w.x-8,w.y-16,2,2,w.facing<0)
 pal(15,15)
end
