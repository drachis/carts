local frame=0
function sfx() end
music,dset=sfx,sfx
local game_update=_update60
function _update60()
 if frame==0 then
  printh("started","cap_title",true)
  extcmd("set_filename","loretta_title")
  extcmd("rec")
 end
 frame+=1
 game_update()
 if frame==120 then extcmd("screen") end
 if frame==300 then
  extcmd("video")
  printh("ok cap_title","cap_title")
 end
end
