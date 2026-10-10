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
-- cone_base and cone_slope shape the auto-aim cone above the mech.
parse_record([[
far_z=6
crest_y=46
crest_hop=47
cone_base=7
cone_slope=0.3
max_heat=100
cool_rate=0.3
restart_heat=30
mech_accel=0.06
mech_speed=0.9
snd_pop=6
snd_boom=7
snd_hurt=8
snd_switch=9
snd_wave=10
snd_overheat=11
]],nil,_ENV)

-- cooldown is in frames (60 a second); speed is depth per frame;
-- spread is sideways scatter; splash is a blast radius; wave is when
-- the weapon is issued.
weapon_specs=parse_table[[
name,wave,cooldown,damage,speed,count,spread,splash,heat,colour,homing,pierce,sound
pulse,1,9,1,0.2,1,0,0,4,12,1,0,0
flak,2,42,2,0.14,7,1,0,24,9,0,0,2
minigun,3,3,0.5,0.25,1,0,0,2,10,1,0,1
shock,4,34,5,0.6,1,0,0,20,14,1,1,3
rocket,5,60,10,0.07,1,0,16,28,8,1,0,4
redeemer,7,300,60,0.04,1,0,60,90,11,1,0,5
]]

-- cell is the first of two sprite frames; tail is the cell the followers
-- of a chain use. size scales the 16px sprite. fly is height off the
-- ground; sway is how far it weaves; bite is damage on reaching the mech.
enemy_specs=parse_table[[
name,cell,tail,size,hp,speed,fly,sway,bite,points,chain,brood
skitter,0,0,0.7,2,0.011,0,10,6,1,0,
wing,2,2,0.8,3,0.014,45,22,8,2,0,
brute,4,4,1.8,40,0.006,0,4,25,10,0,
wyrm,6,8,1.1,8,0.009,0,26,10,3,1,
ship,10,10,2.4,90,0.004,60,8,30,25,0,skitter
]]

-- one wave a line; each group is name*count, sent a few seconds apart.
wave_specs=split([[skitter*5,skitter*6
skitter*6,wing*4,skitter*8
wing*5,wyrm*6,skitter*8
brute*1,skitter*8,wing*6
wyrm*8,skitter*10,brute*1,wing*6
wyrm*8,wing*8,brute*2,skitter*12
ship*1,skitter*10,wing*8,brute*2
ship*2,wyrm*10,brute*2,wing*10,skitter*12]],"\n")

skyline=split"7,12,9,16,7,13,20,8,11,15,6,18,10,14,7,12,9,17,8,11,14,9"
grid_depths=split"1.15,1.4,1.8,2.5,3.6,5"
stars=split"9,5,30,11,52,3,71,9,96,6,118,12,84,16,40,17,14,15,107,2"
