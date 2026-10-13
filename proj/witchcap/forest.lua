-- forest.lua : the level. ground and branches are written into the map
-- (128 columns, rows 0..15); mushrooms are a list.
--
-- the forest is cut into cells five columns wide. the ground only changes
-- height between cells, by two tiles at most, and a branch sits three
-- tiles above its own cell's ground, so everything is within one jump of
-- somewhere. the three cells in the middle (columns 55..69) are the
-- clearing, flat and bare, with the cauldron at its centre.
-- tests/test_forest.lua walks generated forests to check.

function make_forest(seed)
 srand(seed)
 memset(0x2000,0,0x1000)
 mushrooms={}
 -- four of each true kind and three of each lookalike: one for each cell
 local kinds={}
 for kind=1,6 do
  for i=1,3+kind%2 do add(kinds,kind) end
 end
 local top=12
 for first=0,125,5 do
  local clearing=abs(first-62)<8
  if clearing then
   top=12
  else
   top=mid(9,top+flr(rnd(5))-2,13)
  end
  for column=first,min(first+4,127) do
   for row=top,15 do
    mset(column,row,row==top and 16 or 17)
   end
  end
  if not clearing and first>0 and first<125 then
   local column,row=first+flr(rnd(5)),top
   if rnd()<0.5 then
    for branch=first+1,first+3 do mset(branch,top-3,18) end
    if rnd()<0.7 then column,row=first+2,top-3 end
   end
   add(mushrooms,{x=column*8+4,y=row*8,kind=del(kinds,rnd(kinds))})
  end
 end
end

function ground_at(x,y)
 return fget(mget(x\8,y\8),0)
end

function draw_backdrop(camera_x)
 circfill(100,24,9,6)
 circfill(97,22,7,7)
 for tree=0,24 do
  local x=tree*29-camera_x\2
  rectfill(x,24+tree%3*9,x+3+tree%4,127,0)
  circfill(x+2,20+tree%3*9,10+tree%5*2,0)
 end
end

function draw_forest()
 map()
 spr(36,cauldron_x-8,80,2,2)
 -- the brew bubbles
 for bubble=0,2 do
  local rise=(t()*8+bubble*5)%12
  pset(cauldron_x-5+bubble*4,82-rise,11)
 end
 for mushroom in all(mushrooms) do
  spr(mushroom.kind,mushroom.x-4,mushroom.y-8)
 end
end
