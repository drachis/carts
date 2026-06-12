-- tools.lua : input, cursor, placement, bulldoze, autotiling

tools_list={
 {name="road",costkey="road",spr=26},
 {name="house zone",costkey="zone",spr=33,kind=1},
 {name="shop zone",costkey="zone",spr=37,kind=2},
 {name="factory zone",costkey="zone",spr=41,kind=3},
 {name="power line",costkey="line",spr=49},
 {name="power plant",costkey="plant",spr=48},
 {name="bulldoze",costkey="dozer"},
 {name="map"},
}

function init_tools()
 cur={x=24,y=24}
 tool=1
 mode="play"
 msg,msg_t="",0
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
   mode=tools_list[tool].name=="map" and "map" or "play"
  end
 else -- map mode
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
 if t.name=="bulldoze" then
  if tile(x,y)>3 and try_spend(cost.dozer) then
   set_tile(x,y,1)
   refresh_around(x,y)
   update_power()
  end
  return
 end
 if not is_buildable(x,y) then
  msg,msg_t="can't build there",60
  return
 end
 if not try_spend(cost[t.costkey]) then return end
 if t.kind then
  set_zone(x,y,t.kind,0)
 elseif t.name=="road" then
  set_tile(x,y,16)
 elseif t.name=="power line" then
  set_tile(x,y,49)
 else
  set_tile(x,y,48)
 end
 refresh_around(x,y)
 update_power()
end

-- roads pick their sprite from connected neighbors (n=1 e=2 s=4 w=8);
-- power lines pick horiz/vert/cross from conductive neighbors
function refresh_tile(x,y)
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
