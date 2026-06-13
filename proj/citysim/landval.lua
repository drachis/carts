-- landval.lua : per-cell land value (no spreading; parks+, industry-)
lv_grid={}

function init_landval()
 lv_grid={}
end

function lv_tile(s,cx,cy)
 local ci=cx+cy*12
 if s>=40 and s<=43 then
  lv_grid[ci]=(lv_grid[ci] or 0)-(s-38)
 elseif s==48 then
  lv_grid[ci]=(lv_grid[ci] or 0)-3
 elseif s==44 or s==65 or s==66 then
  lv_grid[ci]=(lv_grid[ci] or 0)+2
 end
end

function land_value(x,y)
 return mid(-6,lv_grid[flr(x/4)+flr(y/4)*12] or 0,6)
end

function growth_mult(x,y,k)
 local v=land_value(x,y)
 if k==1 then return mid(0.25,1+v/6,1.75)
 elseif k==2 then return mid(0.5,1+v/12,1.4) end
 return 1
end
