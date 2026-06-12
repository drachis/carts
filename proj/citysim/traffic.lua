-- traffic.lua : little cars driving on roads

tr_cars={}

function init_traffic()
 tr_cars={}
end

local tr_cols={7,8,10,12,14}
local tr_dirs={{dx=1,dy=0},{dx=-1,dy=0},{dx=0,dy=1},{dx=0,dy=-1}}

function update_traffic()
 -- spawn
 if frame%16==0 and pop>0 and #tr_cars<min(10,1+flr(pop/16)) then
  for attempt=1,8 do
   local x=flr(rnd(gridw))
   local y=flr(rnd(gridh))
   if is_road(x,y) then
    -- find valid neighbor dirs
    local valid={}
    for _,d in pairs(tr_dirs) do
     if is_road(x+d.dx,y+d.dy) then
      add(valid,d)
     end
    end
    if #valid>0 then
     local d=valid[1+flr(rnd(#valid))]
     add(tr_cars,{
      px=x*8+3,
      py=y*8+3,
      dx=d.dx,
      dy=d.dy,
      life=400,
      col=tr_cols[1+flr(rnd(#tr_cols))]
     })
    end
    break
   end
  end
 end

 -- move + update
 local keep={}
 for _,c in pairs(tr_cars) do
  c.px+=c.dx
  c.py+=c.dy
  c.life-=1
  local alive=c.life>0
  if alive and (c.px-3)%8==0 and (c.py-3)%8==0 then
   local tx=flr(c.px/8)
   local ty=flr(c.py/8)
   if not is_road(tx,ty) then
    alive=false
   else
    local valid={}
    for _,d in pairs(tr_dirs) do
     local notrev=(d.dx~=-c.dx or d.dy~=-c.dy)
     if is_road(tx+d.dx,ty+d.dy) and notrev then
      add(valid,d)
     end
    end
    if #valid==0 then
     -- only option: reverse
     local rev={dx=-c.dx,dy=-c.dy}
     if is_road(tx+rev.dx,ty+rev.dy) then
      add(valid,rev)
     else
      alive=false
     end
    end
    if alive then
     local keep_cur=false
     if #valid>0 then
      for _,d in pairs(valid) do
       if d.dx==c.dx and d.dy==c.dy then
        keep_cur=true
       end
      end
     end
     if keep_cur and rnd()<0.7 then
      -- keep direction
     elseif #valid>0 then
      local nd=valid[1+flr(rnd(#valid))]
      c.dx=nd.dx
      c.dy=nd.dy
     else
      alive=false
     end
    end
   end
  end
  if alive then
   add(keep,c)
  end
 end
 tr_cars=keep
end

function draw_traffic()
 for _,c in pairs(tr_cars) do
  rectfill(c.px-1,c.py-1,c.px,c.py,c.col)
 end
end
