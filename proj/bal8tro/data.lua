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
joker_count=3
step_frames=18
snd_chips=0
snd_mult=1
snd_pick=2
snd_total=3
]],nil,_ENV)

hand_specs=parse_table[[
name,label,chips,mult
high,high card,5,1
pair,pair,10,2
two,two pair,20,2
three,three of a kind,30,3
straight,straight,30,4
flush,flush,35,4
full,full house,40,4
four,four of a kind,60,7
sflush,straight flush,100,8
]]

joker_specs=parse_table[[
name,text,when,need,chips,mult,xmult
joker,+4 mult,hand,,,4,
greedy,+3m per,card,4,,3,
lusty,+3m per,card,2,,3,
wrathful,+3m per,card,1,,3,
glutton,+3m per,card,3,,3,
jolly,+8m pair,hand,pair,,8,
zany,+12m trips,hand,three,,12,
sly,+50c pair,hand,pair,50,,
scary,+30c face,card,face,30,,
the duo,x2 pair,hand,pair,,,2
the tribe,x2 flush,hand,flush,,,2
]]

blind_specs=parse_table[[
name,goal
small blind,300
big blind,450
the boss,600
]]
