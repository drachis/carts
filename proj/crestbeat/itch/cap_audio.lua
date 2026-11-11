local frames=0
function _update()
 frames+=1
 if frames==2 then
  music(0)
  extcmd("set_filename","crestbeat_music")
  extcmd("audio_rec")
 end
 if frames==2+24*30 then music(8) end
 if frames==2+40*30 then extcmd("audio_end") end
 if frames==2+43*30 then
  printh("ok cap_audio")
  extcmd("shutdown")
 end
 if frames%300==0 then printh("still recording") end
end
function _draw() cls() print(stat(50),2,2,7) end
printh("started")
