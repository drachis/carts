-- test_feel.lua : a bot plays the whole game three times, unhealed, and
-- prints a line per wave: how long it took, armour at the end, kills, most
-- foes on the hill at once, overheats, alpha strikes, hits taken.
--
-- the bot walks under the nearest foe, sidesteps a spit that is close,
-- holds fire while it has the heat to spare, swaps weapon when the one in
-- hand is reloading or has nothing in range, uses alpha when it has it and
-- takes the middle upgrade, and walks to a drop when nothing is close. it is a crude player: it measures how much is
-- going on and whether a plain strategy survives, not whether the game is
-- fun. spawns are random, so runs differ; that is why there are three.
--
-- headless pico-8 runs in real time, so the game is stepped several times
-- a frame and drawn once.

local held,was_held={},{}
function btn(i) return held[i] or false end
function btnp(i) return held[i] and not was_held[i] or false end
function sfx() end
music=sfx

local steps_a_frame=8
local n,runs=0,0
local game_update,game_draw=_update60,_draw
local stats={}
local wave_seen,wave_started=0,0

function _draw() end

function report()
 printh("wave "..wave_seen
  .." | "..flr((n-wave_started)/60).."s"
  .." | armor "..flr(player.armor).."/"..player.max_armor
  .." | kills "..stats.kills
  .." | most foes "..stats.most
  .." | overheats "..stats.overheats
  .." | alphas "..stats.alphas
  .." | hits "..stats.hits
  .." | city "..flr(city)
  .." | drops "..stats.drops
  .." | score "..score.."00")
end

local real_alpha,real_score,real_collect=start_alpha,add_score,collect
function collect(drop)
 stats.drops+=1
 real_collect(drop)
end
function start_alpha()
 stats.alphas+=1
 real_alpha()
end
function add_score(...)
 stats.kills+=1
 real_score(...)
end

function play()
 if wave!=wave_seen then
  wave_seen,wave_started=wave,n
  stats={kills=0,most=0,overheats=0,alphas=0,hits=0,drops=0}
 end
 stats.most=max(stats.most,#foes)

 local goal,nearest=player.x
 for foe in all(foes) do
  if foe.z<far_z and (not nearest or foe.z<nearest.z) then nearest=foe end
 end
 if nearest then
  goal=nearest.x
  if nearest.points==0 and nearest.z<3 then
   goal=nearest.centre+(player.x<nearest.centre and -22 or 22)
  end
 end
 for drop in all(drops) do
  if drop.z<2.5 and not (nearest and nearest.z<1.8) then goal=drop.x end
 end
 if goal>player.x+3 then held[1]=true end
 if goal<player.x-3 then held[0]=true end

 local weapon=weapon_specs[player.weapon]
 held[4]=player.heat+weapon.heat<max_heat
 held[2]=charge>=alpha_cost
 held[5]=n%10==0 and (weapon.wait>20
  or nearest and not player.target and n%40==0)
end

function bot_frame()
 n+=1
 was_held=held
 held={}
 if state=="title" then
  held[4]=n%4==0
 elseif state=="shop" then
  if wave==wave_seen then
   report()
   wave_seen=0
  end
  held[4]=n%20<10
 elseif state=="play" then
  play()
 end

 local was_hot,armor=player.overheated,player.armor
 game_update()
 if player.armor<armor then stats.hits+=1 end
 if player.overheated and not was_hot then stats.overheats+=1 end
 if state=="over" then
  report()
  printh((game_won and "the bot won" or "the bot died on wave "..wave)
   .." after "..flr(n/60).."s")
  runs+=1
  if runs==3 then
   printh("ok feel")
   extcmd("shutdown")
  end
  n,wave_seen=0,0
  reset()
  state="play"
 end
end

function _update60()
 for i=1,steps_a_frame do bot_frame() end
 game_draw()
 if runs==0 and n==1504 then dump_screen("feel_early") end
 if runs==0 and n==7504 then dump_screen("feel_mid") end
end
