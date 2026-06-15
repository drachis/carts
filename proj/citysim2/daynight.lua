-- daynight.lua : day/night cycle via a draw-palette remap (pal), NOT a dither
-- overlay — PICO-8's fill transparency doesn't darken the map, but pal() does
-- (citysim1 lesson). night_pal() darkens every colour to a moodier one while
-- leaving lit-window white (7) bright, so the night city glows. render.lua
-- wraps the map/agents draw in night_pal()..pal().
-- api: day_phase, night_pal; reads sim `tick`, period p.day_frames.

-- 0=noon (brightest) .. 1=midnight (darkest). starts at noon (tick 0).
function day_phase()
 return (1-cos((tick or 0)/p.day_frames))/2
end

-- colour i -> darker i. index 7 (white) stays 7 so windows/lights glow.
local night_lut=split"1,1,1,2,5,5,7,2,4,9,3,13,1,2,4"
local eve_lut=split"1,2,3,4,5,13,7,8,9,9,3,13,13,2,4"

-- apply the dusk/night remap if it's dark enough (no-op at midday).
function night_pal()
 local dk=day_phase()
 local l=dk>0.62 and night_lut or (dk>0.34 and eve_lut)
 if l then for i=1,15 do pal(i,l[i]) end end
end
