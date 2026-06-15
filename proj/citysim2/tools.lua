-- tools.lua : cursor, tool palette, placement.
-- HEADER: cursor move/draw are live; apply_tool + tool_put are STUBS for an
-- agent to flesh out against the contract in the comments below.
-- api: init_tools, update_tools, apply_tool, tool_put, draw_cursor
--      globals: cur, tool, tools_list

-- tool ids: 1 road  2 r-zone  3 c-zone  4 i-zone  5 power  6 bulldoze
tools_list=split"road,r-zone,c-zone,i-zone,power,bulldoze"
tool=1

function init_tools()
 cur={x=16,y=16}
 tool=1
end

function update_tools()
 -- cursor (live): dpad moves, button O (4) cycles tool, button X (5) applies.
 if btnp(0) then cur.x=max(0,cur.x-1) end
 if btnp(1) then cur.x=min(gw-1,cur.x+1) end
 if btnp(2) then cur.y=max(0,cur.y-1) end
 if btnp(3) then cur.y=min(gw-1,cur.y+1) end
 if btnp(4) then tool=tool%#tools_list+1 end
 if btnp(5) then apply_tool() end
 update_camera()
end

-- STUB (agent: flesh out). what id the current tool would place at x,y, or nil
-- if invalid. used by the ghost preview + apply_tool.
--   road(1)   -> 16 (autotiled by refresh) on buildable(grass) ; nil otherwise
--   r/c/i(2,3,4) -> a zone plot (set via set_zone(x,y,kind,0)) on buildable
--   power(5)  -> 32 (autotiled) on buildable
--   bulldoze(6) -> 1 (grass) on anything > grass
function tool_put(t,x,y)
 if t==1 then
  return is_buildable(x,y) and 16 or nil
 elseif t==5 then
  return is_buildable(x,y) and 32 or nil
 elseif t>=2 and t<=4 then
  return is_buildable(x,y) and (48+(t-2)*4) or nil
 elseif t==6 then
  return tile(x,y)>1 and 1 or nil
 end
 return nil
end

-- STUB (agent: flesh out). place the current tool at cur:
--   - validate via tool_put / is_buildable; zones use set_zone(x,y,kind,0),
--     roads/power use set_tile then refresh autotile of the tile + 4 neighbours
--     (set_tile(16+nmask(...,is_road)) / 80? no — power 32+nmask(...,conducts)).
--   - bulldoze -> set_tile(cur.x,cur.y,1).
--   - after any change: update_net(); and for a NEW zone tile, schedule a sim
--     eval: schedule(0,{k=1,x=cur.x,y=cur.y}) so the sim picks it up live.
function apply_tool()
 local x,y=cur.x,cur.y
 if tool==6 then
  if tile(x,y)>1 and try_spend(cost.dozer) then
   set_tile(x,y,1)
   update_net()
  end
 elseif tool>=2 and tool<=4 then
  if is_buildable(x,y) and try_spend(cost.zone) then
   set_zone(x,y,tool-1,0)
   update_net()
   schedule(0,{k=1,x=x,y=y})
  end
 elseif tool==1 then
  if tool_put(1,x,y) and try_spend(cost.road) then
   set_tile(x,y,16+nmask(x,y,is_road))
   for nb in all(neighbors4(x,y)) do
    if is_road(nb.x,nb.y) then
     set_tile(nb.x,nb.y,16+nmask(nb.x,nb.y,is_road))
    end
   end
   update_net()
  end
 elseif tool==5 then
  if tool_put(5,x,y) and try_spend(cost.power) then
   set_tile(x,y,32+nmask(x,y,conducts))
   for nb in all(neighbors4(x,y)) do
    if conducts(nb.x,nb.y) then
     set_tile(nb.x,nb.y,32+nmask(nb.x,nb.y,conducts))
    end
   end
   update_net()
  end
 end
end

function draw_cursor()
 -- live: outline the cursor tile (caller has set camera to world space)
 local x,y=cur.x*8,cur.y*8
 rect(x,y,x+7,y+7,7)
end
