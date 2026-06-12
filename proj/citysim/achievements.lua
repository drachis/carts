-- achievements.lua
-- session achievements with hud toasts
-- prefix: av_

local av_done={}
local av_stats={}

local av_list={
 {n="first 100 citizens", t=function(s) return pop>=100 end},
 {n="boomtown 500",       t=function(s) return pop>=500 end},
 {n="road warrior",       t=function(s) return s.roads>=50 end},
 {n="river crossed",      t=function(s) return s.bridges>=1 end},
 {n="green thumb",        t=function(s) return s.parks>=5 end},
 {n="power broker",       t=function(s) return s.plants>=3 end},
 {n="civil servant",      t=function(s) return s.svc>=3 end},
 {n="deep pockets",       t=function(s) return money>=5000 end},
}

function init_achv()
 av_done={}
 av_stats={}
end

function update_achv()
 if frame%128~=0 then return end
 local s={roads=0,parks=0,plants=0,bridges=0,svc=0}
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   local t=tile(x,y)
   if (t>=16 and t<=31) or t==53 or t==54 then
    s.roads=s.roads+1
   elseif t==59 or t==60 then
    s.bridges=s.bridges+1
    s.roads=s.roads+1
   elseif t==44 then
    s.parks=s.parks+1
   elseif t==48 then
    s.plants=s.plants+1
   elseif t==64 or t==65 or t==66 then
    s.svc=s.svc+1
   end
  end
 end
 for i=1,#av_list do
  if not av_done[i] and av_list[i].t(s) then
   av_done[i]=true
   hud_msg="achv: "..av_list[i].n
   hud_msg_c=10
   hud_msg_t=120
   sfx(2)
   return
  end
 end
end

function achv_count()
 local n=0
 for i=1,#av_list do
  if av_done[i] then n=n+1 end
 end
 return n
end

function achv_total()
 return #av_list
end
