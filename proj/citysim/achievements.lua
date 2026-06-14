-- achievements.lua
-- session achievements with hud toasts. reads the tile census city_st
-- that growth's demand scan refreshes (keys are cls[] class names).
-- prefix: av_

local av_done={}

local function st(k) return city_st[k] or 0 end

-- class ids: 6 road, 9 bridge, 12 plant, 13 service, 14 park
local av_list={
 {n="first 100 citizens", t=function() return pop>=100 end},
 {n="boomtown 500",       t=function() return pop>=500 end},
 {n="road warrior",       t=function() return st(6)>=50 end},
 {n="river crossed",      t=function() return st(9)>=1 end},
 {n="green thumb",        t=function() return st(14)>=5 end},
 {n="power broker",       t=function() return st(12)>=3 end},
 {n="civil servant",      t=function() return st(13)>=3 end},
 {n="deep pockets",       t=function() return money>=5 end},
}

function init_achv()
 av_done={}
end

function update_achv()
 if frame%128~=0 then return end
 for i=1,#av_list do
  if not av_done[i] and av_list[i].t() then
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
