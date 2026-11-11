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
   add(rows,row)
   rows[row.name]=row
  end
 end
 return rows
end

function parse_record(text,separator,into)
 local record=into or {}
 for line in all(split(text,separator or "\n")) do
  local pair=split(line,"=")
  if pair[2] then record[pair[1]]=pair[2] end
 end
 return record
end

parse_record([[
frames_per_beat=14.94
good_window=10
knock_per_damage=0.25
max_hp=4
horizon=40
titan_horizon=82
hill_bottom=100
max_sparks=200
fly_speed=0.024
start_gun=2
bell_bonus=200
idle_beats=4
surge=0.12
straddle=0.7
robot_spring=0.45
robot_damping=0.45
camera_lean=0.25
splash_reach=0.15
perfect_points=601
ticket_curve=2
top_tickets=500
payout_rest=24
row_frames=10
count_frames=8
total_frames=30
spring=0.35
damping=0.6
]],nil,_ENV)

kinds=parse_table[[
name,keys,bars,walk,bonus,harmless,body,rim,track,depth,sprite,penalty,size,weave
alien,123,0.5,8,0,,11,3,,,0,,1,
weaver,rty,0.5,8,0,,11,2,,,0,,1,2
brute,456,1,8,0,,3,11,,,0,,1.25
hulk,789,1.5,8,0,,3,1,,,0,,1.5
gold,zxc,2,,100,1,10,9,4,0.45,0,,1
civilian,jkl,99,4,0,1,11,3,,,1,50,1
]]

function sprite_sizes(text)
 local sizes={}
 for entry in all(split(text,"/")) do add(sizes,split(entry)) end
 return sizes
end
swarm_sprites=sprite_sizes"8,0,0/10,16,0/12,36,0/14,60,0/16,88,0/18,0,16/22,36,16/24,80,16/28,0,40/32,56,40"
civilian_sprites=sprite_sizes"8,64,84/12,64,72/16,48,72/24,104,72"

stage_music=split"0,6,8,16,6,22,26,30,32"
chime=split"34,36,38,41,43,46,48,50,53,55"
pillar_hues={[3]=split"8,9,10,7",[13]=split"12,13,7,1",[14]=split"11,3,10,7"}

guns=parse_table[[
name,colour,pattern,splash,sound,style
minigun,10,xxxxxxxx,,16,tracer
shock rifle,13,x.x.x.x.,,17,zap
rockets,9,x...x...,0.5,12,rocket
flak cannon,4,x.x.x...,,18,flak
plasma rifle,12,x.x.xxx.,,19,plasma
]]

for gun in all(guns) do
 gun.shots=#split(gun.pattern,"x")-1
 gun.damage=8/gun.shots
end

payouts=parse_table[[
name,each,label
kills,1,aliens downed
golds,30,golden aliens
bells,15,bells rung
titans,10,giants felled
civilians,-5,civilians hit
saved,25,city saved
]]

judgements=parse_table[[
name,colour,knock,points
perfect,7,1,10
late,10,0.5,5
]]
