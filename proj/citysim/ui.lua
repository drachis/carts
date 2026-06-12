-- ui.lua : hud, menu, minimap, message overlay

local ui_months={"jan","feb","mar","apr","may","jun",
                 "jul","aug","sep","oct","nov","dec"}

function draw_hud()
 rectfill(0,0,127,7,0)
 -- money
 local ms="$"..tostr(money)
 print(ms,0,1,money<0 and 8 or 11)
 -- pop
 local ps="p"..tostr(pop)
 print(ps,28,1,14)
 -- monthly tax summary briefly replaces the date
 if hud_msg_t and hud_msg_t>0 then
  hud_msg_t-=1
  print(hud_msg,58,1,hud_msg_c)
 else
  print(ui_months[month].." "..tostr(year),58,1,7)
 end
 -- rci demand: r green, c blue, i yellow; dimmer hue below the midline
 local bx=104
 local labels={"r","c","i"}
 local dvals={demand.r,demand.c,demand.i}
 local dcols={11,12,10}
 local ncols={3,13,4}
 rectfill(bx,4,bx+22,4,5)
 for i=1,3 do
  local lx=bx+(i-1)*8
  print(labels[i],lx,1,dcols[i])
  local d=dvals[i]
  local h=mid(-3,flr(d*3+(d>0 and 0.99 or 0)),3)
  if h>0 then
   rectfill(lx+4,4-h,lx+5,4,dcols[i])
  elseif h<0 then
   rectfill(lx+4,4,lx+5,4-h,ncols[i])
  end
 end
end

function draw_menu()
 if mode~="menu" then return end
 -- sliding strip: the selected tool stays centered
 local sy=115
 rectfill(0,sy-1,127,sy+12,1)
 for i=1,#tools_list do
  local x=58+(i-tool)*13
  if x>-12 and x<128 then
   local e=tools_list[i]
   if e.spr then
    spr(e.spr,x+2,sy+2)
   elseif e.name=="bulldoze" then
    line(x+2,sy+2,x+9,sy+9,8)
    line(x+9,sy+2,x+2,sy+9,8)
   elseif e.spd then
    print(">>",x+2,sy+3,10)
   else
    -- map: little checkerboard
    for row=0,2 do
     for col=0,2 do
      rectfill(x+2+col*2,sy+2+row*2,x+3+col*2,sy+3+row*2,
       (row+col)%2==0 and 3 or 11)
     end
    end
   end
   if i==tool then
    rect(x-1,sy-1,x+12,sy+12,7)
   end
  end
 end
 -- label above strip: name + cost
 local e=tools_list[tool]
 local label=e.name
 if e.costkey and cost[e.costkey] then
  label=label.." $"..cost[e.costkey]
 end
 local lx=64-#label*2
 rectfill(lx-1,sy-10,lx+#label*4,sy-3,0)
 print(label,lx,sy-9,7)
end

-- minimap tile colors for the "city" view, by sprite id band
function ui_city_col(s)
 if s==3 then return 12 end
 if s>=16 and s<=31 then return 5 end
 if s>=32 and s<=35 then return 11 end
 if s>=36 and s<=39 then return 13 end
 if s>=40 and s<=43 then return 10 end
 if s==48 then return 8 end
 if s==53 or s==54 then return 5 end
 if s==55 then return 9 end
 if s==56 then return 0 end
 if s==59 or s==60 then return 4 end
 if s==61 or (s>=80 and s<=95) then return 6 end
 if s>=64 and s<=66 then return 7 end
 return 3
end

-- the world keeps drawing (and panning) behind the panel: one pass
function draw_minimap()
 if mode~="map" then return end
 local px,py=16,13
 rectfill(px-1,py-1,px+96,py+96,0)
 rect(px-1,py-1,px+96,py+96,7)
 for ty=0,47 do
  for tx=0,47 do
   local c
   if map_view=="smog" then
    local s=tile(tx,ty)
    local v=land_value(tx,ty)
    c=5
    if s==3 then c=12
    elseif v<=-4 then c=8
    elseif v<=-2 then c=9
    elseif v<0 then c=4
    elseif v>1 then c=11
    end
   else
    c=ui_city_col(tile(tx,ty))
   end
   rectfill(px+tx*2,py+ty*2,px+tx*2+1,py+ty*2+1,c)
  end
 end
 local vx=px+flr(camx/8)*2
 local vy=py+flr(camy/8)*2
 rect(vx,vy,vx+31,vy+29,7)
 print(map_view,px+2,py+1,7)
 -- city name, rank, budget, achievements
 rectfill(0,110,127,127,0)
 local rname="village"
 for m in all(p.ranks) do
  if milestone>=m[1] then rname=m[2] end
 end
 print(city_name.." ("..rname..")",18,111,7)
 print("+$"..last_income.." -$"..last_upkeep.."  achv "..achv_count().."/"..achv_total(),18,118,6)
end

function draw_msg()
 if msg_t and msg_t>0 then
  msg_t=msg_t-1
  local mw=#msg*4
  local mx=flr(64-mw/2)
  rectfill(mx-1,109,mx+mw,116,0)
  print(msg,mx,110,7)
 end
end
