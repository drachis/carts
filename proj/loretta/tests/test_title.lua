-- test_title.lua : the whole real cart boots and runs half a second. no
-- picture, no helpers: this cart is only ever limited by the game itself.
local update=_update60
function _update60()
 update()
 if t()>0.5 then
  printh("started\nok title","log_title",true)
 end
end
