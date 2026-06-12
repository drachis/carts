-- econ.lua : money, monthly tick, cost table

cost={road=10,zone=50,line=5,plant=300,park=10,bridge=50,dozer=1}

-- deficit spending allowed down to a debt ceiling
function try_spend(n)
 if money-n>=-1000 then
  money-=n
  return true
 end
 msg="bankers refuse: debt limit"
 msg_t=60
 sfx(1)
 return false
end

function init_econ()
 money=2000
 month=1
 year=1950
 ec_f=0
 tax_rate=2
 hud_msg,hud_msg_t,hud_msg_c="",0,7
end

function update_econ()
 ec_f+=1
 if ec_f<300 then return end
 ec_f=0
 -- advance month
 month+=1
 if month>12 then
  month=1
  year+=1
 end
 -- income scales with the tax rate (menu-adjustable)
 local income=pop*tax_rate+flr(jobs*tax_rate/2)
 -- upkeep via grid scan
 local upkeep=0
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   local s=tile(x,y)
   if s>=16 and s<=31 then
    upkeep+=1
   elseif s==49 or s==50 or s==51 then
    upkeep+=1
   elseif s==53 or s==54 then
    upkeep+=2 -- road + line crossing
   elseif s==48 then
    upkeep+=10
   end
  end
 end
 -- debt accrues interest monthly
 if money<0 then
  upkeep+=flr(-money*0.02)+1
 end
 local net=income-upkeep
 money+=net
 if month==1 and money<0 then
  hud_msg,hud_msg_c="in debt! citizens unhappy",8
  hud_msg_t=150
  sfx(3)
 end
 -- monthly summary shows in the hud where the date is
 if net>=0 then
  hud_msg,hud_msg_c="taxes +$"..net,11
 else
  hud_msg,hud_msg_c="deficit -$"..(-net),8
 end
 hud_msg_t=90
 sfx(2)
end
