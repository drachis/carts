-- tools.lua : input, cursor, placement, bulldoze, autotiling

tools_list={
 {name="inspect",insp=true},
 {name="road",costkey="road",spr=26},
 {name="house zone",costkey="zone",kind=1},
 {name="shop zone",costkey="zone",kind=2},
 {name="factory zone",costkey="zone",kind=3},
 {name="park",costkey="park",spr=44,put=44},
 {name="power line",costkey="line",spr=90},
 {name="power plant",costkey="plant",spr=48,put=48},
 {name="fire dept",costkey="svc",spr=64,put=64},
 {name="police",costkey="svc",spr=65,put=65},
 {name="school",costkey="svc",spr=66,put=66},
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
 map_view="city"
end

function cycle_speed()
 gspd=gspd==1 and 2 or gspd==2 and 4 or 1
 for e in all(tools_list) do
  if e.spd then e.name="speed "..gspd.."x" end
 end
end

function update_tools()
 if mode=="play" then
  local ox,oy=cur.x,cur.y
  if btnp(0) then cur.x=max(0,cur.x-1) end
  if btnp(1) then cur.x=min(gridw-1,cur.x+1) end
  if btnp(2) then cur.y=max(0,cur.y-1) end
  if btnp(3) then cur.y=min(gridh-1,cur.y+1) end
  update_camera()
  if btnp(5) then apply_tool() end
  -- drag-build: hold ❎ and move to paint roads/zones/lines
  if btn(5) and not btnp(5) and (cur.x~=ox or cur.y~=oy) then
   apply_tool(true)
  end
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
  if btnp(4) then
   map_view=map_view=="city" and "power"
    or map_view=="power" and "value" or "city"
  end
  if btnp(5) then mode="play" end
 end
end

-- what would tool t place at x,y, and for how much? nil when invalid.
-- shared by the placement code and the cursor ghost preview.
-- plain power lines (80..95) may be built over without bulldozing.
function tool_put(t,x,y)
 local s=tile(x,y)
 local online=s>=80 and s<=95
 local open=is_buildable(x,y) or online
 if t.kind then
  if open then return zone_base[t.kind],cost.zone end
 elseif t.name=="road" then
  if online then
   -- crossing if the line runs straight, otherwise the road replaces it
   local m=s-80
   if m==1 or m==4 or m==5 then return 53,cost.road end
   if m==2 or m==8 or m==10 then return 54,cost.road end
   return 16,cost.road
  end
  if is_buildable(x,y) then return 16,cost.road end
  if s==3 then return 59,cost.bridge end
 elseif t.name=="power line" then
  if is_buildable(x,y) then return 80,cost.line end
  if s==3 then return 61,cost.line*4 end
  if s==26 then return 53,cost.line end
  if s==21 then return 54,cost.line end
 elseif t.put then
  if open then return t.put,cost[t.costkey] end
 end
end

function apply_tool(quiet)
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
 if t.insp then
  do_inspect(x,y)
  return
 end
 local s=tile(x,y)
 if t.name=="bulldoze" then
  if s>3 and try_spend(s==5 and cost.blast or cost.dozer) then
   if s>=59 and s<=62 then
    set_tile(x,y,3)            -- bridge/pylon → water
   elseif s>=96 and s<=98 then
    set_zone(x,y,s-95,0)      -- zone rubble → empty plot
   elseif is_zone(x,y) and zone_density(x,y)>0 then
    set_zone(x,y,zone_kind(x,y),0) -- developed zone → empty plot
   else
    set_tile(x,y,1)            -- empty plot/anything else → grass
   end
   -- if this tile was burning, cancel the fire (prevents phantom rubble)
   local fk=x+y*64
   if dz_fmap and dz_fmap[fk] then
    dz_fmap[fk]=nil
    local nf={}
    for _,f in pairs(dz_fires) do
     if f.x~=x or f.y~=y then add(nf,f) end
    end
    dz_fires=nf
   end
   refresh_around(x,y)
   update_power()
   add_fx(x,y,3,0.2,-0.3,25,5,6)
   sfx(1)
   started=true
  end
  return
 end
 local put,c=tool_put(t,x,y)
 if not put then
  local already=(t.kind and zone_kind(x,y)==t.kind)
   or (t.name=="road" and is_road(x,y))
   or (t.name=="power line" and s>=80 and s<=95)
   or (t.put and s==t.put)
  if not quiet and not already then
   msg,msg_t="can't build there",60
   sfx(1)
  end
  return
 end
 if not try_spend(c) then return end
 set_tile(x,y,put)
 refresh_around(x,y)
 update_power()
 add_fx(x,y,4,0.5,0,20,7,10)
 sfx(0)
 started=true -- the clock runs once the first thing is built
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
 if s==61 or s==62 then
  -- pylons face along the wire crossing the water
  local h=conducts(x-1,y) or conducts(x+1,y)
  local v=conducts(x,y-1) or conducts(x,y+1)
  set_tile(x,y,h and not v and 62 or 61)
  return
 end
 if is_road(x,y) then
  local m=0
  if is_road(x,y-1) then m+=1 end
  if is_road(x+1,y) then m+=2 end
  if is_road(x,y+1) then m+=4 end
  if is_road(x-1,y) then m+=8 end
  set_tile(x,y,16+m)
 elseif s>=80 and s<=95 then
  -- wires bend toward anything conductive next door
  local m=0
  if conducts(x,y-1) then m+=1 end
  if conducts(x+1,y) then m+=2 end
  if conducts(x,y+1) then m+=4 end
  if conducts(x-1,y) then m+=8 end
  set_tile(x,y,80+m)
 end
end

function do_inspect(x,y)
 local s=tile(x,y)
 local k=zone_kind(x,y)
 if k then
  local d=zone_density(x,y)
  local st=not is_powered(x,y) and "no power"
   or not has_road_access(x,y) and "no road"
   or not net_ok(x,y,k,d) and (k==1 and "needs jobs" or "needs trade")
   or d<3 and "growing" or "thriving"
  msg,msg_t=({"r","c","i"})[k].." lv"..d.." "..st,120
 else
  msg,msg_t=tile_name(s),120
 end
end

local tl_names={"grass","trees","water","highland","mountain","road",
 "zone","crossing","bridge","pylon","power line","power plant",
 "city service","park","fire!","rubble - bulldoze it"}
function tile_name(s)
 return tl_names[tcl[s]] or "land"
end

function refresh_around(x,y)
 refresh_tile(x,y)
 refresh_tile(x-1,y)
 refresh_tile(x+1,y)
 refresh_tile(x,y-1)
 refresh_tile(x,y+1)
end
