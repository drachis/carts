-- econ.lua : money, monthly tick (costs live in params.lua)

-- money is stored in THOUSANDS of dollars so a 16.16 fixed-point number can
-- represent up to ~$32m without flipping sign. costs/income stay in dollars
-- and are scaled by 1/1000 at the econ boundaries (try_spend / update_econ).
-- mfmt formats a $k value: <$1k shows dollars, then k, then m.
function mfmt(v)
 local s=v<0 and "-$" or "$"
 local a=abs(v)
 if a<1 then return s..flr(a*1000+0.5) end
 local u="k"
 if a>=1000 then a/=1000 u="m" end
 local w=flr(a)
 local f=flr((a-w)*10)
 return s..w..(f>0 and "."..f or "")..u
end

-- deficit spending allowed down to a debt ceiling
function try_spend(n)
 local d=n/1000 -- dollars -> $k
 if money-d>=-p.debt_limit/1000 then
  money-=d
  return true
 end
 msg="bankers refuse: debt limit"
 msg_t=60
 sfx(1)
 return false
end

function init_econ()
 money=p.start_money/1000
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
 -- debt accrues interest monthly (money is $k, so debt dollars = -money*1000)
 if money<0 then
  upkeep+=flr(-money*1000*p.interest)+1
 end
 local net=income-upkeep
 money=min(32000,money+net/1000)
 last_income,last_upkeep=income,upkeep
 if net>=0 then
  hud_msg,hud_msg_c="+"..mfmt(net/1000).." tax",11
 else
  hud_msg,hud_msg_c=mfmt(net/1000).." deficit",8
 end
 hud_msg_t=90
 sfx(2)
end
