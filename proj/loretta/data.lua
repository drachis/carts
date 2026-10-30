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
leg_stride=5
leg_bone=4.5
ear_length=10
ear_spring=0.14
ear_damp=0.82
ear_gravity=0.15
ear_flop=10
head_turn=0.13
head_turn_speed=0.03
tongue_link=1.1
tongue_damp=0.9
tongue_weight=0.4
belly_spring=0.12
belly_damp=0.82
belly_bounce=1.5
hurt_frames=90
bark_frames=14
bark_cool=24
bark_speed=2
drop_frames=10
idle_sit=240
pet_frames=120
pet_again=150
view_drop=16
pet_range=64
respawn_frames=50
hero_w=24
hero_h=14
max_hearts=3
squirrel_speed=0.35
squirrel_wake=150
squirrel_patrol=40
squirrel_flee=1.1
squirrel_run=120
squirrel_arc=40
squirrel_gap=56
pot=0
run_max=1.3
jump_a=2.85
bark_reach=56
pet_hearts=3
pet_points=20
squirrel_lag=0.07
squirrel_dash=3
chase=0
slide_speed=2.2
slide_fric=0.02
squirrel_far=240
squirrel_climb=0.8
squirrel_height=58
squirrel_wind=24
grab_reach=11
ear_rise=4
camera_speed_change=0.12
camera_margin=8
camera_dead=6
camera_lookahead=32
camera_lookahead_speed=0.04
coin_points=1
bone_points=5
heart_bonus=10
snd_jump=0
snd_land=1
snd_coin=2
snd_bark=3
snd_munch=6
snd_pet=7
snd_check=8
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
coin,19,6,6,1,1
bone,20,14,6,-3,1
squirrel,21,12,12,-2,-4
hydrant,22,10,14,-1,-6
neighbour,23,16,8,-4,0
theatre,24,8,8,0,8,1
bookshop,25,8,8,0,8,1
lamp,26,8,8,0,8,1
house,27,8,8,0,8,1
jacaranda,28,8,8,0,8,1
fern,29,8,8,0,8,1
tree,31,8,8,0,8,1
ferndell,68,8,8,0,8,1
craftsman,69,8,8,0,8,1
fence,70,8,8,0,8,1
trailsign,72,8,8,0,8,1
chaparral,73,8,8,0,8,1
splitrail,75,8,8,0,8,1
bench,84,8,8,0,8,1
monument,85,8,8,0,8,1
viewer,86,8,8,0,8,1
fred62,87,8,8,0,8,1
cafe,88,8,8,0,8,1
petshop,89,8,8,0,8,1
hollyhock,90,8,8,0,8,1
fountain,91,8,8,0,8,1
decor,92,8,8,0,8,1
]]

