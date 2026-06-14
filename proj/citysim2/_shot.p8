pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- _shot.p8 : dev screenshot harness (not shipped). lays a small test city,
-- renders tiles as colour blocks (no sprite art yet), saves a screenshot,
-- then shuts down so pico8 -x exits.
#include params.lua
#include data.lua
#include map.lua
#include router.lua

function tcol(s)
 if s==0 then return 1 end
 if s==2 then return 13 end
 if s>=16 and s<=31 then return 5 end
 if s>=32 and s<=47 then return 9 end
 if s>=48 and s<=51 then return 11 end
 if s>=52 and s<=55 then return 12 end
 if s>=56 and s<=59 then return 10 end
 return 3
end

function _init()
 cur={x=16,y=16}
 init_map()
 for x=4,28 do set_tile(x,16,16) end
 for y=4,28 do set_tile(16,y,16) end
 for x=5,11 do set_zone(x,13,1,2) set_zone(x,19,1,1) end
 for x=18,26 do set_zone(x,13,2,1) end
 for x=18,26 do set_zone(x,19,3,1) end
 fr=0
end

function _update()
 fr+=1
 if fr==3 then
  -- dump the 128x128 framebuffer (0x6000, 8k) into a companion cart's gfx
  cstore(0x0,0x6000,0x2000,"shot_fb.p8")
  extcmd("shutdown")
 end
end

function _draw()
 cls(0)
 for y=0,gw-1 do
  for x=0,gw-1 do
   rectfill(x*4,y*4,x*4+3,y*4+3,tcol(tile(x,y)))
  end
 end
 rectfill(0,0,80,6,0)
 print("citysim2 test city",1,1,7)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
