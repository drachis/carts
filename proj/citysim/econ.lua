-- econ.lua : money, monthly tick, cost table

cost={road=10,zone=50,line=5,plant=300,dozer=1}

function try_spend(n)
 if money>=n then
  money-=n
  return true
 end
 msg="not enough money"
 msg_t=60
 return false
end

function init_econ()
 money=2000
 month=1
 year=1900
 ec_f=0
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
 -- income
 local income=pop*2+jobs
 -- upkeep via grid scan
 local upkeep=0
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   local s=tile(x,y)
   if s>=16 and s<=31 then
    upkeep+=1
   elseif s==49 or s==50 or s==51 then
    upkeep+=1
   elseif s==48 then
    upkeep+=10
   end
  end
 end
 local net=income-upkeep
 money+=net
 if net>=0 then
  msg="taxes +$"..net
 else
  msg="deficit -$"..(-net)
 end
 msg_t=90
end
