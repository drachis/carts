-- data.lua : everything the game is tuned by.
--
-- a table constructor costs about three tokens per field; a string
-- costs one however long it is. so all data lives in strings that
-- are parsed once at boot, and adding a unit, building, legend or
-- wrath level is a new line here rather than new code.

-- lines of comma separated values. the first line names the fields
-- and the first field is the row's name. rows are stored both in
-- order and by name; empty cells are left nil.
function parse_table(text)
 local rows,fields={}
 for line in all(split(text,"\n")) do
  local values=split(line)
  if not fields then
   fields=values
  elseif line!="" then
   local row={}
   for i,field in ipairs(fields) do
    if values[i]!="" then row[field]=values[i] end
   end
   add(rows,row)
   rows[row.name]=row
  end
 end
 return rows
end

-- lines of key=value (or one line, with another separator)
function parse_record(text,separator)
 local record={}
 for line in all(split(text,separator or "\n")) do
  local pair=split(line,"=")
  if pair[2] then record[pair[1]]=pair[2] end
 end
 return record
end

-- a cell may hold a list: "a/b/c". an empty cell is an empty list.
function list(cell)
 return cell and split(cell,"/") or {}
end

-- ground tile sprites. the burnt form of a tile is 16 ids later and
-- its fuel is in its sprite flags (see gen_gfx.py, world.lua).
tile=parse_record[[
grass=1
flowers=2
tree=3
wheat=4
road=5
water=6
bridge=7
stump=19
rubble=21
]]

sound=parse_record[[
breath=0
roar=1
crash=2
hurt=3
die=4
fanfare=6
eat=8
alarm=9
coin=10
wings=11
]]

config=parse_record[[
max_units=100
max_particles=320
alarm_range=110
fireproof=0.35
guardian_at=0.6
combo_frames=120
max_multiplier=5
fury_frames=240
nova_range=56
coin_value=2
reel_frames=45
battle_rush=4
lull_frames=600
]]

-- the dragon's ages, from the whelp it starts as (dragon_stats) to
-- a calamity. it grows by eating: every unit has a `meal` value,
-- and sheep are by far the best. it comes of age when it has eaten
-- that many meals' worth since the last age, and gains the stats
-- listed, added to its own.
--  size scales its whole body, its reach and its jaws.
--  weight is heft: it shakes the ground with each wingbeat,
--   crushes what it flies over, shrugs off blows, deepens its
--   roar and makes the fearful flee at the sight of it.
--  less accel and turn_rate with more friction is momentum: the
--   same top speed, but slow to gather and slow to shed.
ages=parse_table[[
name,meals,stats
whelp,0
drake,40,size=0.4/weight=1/max_hp=60/hp=60/max_fire=20/accel=-0.075/breath_accel=-0.04/friction=0.025/turn_rate=-0.022/breath_range=14/breath_speed=0.75/breath_arc=0.015/breath_flames=1.5/breath_damage=0.95/charge_damage=20/bite_damage=10/charge_speed=0.5
wyrm,110,size=0.4/weight=1/max_hp=60/hp=60/max_fire=20/accel=-0.075/breath_accel=-0.04/friction=0.025/turn_rate=-0.022/breath_range=14/breath_speed=0.75/breath_arc=0.015/breath_flames=1.5/breath_damage=0.95/charge_damage=20/bite_damage=10/charge_speed=0.5
great wyrm,200,size=0.4/weight=1/max_hp=60/hp=60/max_fire=20/accel=-0.075/breath_accel=-0.04/friction=0.025/turn_rate=-0.022/breath_range=14/breath_speed=0.75/breath_arc=0.015/breath_flames=1.5/breath_damage=0.95/charge_damage=20/bite_damage=10/charge_speed=0.5
calamity,320,size=0.4/weight=1/max_hp=70/hp=70/max_fire=20/accel=-0.075/breath_accel=-0.04/friction=0.025/turn_rate=-0.022/breath_range=14/breath_speed=0.75/breath_arc=0.015/breath_flames=1.5/breath_damage=0.95/charge_damage=20/bite_damage=10/charge_speed=0.5
]]

-- razing a settlement spins the reel and lands on one of these.
-- each stat is added to the dragon's, for the rest of the game.
boons=parse_table[[
name,stats
long flame,breath_range=10/breath_speed=0.5
wide maw,breath_arc=0.025
swift wings,accel=0.1/breath_accel=0.05
iron scales,max_hp=25/hp=25
deep lungs,max_fire=30/fire=30
hot blood,regen=0.04
battering ram,charge_damage=15/bite_damage=10
]]

-- called out when a combo reaches this many hits
streaks=parse_record[[
10=rampage!
25=carnage!
45=massacre!
70=apocalypse!
]]

-- laid over the dragon's stats while an inferno lasts. rage
-- multiplies the breath's power (its reach, speed and damage), so
-- an inferno is half as strong again whatever the dragon's age.
fury_stats=[[
body=10
wing=9
flame=1,13,12,12,7
rage=1.5
breath_cost=0
charge_recover=20
]]

-- the dragon starts each game as a copy of this: a whelp. anything
-- here can be changed in play (ages, boons, fury) without new code.
-- flight is shmup-tight: top speed is accel/(1-friction), reached
-- in a few frames. mercy is the frames of safety after a hit.
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

