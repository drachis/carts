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

function list(cell)
 return cell and split(cell,"/") or {}
end

parse_record([[
tile_grass=1
tile_flowers=2
tile_tree=3
tile_wheat=4
tile_road=5
tile_water=6
tile_bridge=7
tile_rubble=21

snd_breath=0
snd_roar=1
snd_crash=2
snd_hurt=3
snd_die=29
snd_fanfare=6
snd_eat=32
snd_alarm=9
snd_coin=10
snd_wings=11

max_units=80
max_particles=320
alarm_range=110
fireproof=0.35
guardian_at=0.6
combo_frames=100
max_multiplier=9
combo_step=8
fury_frames=240
nova_range=56
coin_value=2
reel_frames=45
battle_rush=4
lull_frames=450
min_livestock=24
]],nil,_ENV)

ages=parse_table[[
name,meals,stats
whelp,0
drake,40,size=0.4/weight=1/max_hp=60/hp=60/max_fire=20/accel=-0.075/breath_accel=-0.04/friction=0.025/turn_rate=-0.022/breath_range=14/breath_speed=0.75/breath_arc=0.015/breath_flames=1.5/breath_damage=0.95/charge_damage=20/bite_damage=10/charge_speed=0.5/kick=0.5
wyrm,110,size=0.4/weight=1/max_hp=60/hp=60/max_fire=20/accel=-0.075/breath_accel=-0.04/friction=0.025/turn_rate=-0.022/breath_range=14/breath_speed=0.75/breath_arc=0.015/breath_flames=1.5/breath_damage=0.95/charge_damage=20/bite_damage=10/charge_speed=0.5/kick=0.5
great wyrm,200,size=0.4/weight=1/max_hp=60/hp=60/max_fire=20/accel=-0.075/breath_accel=-0.04/friction=0.025/turn_rate=-0.022/breath_range=14/breath_speed=0.75/breath_arc=0.015/breath_flames=1.5/breath_damage=0.95/charge_damage=20/bite_damage=10/charge_speed=0.5/kick=0.5
calamity,320,size=0.4/weight=1/max_hp=70/hp=70/max_fire=20/accel=-0.075/breath_accel=-0.04/friction=0.025/turn_rate=-0.022/breath_range=14/breath_speed=0.75/breath_arc=0.015/breath_flames=1.5/breath_damage=0.95/charge_damage=20/bite_damage=10/charge_speed=0.5/kick=0.5
cataclysm,420,size=0.4/max_hp=80/hp=80/max_fire=20/accel=-0.03/breath_accel=-0.02/friction=0.01/turn_rate=-0.008/breath_range=6/breath_speed=0.35/breath_flames=1/breath_damage=1/charge_damage=25/bite_damage=10/kick=0.3
world eater,560,size=0.4/max_hp=80/hp=80/max_fire=20/accel=-0.03/breath_accel=-0.02/friction=0.01/turn_rate=-0.008/breath_range=6/breath_speed=0.35/breath_flames=1/breath_damage=1/charge_damage=25/bite_damage=10/kick=0.3
god-wyrm,720,size=0.4/max_hp=80/hp=80/max_fire=20/accel=-0.03/breath_accel=-0.02/friction=0.01/turn_rate=-0.008/breath_range=6/breath_speed=0.35/breath_flames=1/breath_damage=1/charge_damage=25/bite_damage=10/kick=0.3
sun-eater,900,size=0.4/max_hp=90/hp=90/max_fire=20/accel=-0.03/breath_accel=-0.02/friction=0.01/turn_rate=-0.006/breath_speed=0.2/breath_flames=1/breath_damage=1/charge_damage=25/bite_damage=10/kick=0.3
doom of kings,1100,size=0.4/max_hp=90/hp=90/max_fire=20/accel=-0.03/breath_accel=-0.02/friction=0.01/turn_rate=-0.006/breath_speed=0.2/breath_flames=1/breath_damage=1/charge_damage=25/bite_damage=10/kick=0.3
]]

