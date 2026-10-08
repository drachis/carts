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
]]

config=parse_record[[
max_units=60
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
]]

-- razing a settlement spins the reel and lands on one of these.
-- each stat is added to the dragon's, for the rest of the game.
boons=parse_table[[
name,stats
long flame,breath_range=10/breath_speed=0.5
wide maw,breath_arc=0.025
swift wings,accel=0.05
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

-- laid over the dragon's stats while an inferno lasts
fury_stats=[[
body=10
wing=9
flame=1,13,12,12,7
accel=0.4
breath_range=64
breath_arc=0.14
breath_cost=0
breath_damage=4
breath_speed=3.8
breath_flames=6
charge_recover=20
]]

-- the dragon starts each game as a copy of this, so anything here
-- can be changed in play (upgrades, curses) without new code.
dragon_stats=[[
x=84
y=84
vx=0
vy=0
angle=0
hp=100
max_hp=100
regen=0.04
fire=100
max_fire=100
fire_regen=0.3
inhale=0.06
power=1
accel=0.3
breath_accel=0.12
friction=0.88
turn_rate=0.04
body=8
wing=2
flame=5,8,9,10,7
breath_range=44
breath_arc=0.09
breath_cost=2
breath_damage=2
breath_speed=2.5
breath_flames=4
charge_windup=7
charge_speed=6
charge_frames=12
charge_recover=45
charge_damage=30
bite_damage=40
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
-- color recolors the legend sprite's gold. a melee unit with a
-- knock throws the dragon back that hard when it lands a blow.
unit_specs=parse_table[[
name,sprite,hp,speed,damage,cooldown,fire_taken,score,meal,ai,range,keep_away,shot,color,knock
serf,64,3,0.5,1,30,1,5,2,melee
archer,65,4,0.45,2,70,1,10,2,ranged,60,0.4,arrow
knight,66,12,0.8,4,30,0.5,25,3,melee,,,,,4
champion,67,20,0.5,4,90,0.3,50,3,ranged,70,0.4,holy
ballista,69,15,0.2,8,120,0.7,40,0,ranged,100,0,bolt
catapult,70,15,0.2,12,150,0.7,40,0,ranged,110,0,rock
sheep,71,1,0.3,0,0,1,0,10,sheep
sir gawain,68,60,1,6,40,0.3,500,30,legend,,,,11,6
sir percival,68,80,1,6,40,0.3,500,30,legend,,,,14,6
sir galahad,68,100,1,6,40,0.3,500,30,legend,,,,7,6
sir lancelot,68,120,1,6,40,0.3,500,30,legend,,,,13,6
king arthur,68,140,1,10,40,0.3,500,30,legend,,,excalibur,10,7
]]

-- size 0 draws a streak, otherwise a ball of that radius. a lobbed
-- shot ignores speed and lands on its target after `life` frames.
shot_specs=parse_table[[
name,speed,color,size,life,sound,lob
arrow,2.2,4,0,60,5
holy,1.6,10,2,60,5
bolt,4.5,7,0,60,5
excalibur,3,12,2,50,5
rock,0,5,2,50,7,1
]]

-- size is in tiles. spawns is who answers the alarm, survivor who
-- runs out burning when it falls, guardian the boss that rides out
-- when it is badly hurt. razing a goal building wins the game.
building_specs=parse_table[[
name,sprite,size,hp,score,spawn_rate,spawns,survivor,guardian,goal
hut,32,1,10,10,260,serf,serf
house,33,1,18,25,200,serf,serf
tower,34,1,30,50,170,archer
church,36,2,60,120,420,champion
keep,38,2,200,1000,150,knight/knight/archer/ballista/catapult,,king arthur,1
]]

-- fixed buildings are kind:x:y offsets from the centre; the rest
-- are scattered inside the radius. trees are cleared to `ground`.
-- when the dragon first comes near, `militia` units drawn from
-- `muster` turn out; razing every building pays the bounty.
settlement_specs=parse_table[[
name,radius,ground,fields,militia,bounty,muster,fixed,buildings
lair,3,19,0,0,0
village,4,1,3,6,100,serf/serf/serf/archer,,house/hut/hut/hut/house/hut
town,5,1,3,10,300,serf/serf/archer/archer/knight,,church/tower/tower/house/house/house/house/house/house/hut/hut
camelot,6,1,0,14,1000,knight/knight/archer/champion,keep:-1:-1/tower:-4:-4/tower:3:-4/tower:-4:3/tower:3:3,church/tower/tower/house/house/house/house/house
]]

-- the realm is a 3x3 grid of kind:name settlements, read left to
-- right, top to bottom.
realm=split"lair:the lair,village:ashford,village:millbrook,village:thornby,town:oakhampton,town:harrowgate,village:dunmere,town:wexcombe,camelot:camelot"

-- wrath rises with score (kept in tens, so 200 here is 2000 on
-- screen). each level has its own reinforcements and may send a
-- legend.
wrath_levels=parse_table[[
name,score,legend,pool
wary,0,,serf/serf/archer
alarmed,200,sir gawain,serf/archer/knight
mustering,700,sir percival,archer/knight/knight/champion
crusading,1600,sir galahad,knight/knight/champion/ballista/catapult
desperate,3000,sir lancelot,knight/champion/champion/ballista/catapult/catapult
]]
