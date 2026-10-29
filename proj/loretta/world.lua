level_w=1024

function flag_at(x,y,flag)
 if x<0 or x>=level_w then return flag==0 end
 return fget(mget(x\8,y\8),flag)
end

function area_has(x,y,w,h,flag)
 for dy=0,h+2,4 do
  for dx=0,w+2,4 do
   if flag_at(x+min(dx,w-1),y+min(dy,h-1),flag) then return true end
  end
 end
 return false
end

function on_ledge(x,y,w,h,ignore_branches)
 local below=flr(y)+h
 return area_has(x,below,w,1,0) or not ignore_branches and below%8==0 and area_has(x,below,w,1,1)
end

function overlaps(a,b)
 return a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h
end

function load_level()
 reload(0x2000,0x2000,0x1000)
 things={}
 for cell_y=0,15 do
  for cell_x=0,127 do
   local spec=thing_specs[mget(cell_x,cell_y)]
   if spec then
    mset(cell_x,cell_y,0)
    add(things,setmetatable({x=cell_x*8+spec.dx,y=cell_y*8+spec.dy,vx=0,vy=0,age=0,petting=0},spec))
   end
  end
 end
end
