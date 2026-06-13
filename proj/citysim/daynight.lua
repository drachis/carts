-- daynight.lua : cosmetic day/night cycle overlay

local dn_dk={[1]=1,[2]=1,[3]=1,[4]=2,[5]=5,[6]=5,[7]=6,[8]=2,
 [9]=4,[10]=9,[11]=3,[12]=13,[13]=1,[14]=2,[15]=4}

function dn_phase()
 local f=(frame%p.day_frames)/p.day_frames
 if f<0.5 then return "day"
 elseif f<0.7 then return "evening"
 else return "night" end
end

function dn_dark()
 for c,d in pairs(dn_dk) do pal(c,d) end
end

function draw_window_lights(x,y,kind,dens)
 if dn_phase()=="day" then return end
 for j=1,dens do
  pset(x*8+1+(x*3+j*2)%6, y*8+2+(y*5+j*3)%5, 10)
 end
end
