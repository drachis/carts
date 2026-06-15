-- daynight.lua : a day/night cycle. cheap dithered darkness over the world,
-- scaled by time of day (sim's `tick` clock, period p.day_frames). the zone
-- sprites' lit windows show through the dither, so the night city glows.
-- api: draw_night, day_phase; runs in SCREEN space, after draw_world.

-- 0=noon (brightest) .. 1=midnight (darkest). starts at noon (tick 0).
function day_phase()
 return (1-cos((tick or 0)/p.day_frames))/2
end

function draw_night()
 local dk=day_phase()
 if dk<0.22 then return end          -- broad daylight: no overlay
 -- pick a denser black dither as it gets darker; ".1" = transparent gaps.
 if dk<0.45 then fillp(0b0000100000000010.1)
 elseif dk<0.7 then fillp(0b0101000010100000.1)
 else fillp(0b0101101001011010.1) end
 rectfill(0,7,127,127,0)
 fillp()
end
