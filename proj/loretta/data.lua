function parse_record(text,separator,into)
 local record=into or {}
 for line in all(split(text,separator or "\n")) do
  local pair=split(line,"=")
  if pair[2] then record[pair[1]]=pair[2] end
 end
 return record
end

parse_record([[
run_start=0.3
run_accel=0.05
idle_fric=0.1
skid_fric=0.18
air_accel=0.05
fall_accel=0.2
hover_accel=0.09
fall_max=3.2
jump_buffer=6
coyote_frames=8
paddle_lift=0.25
paddle_rise=-0.1
stomp_bounce=2.4
hurt_frames=90
knock_x=1.2
knock_y=1.8
bark_frames=14
bark_cool=24
bark_speed=2
drop_frames=10
idle_sit=240
pet_frames=60
pet_range=28
respawn_frames=50
hero_w=24
hero_h=14
max_hearts=3
squirrel_speed=0.35
camera_speed_change=0.12
camera_lookahead=32
camera_lookahead_speed=0.04
coin_points=1
bone_points=5
stomp_points=10
spook_points=5
heart_bonus=10
snd_jump=0
snd_land=1
snd_coin=2
snd_bark=3
snd_stomp=4
snd_hurt=5
snd_munch=6
snd_pet=7
snd_check=8
snd_paddle=9
snd_splash=10
snd_howl=11
snd_chitter=12
snd_over=13
snd_menu=14
snd_sit=15
]],nil,_ENV)

function parse_table(text)
 local rows,fields={}
 for line in all(split(text,"\n")) do
  local values=split(line)
  if not fields then
   fields=values
  elseif line!="" then
   local row={}
   row.__index=row
   for i,field in ipairs(fields) do
    if values[i]!="" then row[field]=values[i] end
   end
   rows[row.tile],rows[row.name]=row,row
  end
 end
 return rows
end

thing_specs=parse_table[[
name,tile,w,h,dx,dy,back
start,16,24,14,0,-6
sign,17,8,8,0,0,1
gate,18,8,48,0,-40,1
coin,19,12,12,-2,-4
bone,20,14,6,-3,1
squirrel,21,12,12,-2,-4
hydrant,22,10,14,-1,-6
neighbour,23,16,8,-4,0
]]

stat_names=split"speed,jump,bark,charm"
stat_colours=split"14,9,11,13"
stats=parse_record[[
speed=3
jump=3
bark=2
charm=4
]]

function apply_stats()
 run_max=0.85+stats.speed*0.15
 jump_a=2.4+stats.jump*0.15
 paddle_frames=12+stats.jump*6
 bark_reach=32+stats.bark*12
 pet_hearts=1+stats.charm\2
 pet_points=stats.charm*5
end
