-- test_forest.lua : generates a hundred forests and walks each from the
-- cauldron, to check that every mushroom can be reached and that the
-- recipe can always be filled.
--
-- the walk is a model, not the witch: from where she stands she may step
-- to the next column, or stay in her own, onto anything no more than
-- three tiles higher. test_witch.lua checks that the real witch can climb
-- three tiles and cannot climb four.

function music() end

local seed,branches,highest=0,0,15
lookalikes,seen_kinds=0,{}

-- the rows of a column that can be stood on
local function surfaces(column)
 local rows={}
 for row=1,15 do
  local tile=mget(column,row)
  if fget(tile,1) or fget(tile,0) and not fget(mget(column,row-1),0) then
   add(rows,row)
   highest=min(highest,row)
   if fget(tile,1) then branches+=1 end
  end
 end
 return rows
end

local function walk_forest()
 local stands={}
 for column=0,127 do stands[column]=surfaces(column) end
 local reached,queue={[64*16+clearing_row]=true},{{64,clearing_row}}
 while #queue>0 do
  local here=deli(queue)
  for step=-1,1 do
   -- round the join as well
   local column=(here[1]+step+128)%128
   for row in all(stands[column]) do
    if row>=here[2]-3 and not reached[column*16+row] then
     reached[column*16+row]=true
     add(queue,{column,row})
    end
   end
  end
 end
 return reached
end

local function check_forest()
 make_forest(seed)
 local reached=walk_forest()
 local counts,needed={},{}
 for kind=1,16 do counts[kind],needed[kind]=0,0 end
 for slot in all(recipe) do needed[slot.kind]+=1 end
 for mushroom in all(mushrooms) do
  counts[mushroom.kind]+=1
  seen_kinds[mushroom.kind]=true
  if needed[mushroom.kind]==0 then lookalikes+=1 end
  if not reached[mushroom.x\8*16+mushroom.y\8] then
   printh("error: seed "..seed.." has a mushroom out of reach at column "..mushroom.x\8)
  end
  if abs(mushroom.x-cauldron_x)<60 then
   printh("error: seed "..seed.." has a mushroom in the clearing")
  end
 end
 -- the recipe never asks twice for a kind; exactly one of each kind it
 -- wants grows; and everything else is a lookalike from a family it uses
 local wanted_families={}
 for kind=1,16 do
  if needed[kind]>0 then
   wanted_families[(kind-1)\4]=true
   if needed[kind]>1 or counts[kind]!=1 then
    printh("error: seed "..seed.." wants "..needed[kind].." of kind "..kind.." and grows "..counts[kind])
   end
  end
 end
 for kind=1,16 do
  if counts[kind]>0 and not wanted_families[(kind-1)\4] then
   printh("error: seed "..seed.." grows kind "..kind..", of a family the recipe does not use")
  end
 end
 if #recipe!=5 then
  printh("error: seed "..seed.." has a recipe of "..#recipe)
 end
 if #mushrooms!=22 then
  printh("error: seed "..seed.." has "..#mushrooms.." mushrooms")
 end
end

local game_draw=_draw
function _draw() end

function _update60()
 run_frame(forest_frame)
end

function forest_frame()
 for i=1,2 do
  seed+=1
  check_forest()
 end
 if seed==100 then
  printh("walked "..seed.." forests; "..branches/seed.." branch tiles each, highest footing row "..highest)
  local kinds_seen=0
  for kind=1,16 do
   if seen_kinds[kind] then kinds_seen+=1 end
  end
  printh(lookalikes/seed.." lookalikes in each forest of 22; "..kinds_seen.." of the 16 kinds grew somewhere")
  -- the left half of one forest, a screen at a time. the witch is
  -- only moved sideways to carry the camera, so she may hang in the air
  make_forest(7)
  reset_witch()
  reset_hut()
  reset_effects()
  mode="play"
  for screen=0,3 do
   witch.x=64+screen*128
   -- and the moon at four ages, from full to nearly gone
   frames_left=3600-screen*1100
   game_draw()
   dump_screen("forest_"..screen)
  end
  printh("ok forest")
  extcmd("shutdown")
 end
end
