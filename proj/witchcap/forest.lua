-- forest.lua : the level. ground and branches are written into the map
-- (128 columns, rows 0..15); mushrooms are a list. make_forest also
-- draws up the run's recipe, since what grows depends on it.
--
-- the forest is cut into cells five columns wide. the ground only changes
-- height between cells, by two tiles at most, and a branch sits three
-- tiles above its own cell's ground, so everything is within one jump of
-- somewhere. the three cells in the middle (columns 55..69) are the
-- clearing, flat and bare, with the cauldron at its centre. the ground
-- is kept low on the screen (rows highest_row..lowest_row) to leave the
-- sky to the hut.
-- tests/test_forest.lua walks generated forests to check.

function make_forest(seed)
 srand(seed)
 new_recipe()
 -- only the sixteen rows the forest uses
 memset(0x2000,0,0x800)
 mushrooms={}
 -- what grows, one to a cell: every mushroom the recipe wants, a spare
 -- of each kind it wants, and for the rest their lookalikes, which are
 -- the other forms of the same families
 local kinds,wanted={},{}
 for slot in all(recipe) do
  add(kinds,slot.kind)
  if not wanted[slot.kind] then
   wanted[slot.kind]=true
   add(kinds,slot.kind)
  end
 end
 while #kinds<21 do
  local lookalike=(rnd(recipe).kind-1)\4*4+flr(rnd(4))+1
  if not wanted[lookalike] then add(kinds,lookalike) end
 end
 local top=clearing_row
 for first=0,125,5 do
  local clearing=abs(first-62)<8
  if clearing then
   top=clearing_row
  else
   top=mid(highest_row,top+flr(rnd(5))-2,lowest_row)
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

-- the height of the ground's surface at x, in pixels down the screen
function ground_top(x)
 for row=0,15 do
  if ground_at(x,row*8) then return row*8 end
 end
 return 128
end

-- a flat clump of leaves with moss hanging from it in strands
function draw_moss(x,y,seed)
 ovalfill(x-11,y-3,x+11,y+3,0)
 for strand=0,20,3 do
  local strand_x=x-10+strand
  line(strand_x,y,strand_x,y+5+(strand*7+seed*5)%10,0)
 end
end

-- a swamp tree: a leaning trunk that spreads at the foot, and two limbs
function draw_tree(x,top,seed)
 local crown=x+seed%5*2-4
 for offset=-5,5 do
  line(x+offset,127,crown+offset/4,top,0)
 end
 for side=-1,1,2 do
  local limb_x=crown+side*(13+(seed+side)%3*4)
  local limb_y=top-2-(seed+side)%4*2
  line(crown,top+8,limb_x,limb_y,0)
  line(crown,top+9,limb_x,limb_y+1,0)
  draw_moss(limb_x,limb_y,seed+side)
 end
 draw_moss(crown,top-2,seed)
end

-- the moon is the clock: `moon` is the share of the time left, 1 a full
-- moon and 0 a new one. the whole disc is always there in shadow, and the
-- lit part wanes across it the way the moon's does: always lit from the
-- left limb, as far as an edge that goes from the right limb through a
-- half moon to a crescent. it is always in the top right corner, and is
-- drawn over the hut so that nothing ever hides the clock.
function draw_moon(moon)
 circfill(116,12,9,5)
 for row=-9,9 do
  local half=sqrt(81-row*row)
  local lit=half*(moon*2-1)
  if lit>-half then
   rectfill(116-half,12+row,116+lit,12+row,7)
   pset(116+lit,12+row,6)
  end
 end
end

function draw_backdrop(camera_x)
 -- stars that stay put, each winking out now and then
 for star=1,24 do
  if (t()/3+star/7)%1<0.85 then
   pset(star*37%128,star*23%70,star%3==0 and 7 or 13)
  end
 end
 for tree=1,17 do
  draw_tree(tree*44-30-camera_x\2,40+tree%3*11,tree)
 end
 -- three bats cross the sky, each at its own pace and height
 for bat=1,3 do
  local x=t()/(6+bat*3)%1*200-36
  if bat==2 then x=120-x end
  spr(19+(t()*6+bat)%2\1,x,10+bat*9+sin(t()/2+bat/3)*5)
 end
end

function draw_forest()
 map()
 local cauldron_y=clearing_row*8-16
 -- the pot is drawn in grey and shown as black iron
 pal(5,0)
 spr(46,cauldron_x-8,cauldron_y,2,2)
 pal(5,5)
 -- the brew bubbles
 for bubble=0,2 do
  local rise=(t()*8+bubble*5)%12
  pset(cauldron_x-5+bubble*4,cauldron_y+2-rise,11)
 end
 for mushroom in all(mushrooms) do
  -- they dance, each on its own beat: a hop, and a lean on every other
  -- one. kind k is sprite 95+k, and its leaning step is the sprite below
  local beat=t()*2+mushroom.x/40
  spr(95+mushroom.kind+beat%2\1*16,mushroom.x-4,mushroom.y-8-abs(sin(beat/2))*2)
 end
end
