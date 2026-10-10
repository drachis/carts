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
sight_range=128
combo_frames=90
horde_size=14
raze_goal=0.6
muster_frames=40
legends=sir kay,sir gawain,merlin,king arthur
growth_rate=1.4
max_size=1.5
rally_at=0.5
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
drake,your charge carries further,accel=-0.15/breath_accel=-0.1/friction=0.06/sink=0.03/charge_frames=8/size=0.15/max_hp=20/hp=20/dread=24/breath_range=4/breath_damage=0.08/bite_damage=1
wyrm,stand your ground: nothing can hurt you,accel=-0.15/breath_accel=-0.1/friction=0.08/sink=0.04/guard=1/size=0.15/max_hp=20/hp=20/dread=12/breath_range=4/breath_damage=0.08/bite_damage=1/max_fire=15
great wyrm,your fire seeks them out,accel=-0.15/breath_accel=-0.1/friction=0.08/sink=0.05/storm=1/size=0.15/max_hp=25/hp=25/dread=12/breath_range=6/breath_damage=0.1/bite_damage=1/max_fire=15
]]


tiles=parse_record[[
w=1
h=8
X=6
B=37
.=39
T=9
g=10
]]

placed=parse_record[[
H=hovel
Q=barracks
S=sheep
P=pig
C=cow
s=serf
a=archer
k=knight
m=monk
l=ballista
+=heart
*=brimstone
]]

stamps=parse_table[[
name,rows
pasture,gSgTgSg
grove,TgTgT
hay,h:h
hut, hhh :hhhhh:w   w:  H w
barn,hhhhhhh:w     w:w C P w
shed,wwww:w+ w:w  w
store,wwww:w* w:w  w
tower, a  :XXX :XXX :XXX :XXX :XXX :XXXQ
church,  B  :  B  : BBB :BB.BB:B...B:B.m.X
hall,XXXXXXX:X.....X:X.....X:X.k.k.X
keep, a   a :XXXXXXX:X.....X:XXXXXXX:X.....X:X.....X:X.k.m.X
wall,BBB:BBB:BBB:BBB:BBB:BBB:BBB:BBB:BBB:XXX:XXX:XXX:XXX
]]

blocks=parse_table[[
name,stamps
hamlet,pasture+hut+hut+hay+grove+barn+shed
town,hut+hut+barn+tower+church+store+pasture+hut
castle,wall+tower+tower+hall+church+hut+store
keep,wall+tower+keep+hall+tower+shed
citadel,wall+keep+keep+tower+hall+wall+store
]]

hordes=parse_table[[
name,pool
the shire,serf/serf/serf/archer/archer/pikeman/bat
the town,serf/pikeman/archer/archer/archer/crossbowman/knight/bat/bat
the castle,pikeman/pikeman/archer/crossbowman/crossbowman/knight/monk/bat/bat
camelot,pikeman/knight/knight/crossbowman/crossbowman/monk/monk/ballista/bat/bat
]]

streaks=parse_record[[
8=rampage!
20=carnage!
40=massacre!
70=apocalypse!
110=ragnarok!
]]

growth="size=0.04/max_hp=6/hp=6/breath_damage=0.02/max_fire=4/bite_damage=0.25"

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
size=0.6
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
belly_goal=30
mercy=30
body=8
wing=2
flame=5,8,9,10,7
breath_range=44
breath_arc=0.1
breath_cost=1.5
breath_damage=0.25
breath_speed=3
breath_flames=4
charge_windup=7
charge_speed=4.5
charge_frames=12
charge_recover=24
bite_damage=2
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
serf,64,1,0.8,1,30,1,0.5,0,melee,,,,,4
pikeman,75,2,0.9,4,35,0.8,0.5,1,melee,,,,,13
archer,65,1,0.3,3,50,1,0.5,0,ranged,70,0.4,arrow
crossbowman,76,2,0.3,5,70,1,0.5,0,ranged,90,0.4,quarrel
knight,66,4,0.8,6,30,0.5,1,1,melee,,,,,26,,,,,,,,,1
monk,77,3,0.3,6,130,0.3,1,1,ranged,90,0.5,smite
bat,83,1,0.8,2,40,1,0.5,1,melee,,,,,3,,1
ballista,69,4,0,10,120,0.7,0,1,ranged,100,0,bolt
sheep,71,1,0.3,0,0,1,10,0,sheep
pig,82,1,0.4,0,0,1,8,0,sheep
cow,81,1,0.25,0,0,1,16,0,sheep
sir kay,96,36,1.2,4,40,0.5,30,1,legend,,,,9,30,,,,1,,16,,,1
sir gawain,98,72,1.3,8,40,0.5,30,1,legend,,,rebuke,11,30,5,,,1,,16,serf/pikeman/archer,,2
merlin,73,76,0.6,7,70,0.5,40,1,ranged,90,0.6,arcane,12,,5,1,,1,,,bat/bat/monk,12,3
king arthur,102,128,1.4,12,40,0.5,30,1,legend,,,excalibur,10,34,7,,,,1,16,knight/monk/crossbowman,14,4
hovel,55,1,0,0,140,0.3,0,1,spawner,,,,,,,1,,,,,serf/serf/archer
barracks,56,1,0,0,110,0.3,0,1,spawner,,,,,,,1,,,,,knight/pikeman/crossbowman
roost,57,1,0,0,120,0.3,0,1,spawner,,,,,,,1,,,,,bat
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
