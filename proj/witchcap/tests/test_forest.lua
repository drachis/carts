-- test_forest.lua : generates a hundred forests and walks each from the
-- cauldron, to check that every mushroom can be reached and that the
-- recipe can always be filled.
--
-- the walk is a model, not the witch: from where she stands she may step
-- to the next column, or stay in her own, onto anything no more than
-- three tiles higher. test_witch.lua checks that the real witch can climb
-- three tiles and cannot climb four.

local seed,branches,highest=0,0,15

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
  for column=max(here[1]-1),min(here[1]+1,127) do
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
 local counts={0,0,0,0,0,0}
 for mushroom in all(mushrooms) do
  counts[mushroom.kind]+=1
  if not reached[mushroom.x\8*16+mushroom.y\8] then
   printh("error: seed "..seed.." has a mushroom out of reach at column "..mushroom.x\8)
  end
  if abs(mushroom.x-cauldron_x)<60 then
   printh("error: seed "..seed.." has a mushroom in the clearing")
  end
 end
 for kind=1,5,2 do
  if counts[kind]!=4 then
   printh("error: seed "..seed.." has "..counts[kind].." of kind "..kind)
  end
 end
 if #mushrooms!=21 then
  printh("error: seed "..seed.." has "..#mushrooms.." mushrooms")
 end
end

local game_draw=_draw
function _draw() end

function _update60()
 for i=1,2 do
  seed+=1
  check_forest()
 end
 if seed==100 then
  printh("walked "..seed.." forests; "..branches/seed.." branch tiles each, highest footing row "..highest)
  -- the left half of one forest, a screen at a time. the witch is
  -- only moved sideways to carry the camera, so she may hang in the air
  make_forest(7)
  new_recipe()
  reset_witch()
  reset_hut()
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
