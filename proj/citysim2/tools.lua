-- tools.lua : cursor + a 2D, data-driven tool palette + placement.
-- palette is COLUMNS (left/right = category) of TOOLS (up/down = type). press O
-- to enter pick-mode (dpad drives the palette), O/X to leave. adding a building
-- is one data row. each tool is a POSITIONAL array (keys cost tokens):
--   [1]=name [2]=icon-sprite [3]=cost-key [4]=place-code [5]=arg
--   place-code: z zone(arg=kind) · r road · w power · b building(arg=tile) · d doze
-- api: init_tools, update_tools, apply_tool, cur_tool, select_tool, draw_*,
--      globals: cur, tcat, trow, picking
cats={
 {{"road",16,"road","r"}},                                         -- roads
 {{"r-zone",48,"zone","z",1},{"c-zone",52,"zone","z",2},{"i-zone",56,"zone","z",3}}, -- zones
 {{"power",42,"power","w"},{"plant",60,"plant","b",60},{"big plant",65,"bigplant","b",65}}, -- power
 {{"park",61,"park","b",61},{"fire",62,"fire","b",62},{"recycle",64,"recycle","b",64}}, -- services
 {{"bulldoze",-1,"dozer","d"}},                                    -- bulldozer
}
tcat=1
trow={}  -- selected row per category; filled by init_tools (one per #cats)
picking=false
local tb_lx,tb_ly=-1,-1  -- last tile painted (drag-build)
for i=1,#cats do trow[i]=1 end

function cur_tool() return cats[tcat][trow[tcat]] end

-- focus a tool by name (used by tests + any hotkey)
function select_tool(name)
 for ci=1,#cats do
  for ri=1,#cats[ci] do
   if cats[ci][ri][1]==name then tcat=ci trow[ci]=ri return end
  end
 end
end

function init_tools()
 cur={x=16,y=16}
 tcat=1 picking=false
 for i=1,#cats do trow[i]=1 end
end

function update_tools()
 if picking then
  -- dpad drives the palette: left/right category, up/down type
  if btnp(0) then tcat=max(1,tcat-1) end
  if btnp(1) then tcat=min(#cats,tcat+1) end
  -- up moves UP the fan (toward higher rows, which draw higher on screen)
  if btnp(2) then trow[tcat]=min(#cats[tcat],trow[tcat]+1) end
  if btnp(3) then trow[tcat]=max(1,trow[tcat]-1) end
  if btnp(4) or btnp(5) then picking=false end
 else
  if btnp(0) then cur.x=max(0,cur.x-1) end
  if btnp(1) then cur.x=min(gw-1,cur.x+1) end
  if btnp(2) then cur.y=max(0,cur.y-1) end
  if btnp(3) then cur.y=min(gw-1,cur.y+1) end
  if btnp(4) then picking=true end
  -- apply on press; hold + move to drag-build/bulldoze a line
  if btnp(5) then
   apply_tool() tb_lx,tb_ly=cur.x,cur.y
  elseif btn(5) and (cur.x~=tb_lx or cur.y~=tb_ly) then
   apply_tool() tb_lx,tb_ly=cur.x,cur.y
  end
  update_camera()
 end
end

function apply_tool()
 local x,y=cur.x,cur.y
 local before=tile(x,y)
 local t=cur_tool()
 local pc=t[4]
 if pc=="d" then
  if peekp(pl_wire,x,y)>0 then            -- peel a wire overlay first
   if try_spend(cost.dozer) then pokep(pl_wire,x,y,0) update_net() end
  elseif is_zone(x,y) and zone_density(x,y)>0 then
   -- raze the BUILDING but keep the zoning (v1 lesson); it can rebuild
   if try_spend(cost.dozer) then
    set_zone(x,y,zone_kind(x,y),0) pokep(pl_sat,x,y,p.sat_seed) update_net()
   end
  elseif tile(x,y)>1 and try_spend(cost.dozer) then
   set_tile(x,y,1)                     -- empty zone / road / building -> grass
   -- re-autotile neighbouring roads / power lines so a removed junction resets
   -- (an L-corner left after dozing the rest of a box collapses to a stub).
   for nb in all(neighbors4(x,y)) do
    if is_road(nb.x,nb.y) then set_tile(nb.x,nb.y,16+nmask(nb.x,nb.y,is_road))
    elseif tile(nb.x,nb.y)>=32 and tile(nb.x,nb.y)<=47 then
     set_tile(nb.x,nb.y,32+nmask(nb.x,nb.y,conducts)) end
   end
   update_net()
  end
 elseif pc=="b" then                       -- a building on grass
  if is_buildable(x,y) and try_spend(cost[t[3]]) then
   set_tile(x,y,t[5]) update_net()
  end
 elseif pc=="z" then                       -- a zone plot (settling grace)
  if is_buildable(x,y) and try_spend(cost.zone) then
   set_zone(x,y,t[5],0) pokep(pl_sat,x,y,p.sat_seed)
   update_net() schedule(0,{k=1,x=x,y=y})
  end
 elseif pc=="r" then                       -- road (bridges water)
  if (is_buildable(x,y) or tile(x,y)==0) and try_spend(cost.road) then
   set_tile(x,y,16+nmask(x,y,is_road))
   for nb in all(neighbors4(x,y)) do
    if is_road(nb.x,nb.y) then set_tile(nb.x,nb.y,16+nmask(nb.x,nb.y,is_road)) end
   end
   update_net()
  end
 elseif pc=="w" then                       -- power: wire over road/water else line
  if is_road(x,y) or tile(x,y)==0 then
   if peekp(pl_wire,x,y)==0 and try_spend(cost.power) then pokep(pl_wire,x,y,1) update_net() end
  elseif is_buildable(x,y) and try_spend(cost.power) then
   set_tile(x,y,32+nmask(x,y,conducts))
   for nb in all(neighbors4(x,y)) do
    if tile(nb.x,nb.y)>=32 and tile(nb.x,nb.y)<=47 then
     set_tile(nb.x,nb.y,32+nmask(nb.x,nb.y,conducts))
    end
   end
   update_net()
  end
 end
 -- dust + sound on a real change; deny blip otherwise
 local now=tile(x,y)
 if now~=before then
  if fx_burst then fx_burst(x*8+4,y*8+4,before>1 and 5 or 6,5) end
  if snd then snd(before>1 and snd_doze or snd_place) end
  if val_dirty_area then val_dirty_area(x,y) end
  if update_cov and (before==61 or before==62 or now==61 or now==62) then update_cov() end
 elseif snd and pc~="d" then
  snd(snd_deny)
 end
end

function draw_cursor()
 local x,y=cur.x*8,cur.y*8
 rect(x,y,x+7,y+7,7)
end

local function tb_icon(i,x,y)
 if i>=0 then spr(i,x,y)
 else line(x+1,y+1,x+6,y+6,8) line(x+6,y+1,x+1,y+6,8) end -- bulldoze X
end

-- bottom palette: one slot per category showing its current tool; the active
-- category is boxed and, while picking, its types fan upward (up/down to choose).
function draw_toolbar()
 rectfill(0,118,127,127,0)
 for ci=1,#cats do
  local x=1+(ci-1)*9
  tb_icon(cats[ci][trow[ci]][2],x,119)
  -- chevron hint: this category has more types stacked (up/down to reveal)
  if #cats[ci]>1 then pset(x+3,117,7) pset(x+2,118,7) pset(x+4,118,7) end
  if ci==tcat then rect(x-1,118,x+8,127,7) end
 end
 if picking then
  local x=1+(tcat-1)*9
  for ri=1,#cats[tcat] do
   local y=118-ri*9
   rectfill(x-1,y-1,x+8,y+8,0)
   tb_icon(cats[tcat][ri][2],x,y)
   if ri==trow[tcat] then rect(x-1,y-1,x+8,y+8,7) end
  end
 end
 local t=cur_tool()
 local lbl=t[1]..(cost[t[3]] and " $"..cost[t[3]] or "")
 print(lbl,min(1+#cats*9+2,128-#lbl*4),121,10)
end
