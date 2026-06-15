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

-- night LUT: dims structures a notch but KEEPS water blue (12), grass green (3),
-- and the lit windows/lamps (7,10) glowing, so the map stays readable after dark.
local night_lut=split"1,2,3,2,5,5,7,8,4,10,3,12,1,2,4"

-- traffic ebbs at night: ~1 at midday down to ~0.3 at midnight, so the roads
-- visibly breathe with the day/night cycle (sim scales commuter spawns by this).
function traffic_factor()
 return 1-0.7*day_phase()
end

-- two states only: day (no remap) or night. no morning/evening tween.
function night_pal()
 if day_phase()>0.5 then
  for i=1,15 do pal(i,night_lut[i]) end
 end
end
