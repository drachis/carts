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
  -- demand pass
  local res=0
  local cjobs=0
  local ijobs=0
  for y=0,gridh-1 do
   for x=0,gridw-1 do
    local k=zone_kind(x,y)
    if k then
     local d=zone_density(x,y)
     if k==1 then res=res+d*p.r_per_density
     elseif k==2 then cjobs=cjobs+d*p.c_per_density
     elseif k==3 then ijobs=ijobs+d*p.i_per_density
     end
    end
   end
  end
  pop=res
  jobs=cjobs+ijobs
  -- high taxes scare everyone off a bit; a city in debt scares them more
  local tp=(tax_rate-2)*p.tax_demand
  if money<0 then tp+=p.debt_demand end
  demand.r=mid((jobs+16-pop)/32-tp,-1,1)
  demand.c=mid((pop*0.5-cjobs)/24-tp,-1,1)
  demand.i=mid((pop*0.7-ijobs)/24-tp,-1,1)
  -- city rank milestones
  for m in all(p.ranks) do
   if pop>=m[1] and milestone<m[1] then
    milestone=m[1]
    hud_msg,hud_msg_c="welcome to your "..m[2].."!",12
    hud_msg_t=120
    sfx(2)
   end
  end
  -- a name from the city's rci character
  local tot=res+cjobs+ijobs
  if tot<30 then city_name="settlement"
  elseif res>cjobs+ijobs then city_name="suburbia"
  elseif cjobs>res and cjobs>ijobs then city_name="market town"
  elseif ijobs>res then city_name="industria"
  else city_name="metroville" end
 end

 if frame%16==0 then
  -- growth tick
  for i=1,p.growth_samples do
   local x=flr(rnd(gridw))
   local y=flr(rnd(gridh))
   local k=zone_kind(x,y)
   if k then
    local d=demand[gr_dk[k]]
    local dens=zone_density(x,y)
    if is_powered(x,y) and has_road_access(x,y) and dens<3
     and rnd()<d*p.grow_rate*growth_mult(x,y,k) then
     set_zone(x,y,k,dens+1)
     add_fx(x,y,1)
     sfx(4)
    elseif (not is_powered(x,y) or d<-0.5
     or (k<3 and land_value(x,y)<-3))
     and dens>0 and rnd()<p.decay_rate then
     set_zone(x,y,k,dens-1)
    end
   end
  end
 end
end