-- ai names a function in unit_ai (units.lua). meal is the health
-- the dragon gains when the unit dies. fire_taken scales
-- breath damage; at or below config.fireproof a unit never ignites.
-- ranged units hold at range and back off inside range*keep_away.
-- color recolors the legend sprite's gold. the brave (1) stand
-- against the dragon's roar and are too much to swallow in passing;
-- the rest (0) flee from it and can be snapped up. a melee unit with a
-- knock throws the dragon back that hard when it lands a blow.
-- anything with a color is a named boss: it gets a health bar, and
-- a fanfare when it falls.
unit_specs=parse_table[[
name,sprite,hp,speed,damage,cooldown,fire_taken,score,meal,brave,ai,range,keep_away,shot,color,knock,volley
serf,64,3,0.5,1,30,1,5,1,0,melee
archer,65,4,0.45,2,80,1,10,1,0,ranged,70,0.4,arrow,,,3
knight,66,12,0.8,4,30,0.5,25,3,1,melee,,,,,7
champion,67,20,0.5,4,90,0.3,50,3,1,ranged,80,0.4,holy,,,3
ballista,69,15,0.2,8,120,0.7,40,0,1,ranged,100,0,bolt
catapult,70,15,0.2,12,150,0.7,40,0,1,ranged,110,0,rock
sheep,71,1,0.3,0,0,1,0,10,0,sheep
lancer,72,18,1.3,5,40,0.5,60,4,1,legend,,,,,9
merlin,73,220,0.6,6,70,0.3,800,40,1,ranged,90,0.6,arcane,12,,10
sir gawain,68,60,1,6,40,0.3,500,30,1,legend,,,,11,10
sir percival,68,80,1,6,40,0.3,500,30,1,legend,,,,14,10
sir galahad,68,100,1,6,40,0.3,500,30,1,legend,,,,7,10
sir lancelot,68,120,1,6,40,0.3,500,30,1,legend,,,,13,10
king arthur,68,140,1,10,40,0.3,500,30,1,legend,,,excalibur,10,12,8
]]

-- size 0 draws a streak, otherwise a ball of that radius. a lobbed
-- shot ignores speed and lands on its target after `life` frames.
-- fan is the angle between the shots of a volley. shots are slow
-- enough to dodge, and come in two kinds: wooden ones (orange)
-- burn up in the dragon's breath, holy ones (blue) do not.
shot_specs=parse_table[[
name,speed,color,size,life,sound,fan,burns,lob
arrow,1.5,9,0,90,5,0.04,1
holy,1.1,12,2,120,5,0.07
bolt,3,9,0,60,5,0,1
excalibur,1.6,12,2,90,5,0.125
arcane,1.2,14,2,110,5,0.1
rock,0,5,2,50,7,0,,1
]]

-- size is in tiles. spawns is who answers the alarm, survivor who
-- runs out burning when it falls, guardian the boss that rides out
-- when it is badly hurt. razing a goal building wins the game. a
-- ward building keeps every `warded` settlement (camelot) safe from
-- all harm while it stands: the town churches are the spine of a
-- run, the villages its side roads.
building_specs=parse_table[[
name,sprite,size,hp,score,spawn_rate,spawns,survivor,guardian,goal,ward
hut,32,1,10,10,260,serf,serf
house,33,1,18,25,200,serf,serf
tower,34,1,50,50,170,archer
church,36,2,100,120,420,champion,,,,1
keep,38,2,700,1000,150,knight/knight/archer/ballista/catapult,,king arthur,1
]]

-- fixed buildings are kind:x:y offsets from the centre; the rest
-- are scattered inside the radius. trees are cleared to `ground`.
-- when the dragon first comes near, `militia` units drawn from
-- `muster` turn out; razing every building pays the bounty. each
-- wheat field has a `flock` of sheep. a warded (1) settlement
-- cannot be harmed while any ward stands elsewhere.
settlement_specs=parse_table[[
name,radius,ground,fields,flock,militia,bounty,warded,muster,fixed,buildings
lair,3,19,0,0,0,0,0
village,4,1,3,2,6,100,0,serf/serf/serf/archer,,house/hut/hut/hut/house/hut
town,5,1,3,2,10,300,0,serf/serf/archer/archer/knight,,church/tower/tower/house/house/house/house/house/house/hut/hut
camelot,6,1,0,0,14,1000,1,knight/knight/lancer/archer/champion,keep:-1:-1/tower:-4:-4/tower:3:-4/tower:-4:3/tower:3:3,church/tower/tower/house/house/house/house/house
]]

-- the realm is a 3x3 grid of kind:name settlements, read left to
-- right, top to bottom.
realm=split"lair:the lair,village:ashford,village:millbrook,village:thornby,town:oakhampton,town:harrowgate,village:dunmere,town:wexcombe,camelot:camelot"

-- wrath rises with score (kept in tens, so 200 here is 2000 on
-- screen). each level has its own reinforcements and may send a
-- legend. the last level is out of reach of score alone: it comes
-- when the final ward breaks, and brings merlin.
wrath_levels=parse_table[[
name,score,legend,pool
wary,0,,serf/serf/archer
alarmed,200,sir gawain,serf/archer/knight
mustering,700,sir percival,archer/knight/knight/champion
crusading,1600,sir galahad,knight/lancer/champion/ballista/catapult
desperate,3000,sir lancelot,knight/lancer/champion/champion/ballista/catapult
doomed,30000,merlin,lancer/lancer/knight/champion/champion/ballista/catapult
]]
