-- tools.lua : cursor, tool palette, placement.
-- HEADER: cursor move/draw are live; apply_tool + tool_put are STUBS for an
-- agent to flesh out against the contract in the comments below.
-- api: init_tools, update_tools, apply_tool, tool_put, draw_cursor
--      globals: cur, tool, tools_list

-- tools: road / r-zone / c-zone / i-zone / power / plant / park / bulldoze.
-- ids 1..5 are stable; "park"/"bulldoze" are dispatched by NAME (below) so new
-- buildings can be inserted before bulldoze without re-indexing the logic.
tools_list=split"road,r-zone,c-zone,i-zone,power,plant,park,fire,bulldoze"
tool=1
local tb_lx,tb_ly=-1,-1  -- last tile painted (for drag-build)

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
 -- apply on press; hold + move the cursor to drag-build/bulldoze a line
 if btnp(5) then
  apply_tool() tb_lx,tb_ly=cur.x,cur.y
 elseif btn(5) and (cur.x~=tb_lx or cur.y~=tb_ly) then
  apply_tool() tb_lx,tb_ly=cur.x,cur.y
 end
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
  return (is_buildable(x,y) or tile(x,y)==0) and 16 or nil  -- roads bridge water
 elseif t==5 then
  return is_buildable(x,y) and 32 or nil
 elseif t>=2 and t<=4 then
  return is_buildable(x,y) and (48+(t-2)*4) or nil
 elseif t==6 then
  return is_buildable(x,y) and 60 or nil
 elseif tools_list[t]=="park" then
  return is_buildable(x,y) and 61 or nil
 elseif tools_list[t]=="fire" then
  return is_buildable(x,y) and 62 or nil
 elseif tools_list[t]=="bulldoze" then
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
 local before=tile(x,y)
 local n=tools_list[tool]
 if n=="bulldoze" then
  if peekp(pl_wire,x,y)>0 then
   -- peel the wire overlay first, leaving the road/water underneath
   if try_spend(cost.dozer) then pokep(pl_wire,x,y,0) update_net() end
  elseif tile(x,y)>1 and try_spend(cost.dozer) then
   set_tile(x,y,1)
   update_net()
  end
 elseif tool==6 then
  if is_buildable(x,y) and try_spend(cost.plant) then
   set_tile(x,y,60)
   update_net()
  end
 elseif n=="park" then
  if is_buildable(x,y) and try_spend(cost.park) then
   set_tile(x,y,61)
  end
 elseif n=="fire" then
  if is_buildable(x,y) and try_spend(cost.fire) then
   set_tile(x,y,62)
  end
 elseif tool>=2 and tool<=4 then
  if is_buildable(x,y) and try_spend(cost.zone) then
   set_zone(x,y,tool-1,0)
   pokep(pl_grace,x,y,p.grace)  -- new plot gets a year to settle
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
  if is_road(x,y) or tile(x,y)==0 then
   -- lay a wire crossing a road or water (overlay plane; the tile stays put)
   if peekp(pl_wire,x,y)==0 and try_spend(cost.power) then
    pokep(pl_wire,x,y,1)
    update_net()
   end
  elseif tool_put(5,x,y) and try_spend(cost.power) then
   set_tile(x,y,32+nmask(x,y,conducts))
   -- re-autotile only neighbouring power LINES (32..47); never a plant/zone
   for nb in all(neighbors4(x,y)) do
    if tile(nb.x,nb.y)>=32 and tile(nb.x,nb.y)<=47 then
     set_tile(nb.x,nb.y,32+nmask(nb.x,nb.y,conducts))
    end
   end
   update_net()
  end
 end
 -- dust kick + sound on any successful change; deny blip if nothing happened
 local now=tile(x,y)
 if now~=before then
  if fx_burst then fx_burst(x*8+4,y*8+4,before>1 and 5 or 6,5) end
  if snd then snd(before>1 and snd_doze or snd_place) end
  -- queue the land value the change touched; the rest of the map stays static.
  if val_dirty_area then val_dirty_area(x,y) end
  -- coverage only changes when a station/park is built or removed: refresh then.
  if update_cov and (before==61 or before==62 or now==61 or now==62) then
   update_cov()
  end
 elseif snd and n~="bulldoze" then
  snd(snd_deny)
 end
end

function draw_cursor()
 -- live: outline the cursor tile (caller has set camera to world space)
 local x,y=cur.x*8,cur.y*8
 rect(x,y,x+7,y+7,7)
end

-- each tool's icon is its own tile sprite (sprite id == tile id); bulldoze=X.
-- cost keys line up with tools_list so the label can show the price.
local tb_spr=split"16,48,52,56,32,60,61,62,-1"
local tb_cost=split"road,zone,zone,zone,power,plant,park,fire,dozer"

-- bottom tool palette: always-visible icons (no more blind cycling), current
-- tool boxed, with its name + cost beside the strip. runs in SCREEN space.
function draw_toolbar()
 rectfill(0,118,127,127,0)
 for i=1,#tools_list do
  local x=1+(i-1)*9
  local s=tb_spr[i]
  if s>=0 then spr(s,x,119)
  else line(x+1,120,x+6,125,8) line(x+6,120,x+1,125,8) end -- bulldoze X
  if i==tool then rect(x-1,118,x+8,127,7) end
 end
 -- tool name + cost on ONE line in the space right of the icons
 local lx=1+#tools_list*9+1
 local ck=tb_cost[tool]
 local lbl=tools_list[tool]..(ck and cost[ck] and " $"..cost[ck] or "")
 print(lbl,min(lx,128-#lbl*4),121,10)
end
