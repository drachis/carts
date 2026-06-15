-- save.lua : save/load via cstore/reload to a companion cart. HEADER — stubs.
-- api: save_city, load_city
-- calls: money/month/year/tax_rate (econ); update_net, init_sim, sim_seed (sim);
--        init_agents (agents); pclr + pl_cong (map/data); gw, mset/mget.
-- layout (manual 6.7): tile grid lives in the map region 0x2000; the sim data
-- planes live at 0x8000 (6 planes x 1024 = 0x1800). companion cart "citysave2.p8"
-- must exist on disk. money is $k (store the integer part).

function save_city()
 local m=flr(money)
 mset(120,0,42)
 mset(121,0,m%256) mset(122,0,flr(m/256))
 mset(123,0,month) mset(124,0,year-1900) mset(125,0,tax_rate)
 cstore(0x2000,0x2000,0x1000,"citysave2.p8")
 cstore(0x0,0x8000,0x1800,"citysave2.p8")
 -- pl_wire (wire-over-road/water overlay) lives past the 0x9800 plane block, so
 -- save it separately into the free file gap at 0x1800 (before the 0x2000 grid).
 cstore(0x1800,pl_wire,0x400,"citysave2.p8")
 cstore(0x1c00,pl_bridge,0x400,"citysave2.p8")  -- bridge flags (free gap < grid)
end

function load_city()
 reload(0x2000,0x2000,0x1000,"citysave2.p8")
 if mget(120,0)~=42 then return end
 reload(0x8000,0x0,0x1800,"citysave2.p8")
 reload(pl_wire,0x1800,0x400,"citysave2.p8")  -- before update_net (it reads pl_wire)
 reload(pl_bridge,0x1c00,0x400,"citysave2.p8")
 money=mget(121,0)+mget(122,0)*256
 month=mget(123,0) year=1900+mget(124,0) tax_rate=mget(125,0)
 init_agents() pclr(pl_cong) update_net() init_sim() sim_seed()
end
