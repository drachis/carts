-- ui.lua : hud, menu, minimap, message overlay

local ui_months={"jan","feb","mar","apr","may","jun",
                 "jul","aug","sep","oct","nov","dec"}

function draw_hud()
 rectfill(0,0,127,7,0)
 -- money
 local ms="$"..tostr(money)
 print(ms,0,1,money<0 and 8 or 11)
 -- pop: P#.##K format when over 1000
 local ps=pop<1000 and "p"..pop
  or "p"..flr(pop/100)/10 .."k"
 print(ps,28,1,14)
 -- date always visible (messages go to ticker below the bar)
 print(ui_months[month].." "..tostr(year),44,1,7)
 -- rci demand bars: r green, c blue, i yellow; dim hue below midline
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

-- ticker: system messages slide in below the hud bar (y=8..14)
function draw_ticker()
 if not hud_msg_t or hud_msg_t<=0 then return end
 hud_msg_t-=1
 rectfill(0,8,127,14,0)
 print(hud_msg,1,9,hud_msg_c)
end

function draw_menu()
 if mode~="menu" then return end
 local sy=115
 rectfill(0,sy-1,127,sy+12,1)
 for i=1,#tools_list do
  local x=58+(i-tool)*13
  if x>-12 and x<128 then
   local e=tools_list[i]
   if e.kind then
    rect(x+1,sy+1,x+10,sy+10,({11,12,10})[e.kind])
    print(({"r","c","i"})[e.kind],x+4,sy+4,7)
   elseif e.insp then
    circ(x+5,sy+4,3,7)
    line(x+8,sy+7,x+10,sy+9,7)
   elseif e.spr then
    spr(e.spr,x+2,sy+2)
   elseif e.name=="bulldoze" then
    line(x+2,sy+2,x+9,sy+9,8)
    line(x+9,sy+2,x+2,sy+9,8)
   elseif e.spd then
    print(">>",x+2,sy+3,10)
   else
    fillp(0x33cc)
    rectfill(x+2,sy+2,x+9,sy+9,0x3b)
    fillp()
   end
   if i==tool then rect(x-1,sy-1,x+12,sy+12,7) end
  end
 end
 local e=tools_list[tool]
 local label=e.name
 if e.costkey and cost[e.costkey] then
  label=label.." $"..cost[e.costkey]
 end
 local lx=64-#label*2
 rectfill(lx-1,sy-10,lx+#label*4,sy-3,0)
 print(label,lx,sy-9,7)
end

local ui_ccol={3,3,12,3,4,5,0,5,4,6,6,8,7,11,9,0}
function ui_city_col(s)
 if s>=32 and s<=35 then return 11 end
 if s>=36 and s<=39 then return 13 end
 if s>=40 and s<=43 then return 10 end
 return ui_ccol[tcl[s]] or 3
end

function draw_minimap()
 if mode~="map" then return end
 local px,py=16,13
 rectfill(px-1,py-1,px+96,py+96,0)
 rect(px-1,py-1,px+96,py+96,7)
 for ty=0,47 do
  for tx=0,47 do
   local c
   local s=tile(tx,ty)
   if map_view=="power" then
    if s==3 then c=12
    elseif s==48 then c=10
    elseif is_powered(tx,ty) then c=11
    elseif conducts(tx,ty) then c=8
    else c=5 end
   else
    c=ui_city_col(s)
   end
   rectfill(px+tx*2,py+ty*2,px+tx*2+1,py+ty*2+1,c)
  end
 end
 local vx=px+flr(camx/8)*2
 local vy=py+flr(camy/8)*2
 rect(vx,vy,vx+31,vy+29,7)
 print(map_view,px+2,py+1,7)
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
