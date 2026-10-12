-- data.lua : tuning and content as text, parsed once at boot.
-- every row parse_table makes is a prototype: objects are made with
-- setmetatable(object,row) and hold only what differs from their row.

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

-- depth runs from 1 (the mech's line) to far_z (the crest of the hill).
-- cone_base is the lock cone's half width at the guns, in world pixels;
-- it widens by the mech's own `cone` for each unit of depth, which an
-- upgrade raises. hover is how high the mech flies.
parse_record([[
far_z=6
crest_y=46
globe=175
crest_hop=20
scroll_speed=0.005
drop_speed=0.01
redeemer_chance=0.08
chill_frames=240
vent_delay=12
vent_rate=1.5
boost_speed=0.008
snd_vent=18
snd_glance=19
cone_base=7
hover=6
max_heat=100
restart_heat=50
mech_accel=0.06
mech_speed=0.9
alpha_cost=60
alpha_frames=180
combo_frames=150
snd_pop=6
snd_boom=7
snd_hurt=8
snd_switch=9
snd_wave=10
snd_overheat=11
snd_alpha=12
snd_upgrade=13
snd_step=14
snd_roar=15
]],nil,_ENV)

-- what a new run starts from; reset() parses these
player_start="x=0,vx=0,armor=100,max_armor=100,heat=0,weapon=1,hurt_flash=0,muzzle=0,recoil=0,gun_side=1,alpha=0,chill=0,cooling=0.35,power=1,haste=1,agility=1,cone=6.5"
run_start="score=0,shake=0,freeze=0,white=0,grid_flash=0,combo=0,combo_wait=0,charge=0,dying=0,bark_wait=0,over_wait=0,city=100,city_flash=0,x_held=0,boost=0"

-- cooldown is in frames (60 a second); speed is depth per frame;
-- homing 1 follows what was locked; 0 flies straight at where it was,
-- and a blast goes off there if it has hit nothing on the way.
-- spread is sideways scatter; splash is a blast radius; range is how
-- deep it locks and reaches; wave is when the weapon is issued. ammo is
-- what it holds (0 is unlimited) and pack is what an ammo drop gives.
weapon_specs=parse_table[[
name,wave,range,cooldown,damage,speed,count,spread,splash,heat,colour,homing,pierce,sound,ammo,pack
pulse,1,4.5,7,1,0.2,1,0,0,4,12,1,0,0,0,0
flak,2,3,42,2,0.14,7,1.6,0,24,9,0,0,1,14,6
minigun,3,4,3,0.6,0.25,1,0,0,2,10,1,0,2,160,60
shock,4,6.2,34,5,0.6,1,0,0,20,14,1,1,3,14,5
rocket,5,6.2,60,10,0.07,1,0,16,28,8,0,0,4,8,3
redeemer,7,6.2,150,60,0.04,1,0,60,90,11,0,0,5,1,1
]]

-- between waves the pilot picks one of three; stat is the field of
-- `player` that amount is added to.
upgrade_specs=parse_table[[
name,stat,amount,blurb
armor,max_armor,30,+30 max
heatsink,cooling,0.1,+cooling
overload,power,0.25,+25% dmg
loader,haste,-0.15,+15% rof
servos,agility,0.3,+speed
optics,cone,2,+aim arc
]]

-- cell is the first of two sprite frames; tail is the cell the followers
-- of a chain use. size scales the 16px sprite. fly is height off the
-- ground; sway is how far it weaves; bite is what a missile does to the
-- mech, and twice what a foe does to the city.
-- track 1 closes on the mech over the last stretch; 0 keeps its line and
-- runs for the city. a foe worth no points is a missile: it lands where
-- the mech stood when it was thrown, and does the city no harm. brood is what it drops, every
-- brood_every frames. halt is a depth it stops at. parts are more sprites drawn around the body, as
-- cell:across:down in sprite pixels; ones to the right are flipped.
-- `armor` is health on top of hp that goes first (any gun wears it down;
-- the foe is drawn grey while it holds); the gun named
-- in `weak` does double.
enemy_specs=parse_table[[
name,cell,tail,size,hp,speed,fly,sway,bite,points,chain,track,brood,brood_every,halt,boss,armor,weak,parts
skitter,0,0,0.7,2,0.011,0,10,6,1,0,0,,,,,0,,
wing,2,2,0.8,3,0.016,45,24,8,2,0,0,,,,,0,flak,
brute,4,4,1.6,20,0.006,0,4,25,10,0,1,spit,260,,,20,rocket,16:-10:1/16:10:1
wyrm,6,8,1.1,6,0.009,0,26,10,3,1,1,,,,,0,shock,
ship,10,10,2.4,70,0.004,60,8,30,25,0,1,skitter,220,2.4,,0,minigun,
spit,14,14,0.6,1,0.028,14,0,9,0,0,0,,,,,0,,
tyrant,18,18,3,350,0.0024,0,6,60,100,0,1,spit,110,1.8,1,150,redeemer,20:0:-7/16:-12:-3/16:12:-3/16:-10:4/16:10:4
]]

for spec in all(enemy_specs) do
 spec.part_list={}
 for part in all(split(spec.parts or "","/")) do
  if part!="" then add(spec.part_list,split(part,":")) end
 end
end

-- one wave a line; each group is name*count, sent a few seconds apart.
wave_specs=split([[skitter*6,skitter*8,skitter*8
skitter*8,wing*5,skitter*10,wing*5
wing*6,wyrm*6,skitter*10,wing*6,wyrm*7
brute*1,skitter*10,wing*6,skitter*12,brute*1,wyrm*8
wyrm*8,skitter*12,brute*2,wing*8,wyrm*8,skitter*14
ship*1,wing*8,wyrm*8,skitter*14,brute*2,wing*10
ship*1,brute*2,skitter*14,wing*10,wyrm*10,ship*1,brute*2,skitter*14
tyrant*1,skitter*12,wing*8,wyrm*8,brute*1,skitter*14,wing*10,brute*2,skitter*14,wing*10]],"\n")

-- one a wave: the mech flies in from the edge of the city to its centre
district_names=split"the suburbs,riverside,old town,the market,midtown,the exchange,downtown,the capitol"
skyline=split"7,12,9,16,7,13,20,8,11,15,6,18,10,14,7,12,9,17,8,11,14,9"
blast_colours=split"7,10,9,8,2"
-- the depths a road is drawn through, closer together where it is near
road_depths=split"0.7,1,1.4,1.9,2.5,3.2,4.2,6"
-- a tower takes one of four wall,roof pairs and one of three window colours
tower_tints=split"5,6,13,6,4,5,1,13"
window_tints=split"10,12,7"
stars=split"9,5,30,11,52,3,71,9,96,6,118,12,84,16,40,17,14,15,107,2"
