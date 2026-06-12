-- landval.lua : coarse land-value / pollution model

lv_grid={}

function init_landval()
 lv_grid={}
 -- count rock per cell once: mountain walls block smog drift
 lv_mtn={}
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   if tile(x,y)==5 then
    local ci=flr(x/4)+flr(y/4)*12
    lv_mtn[ci]=(lv_mtn[ci] or 0)+1
   end
  end
 end
end

-- cell-grid (12x12) accessors with their own bounds check.
-- negative spread (pollution) cannot drift into a mostly-rock cell.
function lv_add(cx,cy,v)
 if cx>=0 and cx<12 and cy>=0 and cy<12 then
  local ci=cx+cy*12
  if v<0 and (lv_mtn[ci] or 0)>4 then return end
  lv_grid[ci]=(lv_grid[ci] or 0)+v
 end
end

function lv_blob(cx,cy,own,nbv)
 lv_add(cx,cy,own)
 lv_add(cx-1,cy,nbv)
 lv_add(cx+1,cy,nbv)
 lv_add(cx,cy-1,nbv)
 lv_add(cx,cy+1,nbv)
end

function update_landval()
 if frame%64~=0 then return end
 lv_grid={}
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   local s=tile(x,y)
   local cx,cy=flr(x/4),flr(y/4)
   if s>=40 and s<=43 then
    lv_blob(cx,cy,-(s-38),-1) -- industry: -(2+density)
   elseif s==48 then
    lv_blob(cx,cy,-3,-1)
   elseif s==44 then
    lv_blob(cx,cy,2,1)
   elseif s==65 or s==66 then
    -- police and schools raise property values
    lv_blob(cx,cy,2,1)
   elseif s==55 then
    lv_add(cx,cy,-2)
   elseif s==56 then
    lv_add(cx,cy,-1)
   elseif s==2 or s==3 or s==4 then
    lv_add(cx,cy,0.25) -- trees, water, highland views
   elseif s==5 then
    lv_add(cx,cy,0.5)  -- mountain scenery
   end
  end
 end
end

function land_value(x,y)
 local ci=flr(x/4)+flr(y/4)*12
 local v=lv_grid[ci] or 0
 return mid(-6,v,6)
end

function growth_mult(x,y,k)
 local v=land_value(x,y)
 if k==1 then return mid(0.25,1+v/6,1.75)
 elseif k==2 then return mid(0.5,1+v/12,1.4)
 end
 return 1
end