shapes={}
for name,text in pairs(parse_record[[
theatre=r 0 -64 87 0 13/r 0 -64 3 0 5/r 84 -64 87 0 5/r 0 -66 87 -64 6/r 9 -57 19 -47 9/r 68 -57 78 -47 1/r 36 -84 50 -46 5/b 36 -84 50 -46 9/t 42 -80 7 s/t 42 -72 7 t/t 42 -64 7 a/t 42 -56 7 r/r -4 -40 91 -26 7/b -4 -40 91 -26 9/t 21 -38 2 now/t 37 -38 2 playing/t 29 -32 8 loretta/r 30 -24 57 0 1/l 43 -24 43 0 5/r 6 -26 22 -6 6/r 8 -24 20 -8 14/r 65 -26 81 -6 6/r 67 -24 79 -8 15
bookshop=r 0 -48 79 0 5/r 0 -50 79 -48 2/r 16 -46 63 -38 2/t 30 -44 7 books/r 6 -22 50 -4 1/l 7 -13 49 -13 6/l 7 -5 49 -5 6/r 9 -20 10 -14 8/r 12 -19 13 -14 11/r 15 -21 17 -14 14/r 20 -18 21 -14 9/r 24 -20 26 -14 13/r 30 -19 31 -14 7/r 9 -12 11 -6 13/r 14 -11 15 -6 9/r 18 -12 19 -6 8/r 23 -10 25 -6 11/r 28 -12 29 -6 14/r 58 -26 71 0 1/r 61 -23 68 -14 9
lamp=r 3 -38 4 0 1/r 2 -2 5 0 1/c 4 -42 3 9/c 4 -42 2 15/c 4 -42 1 7
bungalow=r 50 -46 55 -32 15/r 0 -32 63 0 15/r 0 -3 63 0 5/r -4 -38 67 -32 8/l -4 -35 67 -35 2/l -4 -38 67 -38 2/c 31 -18 6 4/r 25 -18 37 0 4/c 33 -9 0 10/c 12 -20 6 1/r 6 -20 18 -8 1/c 12 -20 4 9/r 8 -20 16 -10 9/l 12 -24 12 -10 1/c 51 -20 6 1/r 45 -20 57 -8 1/c 51 -20 4 9/r 47 -20 55 -10 9/l 51 -24 51 -10 1/c 41 -20 1 10
jacaranda=r 3 -34 6 0 4/l 4 -34 -4 -46 4/l 5 -34 14 -48 4/c -3 -46 9 13/c 12 -51 10 13/c 3 -57 9 13/c 20 -44 7 13/c 0 -51 4 14/c 13 -56 3 14/c 18 -46 2 14/c 5 -60 2 14/p -15 -64 44 56 14
fern=l 4 0 -6 -5 3/l 4 0 -3 -11 11/l 4 0 2 -14 3/l 4 0 7 -14 11/l 4 0 12 -11 3/l 4 0 15 -5 11/l 4 0 -4 -9 11/l 4 0 13 -8 3
sycamore=r 6 -56 9 0 6/l 7 -40 -2 -52 6/l 8 -44 18 -58 6/r 6 -30 7 -22 13/r 8 -48 9 -40 13/c -2 -58 9 3/c 16 -62 11 3/c 6 -70 9 3/c 24 -52 7 3/c 2 -60 3 11/c 18 -66 3 11/c 22 -54 2 11
ferndell=r 3 -14 4 0 4/r -6 -26 13 -12 4/b -6 -26 13 -12 2/t -4 -24 15 fern/t -4 -18 15 dell
craftsman=r 34 -60 61 -56 4/r 24 -56 71 -52 4/r 14 -52 81 -48 4/r 4 -48 91 -44 4/l 34 -60 61 -60 2/l 24 -56 71 -56 2/l 14 -52 81 -52 2/r 43 -55 52 -49 9/r 0 -44 95 0 5/l 0 -44 95 -44 15/l 0 -38 95 -38 2/l 0 -32 95 -32 2/r 20 -31 75 -1 2/r 26 -24 40 -10 9/l 33 -24 33 -10 2/r 54 -26 64 -1 4/r 57 -23 61 -18 9/c 51 -26 1 10/r 16 -32 19 0 15/r 46 -32 49 0 15/r 76 -32 79 0 15/r 38 -3 58 0 6
fence=l 0 -9 63 -9 6/l 0 -4 63 -4 6/r 1 -12 2 0 6/r 7 -12 8 0 6/r 13 -12 14 0 6/r 19 -12 20 0 6/r 25 -12 26 0 6/r 31 -12 32 0 6/r 37 -12 38 0 6/r 43 -12 44 0 6/r 49 -12 50 0 6/r 55 -12 56 0 6/r 61 -12 62 0 6
trailsign=r -2 -14 -1 0 4/r 33 -14 34 0 4/r -4 -28 36 -14 4/b -4 -28 36 -14 2/t -1 -26 15 griffith/t 9 -20 15 park
chaparral=c 2 -3 5 3/c 10 -5 7 3/c 18 -3 5 3/c 6 -7 2 13/c 13 -8 2 13/c 19 -5 1 13/c 9 -3 1 5
splitrail=l 0 -10 55 -10 4/l 0 -5 55 -5 4/r 0 -12 1 0 4/r 27 -12 28 0 4/r 54 -12 55 0 4
bench=r 0 -8 23 -6 4/r 0 -14 23 -12 4/l 2 -12 2 -8 4/l 21 -12 21 -8 4/l 1 -6 1 0 1/l 22 -6 22 0 1
monument=r 0 -6 15 0 6/r 1 -8 14 -6 13/r 4 -50 11 -8 6/l 4 -50 4 -8 13/l 7 -40 7 -14 13/l 9 -30 9 -16 13/r 6 -54 9 -50 6/c 7 -57 2 10/l 7 -62 7 -60 10
observatory=c -31 26 9 5/c 39 26 9 5/c 4 13 18 13/c 4 13 17 5/r -14 13 22 26 6/r -41 26 49 47 6/r -41 44 49 47 13/l -36 29 -36 43 13/l -27 29 -27 43 13/l -18 29 -18 43 13/l -9 29 -9 43 13/l 0 29 0 43 13/l 9 29 9 43 13/l 18 29 18 43 13/l 27 29 27 43 13/l 36 29 36 43 13/c 4 36 5 1/r -1 36 9 47 1/r -6 18 -5 21 10/r 14 18 15 21 10
arch=r -16 8 -13 48 4/r 21 8 24 48 4/r -22 0 30 10 8/b -22 0 30 10 2/c -19 5 1 10/c 27 5 1 10
sign=r 3 -1 4 7 4/r -9 -15 16 -1 4/b -9 -15 16 -1 2/t -6 -13 15 los/t -6 -7 15 feliz
fred62=r 0 -30 71 0 15/r 0 -34 71 -30 8/l -6 -35 30 -46 8/l -6 -34 30 -45 8/l 30 -46 78 -35 8/l 30 -45 78 -34 8/r 6 -24 64 -10 1/r 8 -22 62 -12 9/l 22 -22 22 -12 2/l 38 -22 38 -12 2/l 54 -22 54 -12 2/r 66 -24 70 0 1/r 82 -52 84 0 5/r 74 -70 98 -52 8/b 74 -70 98 -52 10/t 78 -67 7 fred/t 82 -60 10 62
cafe=r 0 -28 39 0 4/r -3 -32 42 -28 2/r 4 -40 36 -33 4/t 12 -38 15 cafe/r 6 -22 20 -12 9/r 24 -14 36 -10 15/l 43 -20 57 -20 14/l 44 -21 56 -21 14/l 46 -22 54 -22 14/l 48 -23 52 -23 14/l 50 -20 50 -2 6/r 45 -8 55 -7 4/l 46 -7 46 0 4/l 54 -7 54 0 4/r 28 -3 34 0 6/r 29 -3 33 -2 12
petshop=r 0 -40 47 0 13/r 0 -42 47 -40 2/r 6 -38 41 -30 2/t 9 -36 7 pet/t 23 -36 7 shop/r 4 -24 30 -6 1/c 12 -15 2 7/c 9 -19 1 7/c 12 -20 1 7/c 15 -19 1 7/r 34 -26 44 0 4/r 18 -3 26 0 6/r 19 -3 25 -2 12
hollyhock=r 20 -36 43 -32 13/r -2 -32 65 -28 13/r 0 -28 63 0 15/l 0 -26 63 -26 5/l 0 -24 63 -24 5/r 8 -20 11 -6 1/r 20 -20 23 -6 1/r 40 -20 43 -6 1/r 52 -20 55 -6 1/r 28 -18 35 0 4
fountain=r 0 -14 7 0 6/r -1 -16 8 -14 5/l 4 -16 4 -19 6/l 5 -19 7 -18 12/r 9 -3 15 0 6/r 10 -3 14 -2 12
palm=r 4 -57 5 0 4/l 4 -57 -7 -50 3/l 5 -57 16 -50 3/l 4 -58 -4 -68 11/l 5 -58 13 -68 11/l 4 -60 4 -70 3/l 4 -57 -8 -56 11/l 5 -57 17 -56 11
orange=r 3 -32 5 0 4/c 4 -48 8 3/c -1 -41 4 3/c 9 -44 4 3/c 4 -60 4 11/c 1 -51 1 9/c 7 -37 1 9/c 4 -57 1 9/c 10 -48 1 9/c -1 -37 1 9
birdbath=r 2 -10 5 0 6/r -2 -12 9 -10 6/r -1 -12 8 -11 13/c 6 -14 1 4
agave=l 3 0 -3 -8 3/l 3 0 0 -10 11/l 4 0 4 -11 3/l 4 0 8 -10 11/l 4 0 11 -7 3/l 3 0 -5 -4 11
pot=r 0 -6 7 0 4/r -1 -7 8 -6 9/c 3 -11 4 11/c 1 -13 1 14/c 6 -12 1 14/c 3 -15 1 14
roses=c 3 -5 5 3/c 0 -7 2 14/c 6 -8 2 14/c 3 -10 1 14/c 8 -4 1 2
flamingo=l 3 0 3 -8 14/l 5 0 5 -7 14/c 4 -11 3 14/l 6 -13 7 -18 14/c 8 -19 1 14/l 9 -19 10 -18 0
viewer=l 3 -10 3 0 5/r 2 -2 4 0 5/r 0 -16 7 -10 1/r 6 -18 9 -15 1/l 1 -14 5 -14 6
]]) do
 shapes[name]={}
 for op in all(split(text,"/")) do add(shapes[name],split(op," ")) end
end

levels={split"9,0,1,0,1,13",split"1,3,0,10,1,14",split"0,2,1,2,3,12",split"0,10,3,4,5,8,11",split"4,5,8,10,4,5,15",split"4,5,6,5,6,7"}
level_names=split"hillhurst,barnsdall park,fern dell,griffith park,the trail,the observatory"
landmarks=split"dog bowl,olive lawn,trails cafe,dog park,water stop"
slot_kinds={house=split"bungalow,craftsman,cafe,bungalow,bookshop,craftsman",tree=split"jacaranda,sycamore,palm,orange",decor=split"birdbath,agave,pot,roses,flamingo"}
walls,roofs,cloths,skins,coin_frames=split"15,14,6,13",split"8,4,2,3",split"14,12,3,10,8,13",split"15,4,9",split"34,34,34,34,34,36,38,36"
praises=split"who's a sweet pup!,best dog on the block!,what a little loaf!,treat earned!,tail wags all round!,such a fine corgi!"