boons=parse_table[[
name,stats
long flame,breath_range=10/breath_speed=0.5
wide maw,breath_arc=0.025
swift wings,accel=0.1/breath_accel=0.05
iron scales,max_hp=25/hp=25
deep lungs,max_fire=30/fire=30
hot blood,regen=0.04
battering ram,charge_damage=15/bite_damage=10
nimble,turn_rate=0.02/accel=0.05
thick hide,mercy=10/max_hp=15/hp=15
bellows,inhale=0.03/fire_regen=0.2
spitfire,breath_flames=1/breath_damage=0.4
restless,charge_recover=-8/charge_speed=0.5
]]

streaks=parse_record[[
10=rampage!
25=carnage!
45=massacre!
70=apocalypse!
110=annihilation!
160=ragnarok!
220=the end of all things!
]]

body_shape=split"-4,4,0,5,6,3,10,3,13,2"

fury_stats=[[
body=10
wing=9
flame=1,13,12,12,7
rage=1.5
breath_cost=0
charge_recover=20
]]

dragon_stats=[[
x=84
y=84
vx=0
vy=0
angle=0
hp=50
max_hp=50
regen=0.04
fire=60
max_fire=60
fire_regen=0.3
inhale=0.06
power=1
rage=1
size=0.6
weight=0
snap=0
accel=0.8
breath_accel=0.4
recoil=0.12
kick=1.5
friction=0.72
turn_rate=0.14
mercy=20
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
charge_speed=5
charge_frames=12
charge_recover=45
charge_damage=12
bite_damage=10
windup=0
charge=0
charge_cooldown=0
charge_id=0
fire_delay=0
flash=0
calm=0
]]

unit_specs=parse_table[[
name,sprite,max_hp,speed,damage,reload,fire_taken,score,meal,brave,ai,range,keep_away,shot,color,knock,volley
serf,64,3,0.7,1,30,1,5,1,0,melee
pikeman,75,8,0.9,3,35,0.8,15,2,1,melee,,,,,6
archer,65,4,0.45,2,80,1,10,1,0,ranged,70,0.4,arrow,,,3
longbowman,93,5,0.4,2,120,1,20,1,0,ranged,100,0.5,arrow,,,5
crossbowman,76,5,0.4,5,110,1,15,1,0,ranged,90,0.4,quarrel
knight,66,12,1.3,6,30,0.5,25,3,1,melee,,,,,12
lancer,72,18,1.7,7,40,0.5,60,4,1,legend,,,,,16
paladin,78,35,1.2,9,40,0.4,90,4,1,legend,,,,,22
monk,77,10,0.5,7,130,0.3,35,2,1,ranged,90,0.5,smite
champion,67,20,0.5,6,90,0.3,50,3,1,ranged,80,0.4,holy,,,3
apprentice,94,14,0.5,6,110,0.4,60,3,1,ranged,85,0.5,hex,,,3
ballista,69,15,0.2,12,120,0.7,40,0,1,ranged,100,0,bolt
catapult,70,15,0.2,18,150,0.7,40,0,1,ranged,110,0,rock
trebuchet,79,25,0.15,26,220,0.7,70,0,1,ranged,140,0,boulder
sheep,71,1,0.3,0,0,1,0,10,0,sheep
pig,82,1,0.4,0,0,1,0,6,0,sheep
cow,81,2,0.25,0,0,1,0,18,0,sheep
sir kay,84,70,1.3,11,40,0.3,400,30,1,legend,,,,9,30
sir gawain,85,60,1.3,9,40,0.3,500,30,1,legend,,,,11,32
sir percival,86,80,1.3,13,40,0.3,500,30,1,legend,,,,14,38
sir galahad,87,100,1.3,18,40,0.3,500,30,1,legend,,,,7,44
the black knight,88,110,1.2,15,40,0.3,500,30,1,legend,,,,5,44
sir tristan,89,110,1.4,19,40,0.3,500,30,1,legend,,,,8,46
sir lancelot,90,120,1.3,23,40,0.3,500,30,1,legend,,,,13,50
mordred,91,150,1.4,26,40,0.3,600,30,1,legend,,,excalibur,2,56,6
morgan le fay,80,160,0.6,9,80,0.3,700,40,1,ranged,90,0.6,hex,2,,8
merlin,73,220,0.6,10,70,0.3,800,40,1,ranged,90,0.6,arcane,12,,10
king arthur,92,160,1.4,30,40,0.3,500,30,1,legend,,,excalibur,10,60,8
]]

