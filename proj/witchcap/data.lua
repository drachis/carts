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
level_seconds=60
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
hut_thigh=13
]],nil,_ENV)
