-- map.lua : grid helpers, plane accessors, camera
-- tile encoding (range checks only; no fget):
--   0 water (not buildable)   1 grass (buildable)   2 mountain (not buildable)
--   roads    16..31 = 16 + nmask(n=1 e=2 s=4 w=8)
--   powerlines 32..47 = 32 + nmask
--   residential 48..51 = 48 + density(0..3)
--   commercial  52..55 = 52 + density
--   industrial  56..59 = 56 + density

gw=p.grid  -- 32

function in_bounds(x,y)
 return x>=0 and y>=0 and x<gw and y<gw
end

function tile(x,y)
 return in_bounds(x,y) and mget(x,y) or 0
end

function set_tile(x,y,s)
 if in_bounds(x,y) then mset(x,y,s) end
end

-- tile predicates (id-range checks; no fget)
function is_road(x,y)
 local s=tile(x,y) return s>=16 and s<=31
end

function is_zone(x,y)
 local s=tile(x,y) return s>=48 and s<=59
end

function is_buildable(x,y)
 local s=tile(x,y) return s==1
end

function conducts(x,y)
 local s=tile(x,y) return (s>=32 and s<=47) or s==60 or s==65 -- lines + plants
end

-- zone helpers
function zone_kind(x,y)
 if not is_zone(x,y) then return nil end
 return flr((tile(x,y)-48)/4)+1
end

function zone_density(x,y)
 if not is_zone(x,y) then return nil end
 return (tile(x,y)-48)%4
end

function set_zone(x,y,kind,density)
 set_tile(x,y,48+(kind-1)*4+density)
end

-- orthogonal in-bounds neighbours
function neighbors4(x,y)
 local n={}
 if in_bounds(x,y-1) then add(n,{x=x,y=y-1}) end
 if in_bounds(x+1,y) then add(n,{x=x+1,y=y}) end
 if in_bounds(x,y+1) then add(n,{x=x,y=y+1}) end
 if in_bounds(x-1,y) then add(n,{x=x-1,y=y}) end
 return n
end

-- autotile bitmask: n=1 e=2 s=4 w=8 where f(x,y) is predicate
function nmask(x,y,f)
 local m=0
 if f(x,y-1) then m+=1 end
 if f(x+1,y) then m+=2 end
 if f(x,y+1) then m+=4 end
 if f(x-1,y) then m+=8 end
 return m
end

-- 0x8000 plane accessors (index = x + y*gw).
-- named peekp/pokep so they don't shadow pico-8 builtins pget/pset.
function peekp(base,x,y)
 if not in_bounds(x,y) then return 0 end
 return peek(base+x+y*gw)
end

function pokep(base,x,y,v)
 if in_bounds(x,y) then poke(base+x+y*gw,v) end
end

function pclr(base)
 memset(base,0,gw*gw)
end

-- camera (pixel-smooth ease toward cursor)
camx,camy=0,0

-- the playfield is the screen between the top HUD (7px) and bottom toolbar
-- (10px). keep the cursor inside it, and let camy dip to -7 / rise so the edge
-- rows sit just below the HUD / above the toolbar (not hidden under either).
function update_camera(snap)
 local px,py=cur.x*8,cur.y*8
 local tx,ty=camx,camy
 if px-tx<16  then tx=px-16  end
 if px-tx>104 then tx=px-104 end
 if py-ty<16  then ty=py-16  end
 if py-ty>100 then ty=py-100 end
 tx=mid(0,tx,gw*8-128)
 ty=mid(-7,ty,gw*8-118)
 if snap then
  camx,camy=tx,ty
 else
  camx+=mid(-4,tx-camx,4)
  camy+=mid(-4,ty-camy,4)
 end
end

-- init: clear tile grid to grass; zero all planes
function init_map()
 for y=0,gw-1 do
  for x=0,gw-1 do
   mset(x,y,1)
  end
 end
 pclr(pl_elev)
 pclr(pl_comp)
 pclr(pl_cap)
 pclr(pl_fill)
 pclr(pl_cong)
 pclr(pl_need)
 pclr(pl_wire)
 pclr(pl_grace)
 pclr(pl_pow)
 pclr(pl_chg)
 camx,camy=0,0
end
