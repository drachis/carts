-- daynight.lua : cosmetic day/night cycle overlay

local dn_lit={
 [1]={evening=true,night=true},  -- residential
 [2]={evening=true},             -- commercial
 [3]={evening=true,night=true},  -- industrial
}

function dn_phase()
 local f=(frame%p.day_frames)/p.day_frames
 if f<0.5 then return "day"
 elseif f<0.7 then return "evening"
 else return "night"
 end
end

function draw_night()
 local ph=dn_phase()
 if ph=="day" then return end
 if ph=="night" then
  fillp(0xa5a5+0x.8)
 else
  fillp(0x7f7f+0x.8)
 end
 rectfill(0,8,127,127,0)
 fillp()
end

function draw_window_lights(x,y,kind,dens)
 local ph=dn_phase()
 if ph=="day" then return end
 local lt=dn_lit[kind]
 if lt and lt[ph] then
  for j=1,dens do
   pset(x*8+1+(x*3+j*2)%6, y*8+2+(y*5+j*3)%5, 10)
  end
 end
end
