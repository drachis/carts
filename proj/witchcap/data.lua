-- data.lua : tuning, as text parsed at boot. speeds are pixels a frame
-- at 60 frames a second.

function parse_record(text,separator,into)
 local record=into or {}
 for line in all(split(text,separator or "\n")) do
  local pair=split(line,"=")
  if pair[2] then record[pair[1]]=pair[2] end
 end
 return record
end

parse_record([[
run_speed=1.25
run_accel=0.15
jump_speed=3
gravity=0.15
coyote_frames=6
poison_frames=180
dance_pace=0.0333
dance_poisoned=0.1
level_wanted=1,2,3,4,5,5,5,5,5
level_imposters=0,2,4,7,10,13,17,17,17
level_seconds=60
level_par=20,35,45,55,60,60,55,50,45
broom_speed=3.2
broom_frames=40
broom_rest=240
broom_height=14
flight_frames=30
cauldron_x=500
view_drop=8
clearing_row=12
highest_row=11
lowest_row=13
hut_speed=0.9
hut_hips=6
hut_stride=64
hut_step_frames=16
hut_bone=32
hut_thigh=11
]],nil,_ENV)

-- the level_ rows are lists, one number for each of the nine levels: how
-- many mushrooms the recipe wants, how many imposters (other forms of
-- the wanted mushrooms' families) grow, and the par, a time in seconds
-- to beat. the rest of a forest's 22 mushrooms are of families the
-- recipe does not use, and plainly something else. every level has the
-- same clock, level_seconds. the pars are about twice what the bot in
-- tests/pace.lua takes on foot, stopping 3/4 of a second at each
-- mushroom (5 17 21 27 29 29 29 29 29 seconds), and less than twice for
-- the last three levels, which differ only in their pars.
level_wanted=split(level_wanted)
level_imposters=split(level_imposters)
level_par=split(level_par)
