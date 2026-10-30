-- test_title.lua : the whole real cart boots and runs 20 frames. no picture,
-- no helpers: this cart is only ever limited by the game itself.
local update,n=_update60,0
function _update60()
 n+=1
 update()
 if n==20 then
  printh("started\nok title","log_title",true)
  extcmd("shutdown")
 end
end
