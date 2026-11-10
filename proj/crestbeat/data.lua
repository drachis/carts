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
]],nil,_ENV)

stages=parse_table[[
name,chart,bars,colour,fly,heal,title
hill,....1.2.3.2.1...3.1.5.3.1.2.3,,,,,they're over the hill!
climb,........,,,1,,up the hill!
titan,..q.w.e.a.w.q.s.e.w.d.,4,3,,,titan! shoot its hot spots
streets,..1.3.2.2.k.4.3.j.3.1.l.2.x.1.3.,,,,1,run for it!
climb,........,,,1,,to the crest!
crest,..1.2.3.3.c.8.r.3.1.1.z.6.t.2.3.,,,,,they keep coming!
climb,........,,,1,,the hive queen awaits
queen,..q.w.1.e.a.y.w.q.s.2.e.d.w.r.,6,14,,1,the hive queen!
]]

kinds=parse_table[[
name,keys,bars,walk,bonus,harmless,body,rim,track,depth,sprite,penalty,size,weave
alien,123,0.5,8,0,,11,3,,,0,,1,
weaver,rty,0.5,8,0,,11,2,,,0,,1,2
brute,456,1,8,0,,3,11,,,0,,1.25
hulk,789,1.5,8,0,,3,1,,,0,,1.5
gold,zxc,2,,100,1,10,9,3,0.45,0,,1
civilian,jkl,99,4,0,1,11,3,,,32,50,1
]]

guns=parse_table[[
name,colour,pattern,splash,sound
minigun,10,xxxxxxxx,,1
shock rifle,13,x.x.x.x.,,0
rockets,9,x...x...,0.5,12
flak cannon,4,x.x.x...,,3
plasma rifle,12,x.x.xxx.,,0
]]

for gun in all(guns) do
 gun.shots=#split(gun.pattern,"x")-1
 gun.damage=8/gun.shots
end

judgements=parse_table[[
name,colour,knock,points
perfect,7,1,10
late,10,0.5,5
]]
