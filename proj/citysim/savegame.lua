-- savegame.lua : save/load via cstore to a companion cart, plus new city.
-- scalar state rides along in map ram at row 0, x=49.. (outside the 48x48
-- grid), so one cstore of the map region carries everything.

function save_city()
 mset(49,0,42) -- magic
 local v=money+32768
 mset(50,0,v%256)
 mset(51,0,flr(v/256))
 mset(52,0,month)
 mset(53,0,year-1900)
 mset(54,0,tax_rate)
 mset(55,0,milestone/10)
 cstore(0x1000,0x1000,0x2000,"citysave.p8")
 msg,msg_t="city saved",60
end

function load_city()
 reload(0x1000,0x1000,0x2000,"citysave.p8")
 if mget(49,0)~=42 then
  msg,msg_t="no saved city",60
  return
 end
 money=mget(50,0)+mget(51,0)*256-32768
 month=mget(52,0)
 year=1900+mget(53,0)
 tax_rate=mget(54,0)
 milestone=mget(55,0)*10
 post_load()
 msg,msg_t="city loaded",60
end

function new_city()
 init_map()
 init_econ()
 init_growth()
 post_load()
 cur={x=24,y=24}
 update_camera()
 msg,msg_t="new city founded",60
end

function post_load()
 -- rebuild all derived state; active fires don't survive a save
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   if tile(x,y)==55 then set_tile(x,y,56) end
  end
 end
 init_power()
 init_traffic()
 init_disaster()
 init_landval()
 update_power()
 if set_tax_item then set_tax_item() end
end
