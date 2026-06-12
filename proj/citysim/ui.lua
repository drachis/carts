-- ui.lua : hud, menu, minimap, message overlay

local ui_months={"jan","feb","mar","apr","may","jun",
                 "jul","aug","sep","oct","nov","dec"}

function draw_hud()
 rectfill(0,0,127,7,0)
 -- money
 local ms="$"..tostr(money)
 print(ms,0,1,11)
 -- pop
 local ps="p"..tostr(pop)
 print(ps,28,1,14)
 -- month/year
 local ds=ui_months[month].." "..tostr(year)
 print(ds,58,1,7)
 -- rci demand bars: drawn at right side
 -- each label+bar takes ~6px, 3 groups = ~18px, start at x=108
 local bx=107
 local by=4 -- midline y
 local labels={"r","c","i"}
 local dvals={demand.r,demand.c,demand.i}
 local dcols={11,14,9}
 for i=1,3 do
  local lx=bx+(i-1)*7
  print(labels[i],lx,1,dcols[i])
  local d=dvals[i]
  if d>0 then
   local h=flr(d*3)
   if h<1 then h=1 end
   rectfill(lx,by-h,lx+2,by,11)
  elseif d<0 then
   local h=flr(-d*3)
   if h<1 then h=1 end
   rectfill(lx,by,lx+2,by+h,8)
  end
 end
end

function draw_menu()
 if mode~="menu" then return end
 local n=#tools_list
 local sw=12
 local gap=1
 local total=n*(sw+gap)-gap
 local sx=flr((128-total)/2)
 local sy=116
 -- dark backing for strip
 rectfill(sx-1,sy-1,sx+total,sy+sw,1)
 for i=1,n do
  local e=tools_list[i]
  local x=sx+(i-1)*(sw+gap)
  -- slot bg
  rectfill(x,sy,x+sw-1,sy+sw-1,1)
  -- icon
  if e.spr then
   spr(e.spr,x+2,sy+2)
  elseif e.name=="bulldoze" then
   line(x+2,sy+2,x+sw-3,sy+sw-3,8)
   line(x+sw-3,sy+2,x+2,sy+sw-3,8)
  else
   -- map: 3x3 checkerboard of 2x2 squares
   local cx=x+2
   local cy=sy+2
   for row=0,2 do
    for col=0,2 do
     local c=(row+col)%2==0 and 3 or 11
     rectfill(cx+col*2,cy+row*2,cx+col*2+1,cy+row*2+1,c)
    end
   end
  end
  -- highlight selected
  if i==tool then
   rect(x,sy,x+sw-1,sy+sw-1,7)
  end
 end
 -- label above strip: name + cost
 local e=tools_list[tool]
 local label=e.name
 if e.costkey and cost and cost[e.costkey] then
  label=label.." $"..tostr(cost[e.costkey])
 end
 local lw=#label*4
 local lx=flr((128-lw)/2)
 local ly=sy-9
 rectfill(lx-1,ly-1,lx+lw,ly+6,0)
 print(label,lx,ly,7)
end

function draw_minimap()
 if mode~="map" then return end
 -- dim background
 rectfill(0,0,127,127,1)
 -- 96x96 panel centered: x=16..111, y=16..111
 local px=16
 local py=16
 rect(px-1,py-1,px+96,py+96,7)
 -- draw tiles as 2x2 px blocks
 for ty=0,47 do
  for tx=0,47 do
   local s=tile(tx,ty)
   local c
   if s==3 then
    c=12
   elseif s==1 or s==2 then
    c=3
   elseif s>=16 and s<=31 then
    c=5
   elseif s>=32 and s<=35 then
    c=11
   elseif s>=36 and s<=39 then
    c=14
   elseif s>=40 and s<=43 then
    c=9
   elseif s==48 then
    c=8
   elseif s>=49 and s<=51 then
    c=6
   else
    c=3
   end
   local mx=px+tx*2
   local my=py+ty*2
   rectfill(mx,my,mx+1,my+1,c)
  end
 end
 -- camera viewport rect: world view 128x120 px = 16x15 tiles
 -- camx,camy are pixel offsets; 1 tile=8px, minimap 1 tile=2px
 local vx=px+flr(camx/8)*2
 local vy=py+flr(camy/8)*2
 local vw=16*2-1
 local vh=15*2-1
 rect(vx,vy,vx+vw,vy+vh,7)
 -- title
 local title="city map - x close"
 print(title,flr((128-#title*4)/2),py+97,7)
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
