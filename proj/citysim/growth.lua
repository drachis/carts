-- growth.lua : demand pass + growth tick
-- owns: pop, jobs, demand

local gr_dk={"r","c","i"}

function init_growth()
 pop=0
 jobs=0
 demand={r=0,c=0,i=0}
 milestone=0
 city_name="settlement"
end

function update_growth()
 if frame%32==0 then
  local res=0
  local cjobs=0
  local ijobs=0
  local cnt={}
  lv_grid={}
  for y=0,gridh-1 do
   for x=0,gridw-1 do
    local s=tile(x,y)
    if s>=32 and s<=43 then
     local k=flr((s-32)/4)+1
     local d=(s-32)%4
     if k==1 then res=res+d*p.r_per_density
     elseif k==2 then cjobs=cjobs+d*p.c_per_density
     else ijobs=ijobs+d*p.i_per_density
     end
    end
    local c=tcl[s]
    if c then cnt[c]=(cnt[c] or 0)+1 end
    lv_tile(s,flr(x/4),flr(y/4))
   end
  end
  city_st=cnt
  pop=res
  jobs=cjobs+ijobs
  local tp=(tax_rate-2)*p.tax_demand
  if money<0 then tp+=p.debt_demand end
  demand.r=mid((jobs+16-pop)/32-tp,-1,1)
  demand.c=mid((pop*0.5-cjobs)/24-tp,-1,1)
  demand.i=mid((pop*0.7-ijobs)/24-tp,-1,1)
  for m in all(p.ranks) do
   if pop>=m[1] and milestone<m[1] then
    milestone=m[1]
    hud_msg,hud_msg_c,hud_msg_t=m[2].."!",12,120
    sfx(2)
   end
  end
  city_name=pop<50 and "settlement" or jobs>pop and "hub" or "suburb"
 end

 if frame%16==0 then
  for i=1,p.growth_samples do
   local x=flr(rnd(gridw))
   local y=flr(rnd(gridh))
   local k=zone_kind(x,y)
   if k then
    local d=demand[gr_dk[k]]
    local dens=zone_density(x,y)
    -- density-0 plots grow 2x faster to fill empty zones quickly
    local rate=p.grow_rate*(dens==0 and 2 or 1)*growth_mult(x,y,k)
    if is_powered(x,y) and has_road_access(x,y) and dens<3
     and net_ok(x,y,k,dens)
     and rnd()<d*rate then
     set_zone(x,y,k,dens+1)
     add_fx(x,y,4,0.5,0,20,7,10)
    elseif (not is_powered(x,y) or d<-0.5)
     and dens>0 and rnd()<(is_powered(x,y) and p.decay_rate or 0.2) then
     set_zone(x,y,k,dens-1)
    end
   end
  end
 end
end
