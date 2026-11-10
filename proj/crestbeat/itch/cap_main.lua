local game_update=_update
local frame,sec,left,route=0,0,0

local function play(number,gun,golden,skip)
 return function()
  start_play()
  start_stage(number)
  equip(gun)
  route=golden
  for i=1,skip or 0 do
   held={}
   bot(i,0,route and stage.golden)
   game_update()
  end
 end
end

local function payout()
 start_play()
 for number,row in ipairs(stages) do
  stage=row
  for i=1,12 do award("kills") end
  if row.bars then
   award("titans")
   award("bells")
  end
  if row.golden and not row.bars and number<5 then award("golds") end
 end
 stage=stages[#stages]
 finish("won")
end

local sections={
 {"hill",play(1,2,true,20)},
 {"streets",play(4,1,true,30)},
 {"titan",play(3,3,true,75)},
 {"queen",play(9,5,false,75)},
 {"payout",payout},
}

function _update()
 if sec>#sections then
  left-=1
  if left==0 then
   printh("ok cap_main")
   extcmd("shutdown")
  end
  return
 end
 if left==0 then
  if sec>0 then extcmd("video") end
  sec+=1
  if not sections[sec] then
   left=90
   return
  end
  frame,left=0,240
  srand(7)
  sections[sec][2]()
  printh("filming "..sections[sec][1])
  extcmd("set_filename","crestbeat_"..sections[sec][1])
  extcmd("rec")
 end
 frame+=1
 left-=1
 held={}
 if mode=="play" then bot(frame,0,route and stage.golden) end
 game_update()
 if frame==150 then extcmd("screen") end
end

printh("started")
