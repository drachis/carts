-- test_title.lua : the whole real cart, real scenery and main together,
-- from its first frame: it boots, runs and draws the title. kept tiny so
-- this cart is only ever limited by the game itself.
function sfx() end
music,dset=sfx,sfx
local n,game_draw,game_update=0,_draw,_update60
function _draw() end
function _update60()
 run_frame(function()
  n+=1
  game_update()
  game_draw()
  if n==20 then
   dump_screen("title")
   printh("ok title")
   extcmd("shutdown")
  end
 end)
end
