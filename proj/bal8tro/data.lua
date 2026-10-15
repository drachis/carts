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
hand_size=8
max_picked=5
hands_per_blind=4
discards_per_blind=3
joker_slots=4
shop_slots=2
reroll_base=5
planet_cost=3
planet_chance=0.33
step_frames=18
deal_frames=4
deck_x=111
deck_y=70
snd_deal=4
music_calm=0
music_table=2
start_money=4
interest_step=5
interest_cap=5
snd_chips=5
snd_mult=13
snd_pick=2
snd_total=3
]],nil,_ENV)

hand_specs=parse_table[[
name,label,chips,mult,planet,short,level_chips,level_mult
high,high card,5,1,pluto,high,10,1
pair,pair,10,2,mercury,pair,15,1
two,two pair,20,2,uranus,2 pair,20,1
three,three of a kind,30,3,venus,3 kind,20,2
straight,straight,30,4,saturn,str8,30,3
flush,flush,35,4,jupiter,flush,15,2
full,full house,40,4,earth,full hs,25,2
four,four of a kind,60,7,mars,4 kind,30,3
sflush,straight flush,100,8,neptune,str8 fl,40,4
]]

joker_specs=parse_table[[
name,text,cond,when,need,chips,mult,xmult,cost
joker,+4 mult,,hand,,,4,,2
greedy,+3 mult,per,card,4,,3,,5
lusty,+3 mult,per,card,2,,3,,5
wrath,+3 mult,per,card,1,,3,,5
glutton,+3 mult,per,card,3,,3,,5
jolly,+8 mult,pair,hand,pair,,8,,3
zany,+12mult,trips,hand,three,,12,,4
mad,+10mult,2 pair,hand,two,,10,,4
droll,+10mult,flush,hand,flush,,10,,4
sly,+50chip,pair,hand,pair,50,,,3
clever,+80chip,2 pair,hand,two,80,,,4
scary,+30chip,face,card,face,30,,,4
the duo,x2 mult,pair,hand,pair,,,2,8
tribe,x2 mult,flush,hand,flush,,,2,8
]]

blind_specs=parse_table[[
name,factor,reward
small blind,2,3
big blind,3,4
the boss,4,5
]]

ante_bases=split"3,8,20,50,110,200,350,500"