shot_specs=parse_table[[
name,speed,color,size,life,sound,fan,burns,lob,seek
arrow,1.5,9,0,90,5,0.04,1
quarrel,2.6,9,0,60,12,0,1
bolt,3,9,0,60,5,0,1
holy,1.1,12,2,120,13,0.07
smite,0.9,11,2,150,14,0,,,1
hex,1.3,13,2,110,15,0.09,,,1
arcane,1.2,14,2,110,22,0.1,,,1
excalibur,1.6,12,2,90,23,0.125
rebuke,2.2,10,1,50,25,0
rock,0,5,2,50,7,0,,1
boulder,0,5,3,70,24,0,,1
]]

building_specs=parse_table[[
name,sprite,tiles,max_hp,score,spawn_rate,spawns,survivor,guardian,goal,ward
hut,32,1,10,10,260,serf,serf
house,33,1,18,25,200,serf,serf
windmill,45,1,16,30,300,serf,serf
barn,40,1,14,20,500,cow/pig/pig/sheep,pig
tower,34,1,50,50,170,archer/archer/crossbowman
stable,41,1,40,60,240,lancer
barracks,98,2,110,80,200,pikeman/pikeman/knight/crossbowman
workshop,43,1,50,70,300,ballista/catapult/trebuchet
chapel,46,1,45,60,300,monk
wizard tower,100,2,130,150,260,apprentice,,morgan le fay
church,36,2,100,120,420,champion,,,,1
minster,96,2,160,300,300,monk/champion/paladin,,mordred
keep,38,2,700,1000,150,knight/paladin/longbowman/ballista/catapult,,king arthur,1
]]

settlement_specs=parse_table[[
name,radius,ground,fields,flock,militia,bounty,warded,muster,fixed,buildings
lair,3,19,0,0,0,0,0
hamlet,3,1,2,3,2,50,0,serf,,barn/hut/hut/windmill
village,4,1,3,2,4,100,0,serf/serf/serf/archer,,house/hut/barn/hut/house/hut/windmill
abbey,4,1,2,2,5,250,0,serf/serf/monk/pikeman,,chapel/chapel/hut/barn/hut/house
fort,4,1,0,0,10,500,0,knight/pikeman/pikeman/crossbowman/lancer,barracks:-1:-1/tower:-3:-3/tower:2:-3/tower:-3:2/tower:2:2,stable/workshop/barracks/house
town,5,1,3,2,10,300,0,serf/pikeman/archer/crossbowman/knight/lancer,,church/tower/tower/barracks/stable/house/house/house/house/house/hut/barn
camelot,6,1,0,0,14,1000,1,knight/knight/lancer/paladin/longbowman/champion,keep:-1:-1/tower:-4:-4/tower:3:-4/tower:-4:3/tower:3:3/wizard tower:0:-4/minster:-1:3,stable/barracks/workshop/tower/tower/house/house/house/house
]]

realm=split"lair:the lair,hamlet:ashford,abbey:st aldhelm's,village:millbrook,town:oakhampton:sir gawain,town:harrowgate:sir percival,fort:blackmoor:sir kay,town:wexcombe:sir galahad,camelot:camelot"

wrath_levels=parse_table[[
name,score,legend,pool
wary,0,,serf/serf/serf/archer
alarmed,350,,serf/serf/archer/pikeman/crossbowman/lancer
mustering,1100,the black knight,archer/longbowman/knight/lancer/lancer/monk/champion
crusading,2400,sir tristan,knight/lancer/paladin/champion/monk/ballista/catapult
desperate,4200,sir lancelot,knight/lancer/paladin/champion/apprentice/ballista/catapult/trebuchet
doomed,30000,merlin,lancer/paladin/paladin/champion/apprentice/ballista/catapult/trebuchet
]]
