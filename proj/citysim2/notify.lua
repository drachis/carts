-- notify.lua : event log — the city narrates itself ("the sim explains itself").
-- a small ring of recent notable events; sim/disaster push, hud draws a fading
-- ticker bottom-left. each entry keeps its tile so callers can flag location.
-- api: init_log, notify(msg,col,x,y), draw_log; global: log
log={}

function init_log() log={} end

-- push a notice. col defaults white; x,y optional (the tile it happened on).
function notify(msg,col,x,y)
 add(log,{m=msg,c=col or 7,x=x,y=y,t=0})
 while #log>8 do deli(log,1) end
end

-- fading ticker: newest at the bottom, dimming over ~4s, then dropped.
function draw_log()
 for i=#log,1,-1 do
  log[i].t+=1
  if log[i].t>=120 then deli(log,i) end
 end
 local n=min(#log,4)
 for i=1,n do
  local e=log[#log-i+1]
  print(e.m,2,113-(i-1)*6,e.t>90 and 5 or e.c)
 end
end
