function send_alien(lane,beat,gun)
 add(aliens,{lane=lane,born=beat,hp=gun and 1 or alien_hp,flash=0,t=-1,gun=gun})
end

function send_pickup(lane,beat)
 pickups_sent+=1
 send_alien(lane,beat,(pickups_sent-1)%(#guns-1)+2)
end

function update_aliens()
 for alien in all(aliens) do
  local beats=clock-alien.born
  local whole=flr(beats)
  alien.hop=beats-whole
  alien.t=(whole+min(1,alien.hop*3)-1)/walk_beats
  alien.flash=max(alien.flash-1)
  if alien.t>=1 then
   del(aliens,alien)
   if not alien.gun then hurt_robot(alien.lane) end
  end
 end
 sort_by_t(aliens)
end

function front_alien(lane)
 local front
 for alien in all(aliens) do
  if alien.lane==lane and alien.t>-0.05 then front=alien end
 end
 return front
end

function hit_alien(alien,amount,judgement)
 alien.hp-=amount
 alien.flash=6
 alien.born+=judgement.knock
 local x,y,scale=alien_centre(alien)
 burst(x,y,6,judgement.colour,2)
 if alien.hp<=0 then
  del(aliens,alien)
  local colour=alien.gun and guns[alien.gun].colour or 11
  burst(x,y,24,colour,3)
  ring(x,y,20*scale,colour)
  shake+=2
  sfx(3)
  if alien.gun then equip(alien.gun) end
 end
end

function alien_centre(alien)
 local x,y,scale=project(alien.lane,alien.t)
 return x,y-12*scale,scale
end

function draw_aliens(behind)
 for alien in all(aliens) do
  if (alien.t<0)==behind then
   local x,y,scale=project(alien.lane,alien.t)
   local size=24*scale
   local lift=alien.hop<0.34 and sin(alien.hop*1.5)*6*scale or 0
   if alien.gun then
    local half,width=8*scale,8*scale*abs(cos(clock/4))
    local cy=y-half+lift-4*scale
    rectfill(x-width,cy-half,x+width,cy+half,alien.flash>0 and 7 or guns[alien.gun].colour)
    rect(x-width,cy-half,x+width,cy+half,7)
   else
    if alien.flash>0 then
     for colour=1,15 do pal(colour,7) end
    end
    sspr(alien.hop<0.34 and 16 or 0,0,16,16,x-size/2,y-size+lift,size,size)
    pal()
   end
  end
 end
end
