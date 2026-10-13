-- effects.lua : sparks, the shake of the view, and the mushrooms that fly
-- from the witch's pockets into the pot.
--
-- a spark is a pixel with a speed and a life. a flight is a recipe slot
-- on its way to the cauldron: its frame counts up from below zero, so
-- that several leave one after another, to flight_frames, when it lands
-- and the slot is in the pot.

function reset_effects()
 sparks,flights,shake={},{},0
end

-- `count` sparks of a colour thrown out from a place, at up to `speed`
function burst(x,y,count,colour,speed)
 for i=1,count do
  local angle,pace=rnd(),rnd(speed)
  add(sparks,{
   x=x,y=y,vx=cos(angle)*pace,vy=sin(angle)*pace-0.5,
   life=20+rnd(20),colour=colour,
  })
 end
end

-- where the brew is: the mouth of the pot
function pot_mouth()
 return near(cauldron_x),clearing_row*8-13
end

function update_effects()
 shake=max(shake-1)
 for spark in all(sparks) do
  spark.x+=spark.vx
  spark.y+=spark.vy
  spark.vy+=0.04
  spark.life-=1
  if spark.life<0 then del(sparks,spark) end
 end
 for flight in all(flights) do
  flight.frame+=1
  if flight.frame>=flight_frames then
   del(flights,flight)
   flight.slot.state=2
   local x,y=pot_mouth()
   burst(x,y,8,11,0.9)
   sfx(2)
  end
 end
end

function draw_effects()
 for spark in all(sparks) do
  pset(spark.x,spark.y,spark.colour)
 end
 local pot_x,pot_y=pot_mouth()
 for flight in all(flights) do
  if flight.frame>0 then
   -- from her pocket to the pot in an arc
   local share=flight.frame/flight_frames
   spr(95+flight.slot.kind,
    flight.x+(pot_x-flight.x)*share-4,
    flight.y+(pot_y-flight.y)*share-4+sin(share/2)*20)
  end
 end
end
