function level_tile(cell_x,cell_y)
 local chunk=level_chunks[cell_x\32+1]
 if not chunk or cell_y<0 or cell_y>15 then return 0 end
 return mget(chunk%4*32+cell_x%32,chunk\4*16+cell_y)
end

function flag_at(x,y,flag)
 if x<0 or x>=level_w then return flag==0 end
 x,y=flr(x),flr(y)
 local tile=level_tile(x\8,y\8)
 if not fget(tile,flag) then return false end
 return flag>0 or fget(tile,3) and y%8>=7-x%8 or fget(tile,4) and y%8>=x%8 or not (fget(tile,3) or fget(tile,4))
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
 level_chunks=levels[level]
 level_w,things=#level_chunks*256,{}
 for cell_y=0,15 do
  for cell_x=0,#level_chunks*32-1 do
   local spec=thing_specs[level_tile(cell_x,cell_y)]
   if spec then
    add(things,setmetatable({x=cell_x*8+spec.dx,y=cell_y*8+spec.dy,vx=0,vy=0,age=0,petting=0},spec))
   end
  end
 end
end

function draw_level(cam)
 for i=cam\256+1,(cam+127)\256+1 do
  local chunk=level_chunks[i]
  if chunk then map(chunk%4*32,chunk\4*16,i*256-256,0,32,16,0x80) end
 end
end
