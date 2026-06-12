-- tools.lua : input, cursor, placement, bulldoze, autotiling

tools_list={
 {name="road",costkey="road",spr=26},
 {name="house zone",costkey="zone",spr=33,kind=1},
 {name="shop zone",costkey="zone",spr=37,kind=2},
 {name="factory zone",costkey="zone",spr=41,kind=3},
 {name="park",costkey="park",spr=44},
 {name="power line",costkey="line",spr=49},
 {name="power plant",costkey="plant",spr=48},
 {name="bulldoze",costkey="dozer"},
 {name="map"},
 {name="speed 1x",spd=true},
}

function init_tools()
 cur={x=24,y=24}
 tool=1
 mode="play"
 msg,msg_t="",0
 gspd=1
end

function cycle_speed()
 gspd=gspd==1 and 2 or gspd==2 and 4 or 1
 for e in all(tools_list) do
  if e.spd then e.name="speed "..gspd.."x" end
 end
end

function update_tools()
 if mode=="play" then
  if btnp(0) then cur.x=max(0,cur.x-1) end
  if btnp(1) then cur.x=min(gridw-1,cur.x+1) end
  if btnp(2) then cur.y=max(0,cur.y-1) end
  if btnp(3) then cur.y=min(gridh-1,cur.y+1) end
  update_camera()
  if btnp(5) then apply_tool() end
  if btnp(4) then mode="menu" end
 elseif mode=="menu" then
  if btnp(0) then tool=(tool-2)%#tools_list+1 end
  if btnp(1) then tool=tool%#tools_list+1 end
  if btnp(4) or btnp(5) then
   local e=tools_list[tool]
   if e.spd then
    cycle_speed()
   elseif e.name=="map" then
    mode="map"
   else
    mode="play"
   end
  end
 else -- map mode: dpad pans the viewport
  if btn(0) then camx-=4 end
  if btn(1) then camx+=4 end
  if btn(2) then camy-=4 end
  if btn(3) then camy+=4 end
  camx=mid(0,camx,gridw*8-128)
  camy=mid(0,camy,gridh*8-120)
  -- keep the cursor inside the view for when we return
  cur.x=mid(flr(camx/8)+1,cur.x,flr(camx/8)+14)
  cur.y=mid(flr(camy/8)+1,cur.y,flr(camy/8)+13)
  if btnp(4) or btnp(5) then mode="play" end
 end
end

function apply_tool()
 local t=tools_list[tool]
 local x,y=cur.x,cur.y
 if t.name=="map" then
  mode="map"
  return
 end
 if t.spd then
  cycle_speed()
  return
 end
 local s=tile(x,y)
 if t.name=="bulldoze" then
  if s>3 and try_spend(cost.dozer) then
   -- bridges and pylons revert to water, everything else to grass
   set_tile(x,y,(s==59 or s==60 or s==61) and 3 or 1)
   refresh_around(x,y)
   update_power()
   sfx(1)
  end
  return
 end
 -- figure out what this tool puts here and what it costs
 local put,c
 if t.kind then
  c=cost.zone
  if is_buildable(x,y) then put=zone_base[t.kind] end
 elseif t.name=="road" then
  c=cost.road
  if is_buildable(x,y) then
   put=16
  elseif s==3 then
   put,c=59,cost.bridge
  end
 elseif t.name=="power line" then
  c=cost.line
  if is_buildable(x,y) then put=49
  elseif s==3 then put,c=61,cost.line*4
  elseif s==26 then put=53 -- crossing over straight roads
  elseif s==21 then put=54
  end
 elseif t.name=="park" then
  c=cost.park
  if is_buildable(x,y) then put=44 end
 else -- power plant
  c=cost.plant
  if is_buildable(x,y) then put=48 end
 end
 if not put then
  msg,msg_t="can't build there",60
  sfx(1)
  return
 end
 if not try_spend(c) then return end
 set_tile(x,y,put)
 refresh_around(x,y)
 update_power()
 sfx(0)
end

-- roads pick their sprite from connected neighbors (n=1 e=2 s=4 w=8);
-- power lines pick horiz/vert/cross from conductive neighbors
function refresh_tile(x,y)
 local s=tile(x,y)
 if s==53 or s==54 then return end -- crossings stay as-is
 if s==59 or s==60 then
  -- bridges orient toward their road neighbors
  set_tile(x,y,(is_road(x,y-1) or is_road(x,y+1)) and 60 or 59)
  return
 end
 if is_road(x,y) then
  local m=0
  if is_road(x,y-1) then m+=1 end
  if is_road(x+1,y) then m+=2 end
  if is_road(x,y+1) then m+=4 end
  if is_road(x-1,y) then m+=8 end
  set_tile(x,y,16+m)
 else
  local s=tile(x,y)
  if s>=49 and s<=51 then
   local v=conducts(x,y-1) or conducts(x,y+1)
   local h=conducts(x-1,y) or conducts(x+1,y)
   set_tile(x,y,v and (h and 51 or 50) or 49)
  end
 end
end

function refresh_around(x,y)
 refresh_tile(x,y)
 refresh_tile(x-1,y)
 refresh_tile(x+1,y)
 refresh_tile(x,y-1)
 refresh_tile(x,y+1)
end
