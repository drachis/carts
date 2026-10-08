-- test_run.lua : headless soak test, included by test_run.p8 right after
-- wyrmfire.lua. the include shares one chunk, so the game's locals are
-- visible here.
--
-- flies a scripted, immortal dragon at camelot for a few thousand frames
-- of update+draw, prints stats, dumps one frame to shot_fb.p8 and exits.

local SOAK_FRAMES=2400
local SCREEN_ADDR,SCREEN_BYTES=0x6000,0x2000

local fake_buttons={}
function btn(i) return fake_buttons[i] end
function btnp(i) return fake_buttons[i] end
function sfx() end

_init()
state=STATE.PLAY

local max_units,max_particles,max_fires=0,0,0
local shot_saved=false

for n=1,SOAK_FRAMES do
 -- head for camelot, breathing in bursts and charging now and then
 local dx=camelot.center_x-dragon.x
 local dy=camelot.center_y-dragon.y
 local playing=state==STATE.PLAY
 fake_buttons[BTN.LEFT],fake_buttons[BTN.RIGHT]=dx<-8,dx>8
 fake_buttons[BTN.UP],fake_buttons[BTN.DOWN]=dy<-8,dy>8
 fake_buttons[BTN.FIRE]=playing and n%90<60
 fake_buttons[BTN.CHARGE]=playing and n%50==0

 _update()
 _draw()
 dragon.hp=max(dragon.hp,50)

 max_units=max(max_units,#units)
 max_particles=max(max_particles,#particles)
 max_fires=max(max_fires,#fires)

 -- screenshot mid-breath, once the fight is under way
 local mid_breath=fake_buttons[BTN.FIRE] and n%90>20
 if n>=400 and not shot_saved and mid_breath and dragon.flash==0 then
  shot_saved=true
  cstore(0,SCREEN_ADDR,SCREEN_BYTES,"shot_fb.p8")
 end
end

printh("ok state="..state.." score="..score.." kills="..kills
 .." wrath="..wrath.." legends="..legends_sent)
printh("buildings "..#buildings.."/"..building_total
 .." max units="..max_units.." particles="..max_particles.." fires="..max_fires)
extcmd("shutdown")
