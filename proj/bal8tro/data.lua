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
step_frames=47
joker_frames=59
score_delay=110
total_gap=98
total_hold=237
shop_wait=220
exit_wait=35
pack_wait=22
pack_hold=111
shop_return=41
select_wait=108
score_wait=52
score_roll=30
spring=0.3
damping=0.6
glide_cap=6
play_delay=28
play_stagger=8
lift_wait=38
juice_frames=24
deal_frames=7
deck_x=113
deck_y=105
chips_x=2
mult_x=20
boxes_y=55
table_centre=84
snd_deal=4
snd_move=27
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
name,text,cond,tag,when,need,chips,mult,xmult,cost,per,grow
joker,+4 mult,,,hand,,,4,,2,,
greedy,+3 mult,per,,card,4,,3,,5,,
lusty,+3 mult,per,,card,2,,3,,5,,
wrath,+3 mult,per,,card,1,,3,,5,,
glutton,+3 mult,per,,card,3,,3,,5,,
jolly,+8 mult,pair,pair,hand,pair,,8,,3,,
zany,+12mult,trips,3oak,hand,three,,12,,4,,
mad,+10mult,2 pair,2pr,hand,two,,10,,4,,
droll,+10mult,flush,flsh,hand,flush,,10,,4,,
sly,+50chip,pair,pair,hand,pair,50,,,3,,
clever,+80chip,2 pair,2pr,hand,two,80,,,4,,
scary,+30chip,face,face,card,face,30,,,4,,
the duo,x2 mult,pair,pair,hand,pair,,,2,8,,
tribe,x2 mult,flush,flsh,hand,flush,,,2,8,,
abstract,+3 mult,a joker,jkrs,hand,,,3,,4,jokers,
banner,+30chip,a disc,disc,hand,,30,,,5,discards,
summit,+15mult,0 discs,0dsc,hand,nodisc,,15,,5,,
half,+20mult,<=3 crd,<=3,hand,small,,20,,5,,
nova,+1 mult,a play,nova,hand,,,1,,5,plays,
green,+1 mult,grows,grow,hand,,,1,,4,count,green
bus,+1 mult,no face,bus,hand,,,1,,6,count,bus
]]

blind_specs=parse_table[[
name,factor,reward,colour
small blind,2,3,12
big blind,3,4,9
the boss,4,5,8
]]

ante_bases=split"3,8,20,50,110,200,350,500"

sidebar_boxes=parse_table[[
name,left,top,right,heading,colour,big
goal,2,15,36,goal,8,1
shown_score,2,29,36,round,7,1
hands_left,2,67,18,hand,12,
discards_left,20,67,36,disc,8,
ante_label,2,97,18,ante,9,
round_number,20,97,36,rnd,9,
]]

for number,spec in ipairs(joker_specs) do spec.sprite=31+number end

enhancement_specs=parse_table[[
name,chips,mult,xmult,held_xmult,colour
bonus,30,,,,12
mult,,4,,,8
wild,,,,,14
glass,,,2,,6
steel,,,,1.5,13
gold,,,,,10
lucky,,20,,,11
]]

tarot_specs=parse_table[[
name,text,act,most,value,cond
magician,2 to lucky,enhancement,2,lucky,pick in hand
empress,2 to mult,enhancement,2,mult,pick in hand
hierophant,2 to bonus,enhancement,2,bonus,pick in hand
lovers,1 to wild,enhancement,1,wild,pick in hand
chariot,1 to steel,enhancement,1,steel,pick in hand
justice,1 to glass,enhancement,1,glass,pick in hand
devil,1 to gold,enhancement,1,gold,pick in hand
star,3 to diamonds,suit,3,4,pick in hand
moon,3 to clubs,suit,3,3,pick in hand
sun,3 to hearts,suit,3,2,pick in hand
world,3 to spades,suit,3,1,pick in hand
strength,2 rank up,rank,2,,pick in hand
hanged man,destroy 2,destroy,2,,pick in hand
hermit,double $ max 20,money,0,,
]]

deck_specs=parse_table[[
name,text,hands,discards,money,faces,suits,colour
red,+1 discard,0,1,0,1,4,8
blue,+1 hand,1,0,0,1,4,12
yellow,+$10,0,0,10,1,4,9
abandoned,no face cards,0,0,0,0,4,3
checkered,spades+hearts only,0,0,0,1,2,13
]]

pack_specs=parse_table[[
name,label,kind,choices,cost,colour
arcana,arcana,tarot,3,4,2
celestial,celest,planet,3,4,12
buffoon,buffoon,joker,2,4,9
standard,standard,card,3,4,6
]]

table_buttons=parse_table[[
name,label,colour,left
play_hand,play,12,41
discard_hand,disc,8,59
sort_hand,sort,13,77
open_info,info,3,95
]]

vfx_specs=parse_table[[
name,count,speed,rise,gravity,life,ramp,width
spark,8,1.5,1,.08,30,,0
shower,40,2.5,1.5,.08,30,9/10/10/7,16
flame,1,.3,.9,0,18,2/8/8/9/10/7,16
coin,10,1.5,2,.12,36,9/10/10/7,8
]]
for spec in all(vfx_specs) do
 if spec.ramp then spec.ramp=split(spec.ramp,"/") end
end

boss_specs=parse_table[[
name,text,factor,debuff,hands,discards,must,halve
the club,clubs are debuffed,4,3,,,,
the goad,spades are debuffed,4,1,,,,
the head,hearts are debuffed,4,2,,,,
the window,diamonds are debuffed,4,4,,,,
the wall,extra large blind,8,,,,,
the needle,play only 1 hand,2,,1,,,
the water,start with 0 discards,4,,,0,,
the psychic,must play 5 cards,4,,,,5,
the flint,base hand is halved,4,,,,,1
]]
