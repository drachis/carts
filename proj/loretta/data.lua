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
theatre,24,8,8,0,8,1
bookshop,25,8,8,0,8,1
lamp,26,8,8,0,8,1
]]

shapes={}
for name,text in pairs(parse_record[[
theatre=r 0 -64 87 0 13/r 0 -64 3 0 5/r 84 -64 87 0 5/r 0 -66 87 -64 6/r 9 -57 19 -47 9/r 68 -57 78 -47 1/r 36 -84 50 -46 5/b 36 -84 50 -46 9/t 42 -80 7 s/t 42 -72 7 t/t 42 -64 7 a/t 42 -56 7 r/r -4 -40 91 -30 7/b -4 -40 91 -30 9/t 6 -37 2 now/t 26 -37 8 good/t 48 -37 8 girl/r 30 -24 57 0 1/l 43 -24 43 0 5/r 6 -26 22 -6 6/r 8 -24 20 -8 14/r 65 -26 81 -6 6/r 67 -24 79 -8 15
bookshop=r 0 -48 79 0 5/r 0 -50 79 -48 2/r 16 -46 63 -38 2/t 30 -44 7 books/r 6 -22 50 -4 1/l 7 -13 49 -13 6/l 7 -5 49 -5 6/r 9 -20 10 -14 8/r 12 -19 13 -14 11/r 15 -21 17 -14 14/r 20 -18 21 -14 9/r 24 -20 26 -14 13/r 30 -19 31 -14 7/r 9 -12 11 -6 13/r 14 -11 15 -6 9/r 18 -12 19 -6 8/r 23 -10 25 -6 11/r 28 -12 29 -6 14/r 58 -26 71 0 1/r 61 -23 68 -14 9
lamp=r 3 -38 4 0 1/r 2 -2 5 0 1/c 4 -42 3 9/c 4 -42 2 15/c 4 -42 1 7
]]) do
 shapes[name]={}
 for op in all(split(text,"/")) do add(shapes[name],split(op," ")) end
end

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
