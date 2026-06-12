-- growth.lua : demand pass + growth tick
-- owns: pop, jobs, demand

local gr_dk={"r","c","i"}

function init_growth()
 pop=0
 jobs=0
 demand={r=0,c=0,i=0}
 milestone=0
end

local gr_ranks={{50,"town"},{150,"city"},{400,"metropolis"}}

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
     if k==1 then res=res+d*8
     elseif k==2 then cjobs=cjobs+d*6
     elseif k==3 then ijobs=ijobs+d*8
     end
    end
   end
  end
  pop=res
  jobs=cjobs+ijobs
  -- high taxes scare everyone off a bit
  local tp=(tax_rate-2)*0.15
  demand.r=mid((jobs+16-pop)/32-tp,-1,1)
  demand.c=mid((pop*0.5-cjobs)/24-tp,-1,1)
  demand.i=mid((pop*0.7-ijobs)/24-tp,-1,1)
  -- city rank milestones
  for m in all(gr_ranks) do
   if pop>=m[1] and milestone<m[1] then
    milestone=m[1]
    hud_msg,hud_msg_c="welcome to your "..m[2].."!",12
    hud_msg_t=120
    sfx(2)
   end
  end
 end

 if frame%16==0 then
  -- growth tick
  for i=1,24 do
   local x=flr(rnd(gridw))
   local y=flr(rnd(gridh))
   local k=zone_kind(x,y)
   if k then
    local d=demand[gr_dk[k]]
    local dens=zone_density(x,y)
    if is_powered(x,y) and has_road_access(x,y) and dens<3
     and rnd()<d*0.5*growth_mult(x,y,k) then
     set_zone(x,y,k,dens+1)
    elseif (not is_powered(x,y) or d<-0.5
     or (k<3 and land_value(x,y)<-3))
     and dens>0 and rnd()<0.08 then
     set_zone(x,y,k,dens-1)
    end
   end
  end
 end
end
