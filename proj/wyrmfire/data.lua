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

-- lines of key=value
function parse_record(text)
 local record={}
 for line in all(split(text,"\n")) do
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
]]

config=parse_record[[
max_units=45
max_particles=320
alarm_range=110
fireproof=0.35
guardian_at=0.6
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
fire_regen=0.5
accel=0.3
breath_accel=0.12
friction=0.88
turn_rate=0.04
breath_range=44
breath_arc=0.09
breath_cost=0.9
breath_damage=2
charge_speed=5
charge_frames=12
charge_recover=45
charge_damage=30
bite_damage=40
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
-- color recolors the legend sprite's gold.
unit_specs=parse_table[[
name,sprite,hp,speed,damage,cooldown,fire_taken,score,meal,ai,range,keep_away,shot,color
serf,64,3,0.5,1,30,1,5,2,melee
archer,65,4,0.45,2,70,1,10,2,ranged,60,0.4,arrow
knight,66,12,0.8,4,30,0.5,25,3,melee
champion,67,20,0.5,4,90,0.3,50,3,ranged,70,0.4,holy
ballista,69,15,0.2,8,120,0.7,40,0,ranged,100,0,bolt
catapult,70,15,0.2,12,150,0.7,40,0,ranged,110,0,rock
sheep,71,1,0.3,0,0,1,0,10,sheep
sir gawain,68,60,1,6,40,0.3,500,30,legend,,,,11
sir percival,68,80,1,6,40,0.3,500,30,legend,,,,14
sir galahad,68,100,1,6,40,0.3,500,30,legend,,,,7
sir lancelot,68,120,1,6,40,0.3,500,30,legend,,,,13
king arthur,68,140,1,10,40,0.3,500,30,legend,,,excalibur,10
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
settlement_specs=parse_table[[
name,radius,ground,fields,fixed,buildings
lair,3,19,0
village,4,1,3,,house/hut/hut/hut/house/hut
town,5,1,3,,church/tower/tower/house/house/house/house/house/house/hut/hut
camelot,6,1,0,keep:-1:-1/tower:-4:-4/tower:3:-4/tower:-4:3/tower:3:3,church/tower/tower/house/house/house/house/house
]]

-- the realm is a 3x3 grid of settlements, read left to right, top
-- to bottom.
realm=split"lair,village,village,village,town,town,village,town,camelot"

-- wrath rises with score. each level has its own reinforcements and
-- may send a legend.
wrath_levels=parse_table[[
name,score,legend,pool
wary,0,,serf/serf/archer
alarmed,300,sir gawain,serf/archer/knight
mustering,900,sir percival,archer/knight/knight/champion
crusading,2000,sir galahad,knight/knight/champion/ballista/catapult
desperate,3600,sir lancelot,knight/champion/champion/ballista/catapult/catapult
]]
