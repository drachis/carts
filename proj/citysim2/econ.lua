-- econ.lua : money ($k), tax, time. HEADER — bodies are STUBS for an agent.
-- api: init_econ, update_econ, try_spend, mfmt; globals money, tax_rate, month, year
-- calls: pop, jobs (sim census), p
-- money is stored in THOUSANDS of dollars (16.16 fixed-point flips past 32767),
-- so costs/income are in dollars and scaled /1000 here (see ../citysim/LEARNINGS).

money=2
tax_rate=2
month=1
year=1950
ec_f=0

function init_econ()
 money=p.start_money
 tax_rate=p.tax_rate
 month=1 year=1950
 ec_f=0
end

-- format a $k value: <$1k -> "$NNN", then "$N.Nk", then "$N.Nm". signed.
function mfmt(v)
 local s=v<0 and "-$" or "$"
 local a=abs(v)
 if a<1 then return s..flr(a*1000+0.5) end
 local u="k"
 if a>=1000 then a=a/1000 u="m" end
 local w=flr(a)
 local f=flr((a-w)*10)
 return s..w..(f>0 and "."..f or "")..u
end

-- spend n DOLLARS; allow down to -$1k debt; return true if allowed.
function try_spend(n)
 local d=n/1000
 if money-d>=-1 then money-=d return true end
 return false
end

-- advance time + apply monthly income/upkeep. call every frame from the glue.
function update_econ()
 ec_f+=1
 if ec_f<p.month_frames then return end
 ec_f=0
 month=month%12+1
 if month==1 then year+=1 end
 local income=pop*tax_rate+flr(jobs*tax_rate/2)
 local roads=0
 for y=0,gw-1 do
  for x=0,gw-1 do
   if is_road(x,y) then roads+=1 end
  end
 end
 local upkeep=roads*p.road_up
 money=min(32000,money+(income-upkeep)/1000)
end
