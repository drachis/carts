-- econ.lua : money, monthly tick (costs live in params.lua)

-- format money as $1.5k / $29k etc; PICO-8 max is 32767 so k is the ceiling
function mfmt(v)
 local s=v<0 and "-$" or "$"
 local a=abs(v)
 if a>=1000 then
  local k=flr(a/1000)
  local t=flr((a%1000)/100)
  return s..k..(t>0 and "."..t or "").."k"
 end
 return s..a
end

-- deficit spending allowed down to a debt ceiling
function try_spend(n)
 if money-n>=-p.debt_limit then
  money-=n
  return true
 end
 msg="bankers refuse: debt limit"
 msg_t=60
 sfx(1)
 return false
end

function init_econ()
 money=p.start_money
 month=1
 year=1950
 ec_f=0
 tax_rate=2
 last_income,last_upkeep=0,0
 city_st={} -- tile census by class id, refreshed by growth's demand scan
 hud_msg,hud_msg_t,hud_msg_c="",0,7
end

function update_econ()
 ec_f+=1
 if ec_f<p.month_frames then return end
 ec_f=0
 -- advance month
 month+=1
 if month>12 then
  month=1
  year+=1
 end
 -- income scales with the tax rate (menu-adjustable)
 local income=pop*tax_rate+flr(jobs*tax_rate/2)
 -- upkeep priced from the shared tile census
 local upkeep=0
 for k,v in pairs(p.upkeep) do
  upkeep+=(city_st[k] or 0)*v
 end
 -- debt accrues interest monthly
 if money<0 then
  upkeep+=flr(-money*p.interest)+1
 end
 local net=income-upkeep
 money=min(29000,money+net)
 last_income,last_upkeep=income,upkeep
 if net>=0 then
  hud_msg,hud_msg_c="+"..mfmt(net).." tax",11
 else
  hud_msg,hud_msg_c=mfmt(net).." deficit",8
 end
 hud_msg_t=90
 sfx(2)
end
