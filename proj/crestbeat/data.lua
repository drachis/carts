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
frames_per_beat=29.88
perfect_window=4
good_window=8
walk_beats=8
alien_hp=2
max_hp=4
crest_y=40
hill_span=60
max_sparks=200
wave_chart=....1.2.3.2.1...3.1.2.3.1.2.3
]],nil,_ENV)

judgements=parse_table[[
name,colour,knock,points,sound
perfect,7,1,100,0
good,10,0.5,50,1
miss,8,0,0,2
]]
