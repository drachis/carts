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
leg_stride=5
paddle_gait=0.09
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
bungalow,27,8,8,0,8,1
jacaranda,28,8,8,0,8,1
fern,29,8,8,0,8,1
footbridge,30,8,8,0,8,1
sycamore,31,8,8,0,8,1
ferndell,68,8,8,0,8,1
craftsman,69,8,8,0,8,1
fence,70,8,8,0,8,1
mailbox,71,8,8,0,8,1
trailsign,72,8,8,0,8,1
chaparral,73,8,8,0,8,1
oldzoo,74,8,8,0,8,1
splitrail,75,8,8,0,8,1
bench,84,8,8,0,8,1
monument,85,8,8,0,8,1
viewer,86,8,8,0,8,1
]]

shapes={}
for name,text in pairs(parse_record[[
theatre=r 0 -64 87 0 13/r 0 -64 3 0 5/r 84 -64 87 0 5/r 0 -66 87 -64 6/r 9 -57 19 -47 9/r 68 -57 78 -47 1/r 36 -84 50 -46 5/b 36 -84 50 -46 9/t 42 -80 7 s/t 42 -72 7 t/t 42 -64 7 a/t 42 -56 7 r/r -4 -40 91 -30 7/b -4 -40 91 -30 9/t 6 -37 2 now/t 26 -37 8 good/t 48 -37 8 girl/r 30 -24 57 0 1/l 43 -24 43 0 5/r 6 -26 22 -6 6/r 8 -24 20 -8 14/r 65 -26 81 -6 6/r 67 -24 79 -8 15
bookshop=r 0 -48 79 0 5/r 0 -50 79 -48 2/r 16 -46 63 -38 2/t 30 -44 7 books/r 6 -22 50 -4 1/l 7 -13 49 -13 6/l 7 -5 49 -5 6/r 9 -20 10 -14 8/r 12 -19 13 -14 11/r 15 -21 17 -14 14/r 20 -18 21 -14 9/r 24 -20 26 -14 13/r 30 -19 31 -14 7/r 9 -12 11 -6 13/r 14 -11 15 -6 9/r 18 -12 19 -6 8/r 23 -10 25 -6 11/r 28 -12 29 -6 14/r 58 -26 71 0 1/r 61 -23 68 -14 9
lamp=r 3 -38 4 0 1/r 2 -2 5 0 1/c 4 -42 3 9/c 4 -42 2 15/c 4 -42 1 7
bungalow=r 50 -46 55 -32 15/r 0 -32 63 0 15/r 0 -3 63 0 5/r -4 -38 67 -32 8/l -4 -35 67 -35 2/l -4 -38 67 -38 2/c 31 -18 6 4/r 25 -18 37 0 4/c 33 -9 0 10/c 12 -20 6 1/r 6 -20 18 -8 1/c 12 -20 4 9/r 8 -20 16 -10 9/l 12 -24 12 -10 1/c 51 -20 6 1/r 45 -20 57 -8 1/c 51 -20 4 9/r 47 -20 55 -10 9/l 51 -24 51 -10 1/c 41 -20 1 10
jacaranda=r 10 -30 13 0 4/l 11 -30 3 -40 4/l 12 -30 21 -42 4/c 4 -40 9 13/c 19 -44 10 13/c 10 -50 9 13/c 27 -38 7 13/c 7 -44 4 14/c 20 -49 3 14/c 25 -40 2 14/c 12 -52 2 14/p -8 -56 44 56 14
fern=l 4 0 -6 -5 3/l 4 0 -3 -11 11/l 4 0 2 -14 3/l 4 0 7 -14 11/l 4 0 12 -11 3/l 4 0 15 -5 11/l 4 0 -4 -9 11/l 4 0 13 -8 3
footbridge=l 0 -10 47 -10 4/l 0 -9 47 -9 2/l 1 -10 1 0 4/l 23 -10 23 0 4/l 46 -10 46 0 4
sycamore=r 6 -56 9 0 6/l 7 -40 -2 -52 6/l 8 -44 18 -58 6/r 6 -30 7 -22 13/r 8 -48 9 -40 13/c -2 -58 9 3/c 16 -62 11 3/c 6 -70 9 3/c 24 -52 7 3/c 2 -60 3 11/c 18 -66 3 11/c 22 -54 2 11
ferndell=r 3 -14 4 0 4/r -6 -26 13 -12 4/b -6 -26 13 -12 2/t -4 -24 15 fern/t -4 -18 15 dell
craftsman=r 34 -60 61 -56 4/r 24 -56 71 -52 4/r 14 -52 81 -48 4/r 4 -48 91 -44 4/l 34 -60 61 -60 2/l 24 -56 71 -56 2/l 14 -52 81 -52 2/r 43 -55 52 -49 9/r 0 -44 95 0 5/l 0 -44 95 -44 15/l 0 -38 95 -38 2/l 0 -32 95 -32 2/r 20 -31 75 -1 2/r 26 -24 40 -10 9/l 33 -24 33 -10 2/r 54 -26 64 -1 4/r 57 -23 61 -18 9/c 51 -26 1 10/r 16 -32 19 0 15/r 46 -32 49 0 15/r 76 -32 79 0 15/r 38 -3 58 0 6
fence=l 0 -9 63 -9 6/l 0 -4 63 -4 6/r 1 -12 2 0 6/r 7 -12 8 0 6/r 13 -12 14 0 6/r 19 -12 20 0 6/r 25 -12 26 0 6/r 31 -12 32 0 6/r 37 -12 38 0 6/r 43 -12 44 0 6/r 49 -12 50 0 6/r 55 -12 56 0 6/r 61 -12 62 0 6
mailbox=r 3 -10 4 0 4/r 0 -17 9 -10 13/r 1 -18 8 -17 13/l 9 -16 9 -21 8/l 9 -21 11 -21 8
trailsign=r -2 -14 -1 0 4/r 33 -14 34 0 4/r -4 -28 36 -14 4/b -4 -28 36 -14 2/t -1 -26 15 griffith/t 9 -20 15 park
chaparral=c 2 -3 5 3/c 10 -5 7 3/c 18 -3 5 3/c 6 -7 2 13/c 13 -8 2 13/c 19 -5 1 13/c 9 -3 1 5
oldzoo=r 0 -34 63 0 5/r 0 -36 63 -34 13/l 0 -26 63 -26 13/l 0 -16 63 -16 13/c 15 -14 9 1/r 6 -14 24 0 1/c 47 -14 9 1/r 38 -14 56 0 1/l 9 -20 9 0 6/l 13 -22 13 0 6/l 17 -22 17 0 6/l 21 -20 21 0 6/l 41 -20 41 0 6/l 45 -22 45 0 6/l 49 -22 49 0 6/l 53 -20 53 0 6/c 31 -40 4 3/c 27 -38 3 3/c 59 -38 3 3
splitrail=l 0 -10 55 -10 4/l 0 -5 55 -5 4/r 0 -12 1 0 4/r 27 -12 28 0 4/r 54 -12 55 0 4
bench=r 0 -8 23 -6 4/r 0 -14 23 -12 4/l 2 -12 2 -8 4/l 21 -12 21 -8 4/l 1 -6 1 0 1/l 22 -6 22 0 1
monument=r 0 -6 15 0 6/r 1 -8 14 -6 13/r 4 -50 11 -8 6/l 4 -50 4 -8 13/l 7 -40 7 -14 13/l 9 -30 9 -16 13/r 6 -54 9 -50 6/c 7 -57 2 10/l 7 -62 7 -60 10
viewer=l 3 -10 3 0 5/r 2 -2 4 0 5/r 0 -16 7 -10 1/r 6 -18 9 -15 1/l 1 -14 5 -14 6
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
