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
snd_breath=0
snd_roar=1
snd_crash=2
snd_hurt=3
snd_die=29
snd_fanfare=6
snd_eat=32
snd_coin=10
snd_wings=11

max_particles=300
gravity=0.23
fall_speed=3.5
fireproof=0.35
sight_range=110
combo_frames=90
horde_size=5
belly_size=40
linger_frames=150
creep=0.4
crush=4
stagger_frames=90
buoyancy=0.12
summon_frames=210
storm_range=56
fury_frames=240
nova_range=48
burn_frames=40
spread_at=28
]],nil,_ENV)

ages=parse_table[[
name,tip,stats
whelp
drake,your charge breaks stone,accel=-0.15/breath_accel=-0.1/friction=0.06/sink=0.03/ram=1/size=0.25/max_hp=20/hp=20/dread=24/breath_range=4/breath_damage=0.3/bite_damage=4
wyrm,stand still to guard,accel=-0.15/breath_accel=-0.1/friction=0.08/sink=0.04/guard=1/size=0.25/max_hp=20/hp=20/dread=12/breath_range=4/breath_damage=0.3/bite_damage=4/max_fire=15
great wyrm,your fire seeks them out,accel=-0.15/breath_accel=-0.1/friction=0.08/sink=0.05/storm=1/size=0.3/max_hp=25/hp=25/dread=12/breath_range=6/breath_damage=0.4/bite_damage=4/max_fire=15
]]


streaks=parse_record[[
8=rampage!
20=carnage!
40=massacre!
70=apocalypse!
110=ragnarok!
]]

growth="size=0.06/max_hp=6/hp=6/breath_damage=0.08/max_fire=4/bite_damage=1"

body_shape=split"-5,3,-1,4,4,3,8,3,11,2"

fury_stats=[[
body=10
wing=9
flame=1,13,12,12,7
rage=1.5
breath_cost=0
charge_recover=20
]]

dragon_stats=[[
vx=0
vy=0
angle=0
facing=1
hp=40
max_hp=40
regen=0.02
fire=60
max_fire=60
fire_regen=0.3
inhale=0.06
power=1
rage=1
size=1
dread=0
snap=0
accel=1.5
breath_accel=1
recoil=0.02
kick=0.4
friction=0.6
turn_rate=0.14
run=1.5
sink=0.2
guard=0
storm=0
belly=0
mercy=30
body=8
wing=2
flame=5,8,9,10,7
breath_range=28
breath_arc=0.08
breath_cost=2
breath_damage=1.2
breath_speed=2
breath_flames=2
charge_windup=7
charge_speed=4.5
ram=0
charge_frames=12
charge_recover=40
bite_damage=8
windup=0
charge=0
charge_cooldown=0
charge_id=0
fire_delay=0
flash=0
calm=0
]]

unit_specs=parse_table[[
name,sprite,max_hp,speed,damage,reload,fire_taken,meal,brave,ai,range,keep_away,shot,color,knock,volley,flies,ward,grants,crown,size,pool,aura,shield
serf,64,2,0.8,1,30,1,2,0,melee,,,,,2
pikeman,75,5,0.9,4,35,0.8,3,1,melee,,,,,3
archer,65,4,0.3,3,80,1,2,0,ranged,70,0.4,arrow
crossbowman,76,5,0.3,5,110,1,2,0,ranged,90,0.4,quarrel
knight,66,14,0.8,6,30,0.5,4,1,melee,,,,,4,,,,,,,,,1
monk,77,10,0.3,6,130,0.3,3,1,ranged,90,0.5,smite
bat,83,2,0.8,2,40,1,1,1,melee,,,,,1,,1
ballista,69,15,0,10,120,0.7,0,1,ranged,100,0,bolt
sheep,71,1,0.3,0,0,1,10,0,sheep
pig,82,1,0.4,0,0,1,8,0,sheep
cow,81,2,0.25,0,0,1,16,0,sheep
sir kay,96,140,1.2,4,40,0.5,30,1,legend,,,,9,5,,,,1,,16,,,1
sir gawain,98,280,1.3,8,40,0.5,30,1,legend,,,rebuke,11,6,5,,,1,,16,serf/pikeman/archer,,2
merlin,73,420,0.6,7,70,0.5,40,1,ranged,90,0.6,arcane,12,,5,1,,1,,,bat/bat/monk,12,3
king arthur,102,500,1.4,12,40,0.5,30,1,legend,,,excalibur,10,8,7,,,,1,16,knight/monk/crossbowman,14,4
hovel,55,6,0,0,140,0.3,0,1,spawner,,,,,,,1,,,,,serf/serf/archer
barracks,56,14,0,0,110,0.3,0,1,spawner,,,,,,,1,,,,,knight/pikeman/crossbowman
roost,57,5,0,0,120,0.3,0,1,spawner,,,,,,,1,,,,,bat
]]

shot_specs=parse_table[[
name,speed,color,size,life,sound,fan,burns,lob,seek
arrow,1.5,9,0,90,5,0.04,1
quarrel,2.6,9,0,60,12,0,1
bolt,3,9,0,60,5,0,1
smite,0.9,11,2,150,14,0,,,1
arcane,1.2,14,2,110,22,0.1,,,1
excalibur,1.6,12,2,90,23,0.125
rebuke,2.2,10,1,50,25,0
]]

relic_specs=parse_table[[
name,sprite,text,stats
heart,95,a knight's heart,max_hp=10/hp=10
brimstone,68,brimstone,max_fire=15/fire=15/breath_range=3
]]
