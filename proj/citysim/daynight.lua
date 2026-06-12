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

-- night darkening via a draw-palette remap (pico-8's stand-in for a
-- multiply layer). chosen to keep contrast: roads stay grey, water goes
-- deep, walls cool off, and color 10 stays warm so windows glow.
local dn_dk={[1]=1,[2]=1,[3]=1,[4]=2,[5]=5,[6]=5,[7]=6,[8]=2,
 [9]=4,[10]=9,[11]=3,[12]=13,[13]=1,[14]=2,[15]=4}

function dn_dark()
 for c,d in pairs(dn_dk) do pal(c,d) end
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
