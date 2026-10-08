-- main.lua : game states, scoring, the wrath director, hud and
-- main loop. state is "title", "play", "dead" or "won".

function new_game()
 generate_world()
 new_dragon()
 score,kills,wrath,heralded=0,0,1,0
 combo,combo_timer,fury,fury_time=0,0,0,0
 shown_score,combo_pop,coin_run,reel_time=0,0,0,0
 hoard=0
 shake,freeze,flash=0,0,0
 message,message_timer,reinforce_timer="",0,300
 cam_x,cam_y=dragon.x-64,dragon.y-64
 boss=nil
 state="title"
 set_tempo()
end

function end_game(outcome)
 state,end_frame=outcome,frame
 if score>high_score then
  high_score=score
  dset(0,high_score)
 end
end

-- the music's speed lives in sfx memory (byte 65 of each 68-byte
-- sfx), so poking it there makes the band play faster as the
-- realm's wrath grows, and faster again in the thick of a battle.
-- sfx 16..18 are the music's patterns.
function set_tempo()
 for pattern=16,18 do
  poke(0x3241+pattern*68,max(5,17-wrath*2-(battle and 3 or 0)))
 end
end

function multiplier()
 return min(1+combo\5,config.max_multiplier)
end

-- pico-8 numbers stop at 32767, so score is kept in tens and shown
-- with a zero on the end: room for 327,670 points
function points(tens)
 return flr(tens).."0"
end

-- fury fills from score, coins, grazes and burnt shots, but not
-- while an inferno is spending it
function add_fury(amount)
 if fury_time==0 then
  fury=min(100,fury+amount)
 end
end

-- every kill and ruin goes through here. hits in quick succession
-- build a combo that multiplies the score and feeds the fury meter.
function add_score(worth,x,y)
 combo+=1
 combo_pop=3
 combo_timer=config.combo_frames
 local gained=worth*multiplier()
 score+=gained/10
 add_fury(worth/4)
 add_particle(x,y-6,0,-.5,30,"text").text="+"..gained
 if streaks[combo] then
  announce(streaks[combo])
  roar(70,30)
 end
end

-- a coin reaching the dragon: a little score, and it keeps the
-- combo alive, so a realm left burning keeps the streak cooking.
-- each ding is a note higher than the last: the coin sfx's first
-- byte is its pitch, poked just before it plays.
function collect_coin()
 coin_run+=1
 score+=config.coin_value*multiplier()/10
 combo_timer=config.combo_frames
 add_fury(.5)
 poke(0x3200+sound.coin*68,24+coin_run%32)
 sfx(sound.coin)
 -- and it is added to the hoard, which the dragon grows on
 hoard+=1
 if hoard_fill()>=1 then grow() end
end

-- how far the hoard is towards the dragon's next age, 0 to 1.
-- at the last age there is nothing left to grow into.
function hoard_fill()
 local next_age=ages[age+1]
 return next_age and hoard/next_age.hoard or 0
end

-- the boon reel: flicker through the boons, then land on one
function update_reel()
 if reel_time==0 then return end
 reel_time-=1
 if reel_time%3==0 then
  reel=rnd(boons)
  announce(reel.name,20)
  sfx(sound.coin)
 end
 if reel_time==0 then
  grant(reel.stats)
  announce("boon: "..reel.name,120)
  sfx(sound.fanfare)
 end
end

-- the more you burn, the harder the realm pushes back
function update_wrath()
 local next_level=wrath_levels[wrath+1]
 if next_level and score>=next_level.score then
  wrath+=1
  announce("the realm is "..next_level.name)
  sfx(sound.fanfare)
 end
 if frame%30==0 then set_tempo() end

 -- newcomers arrive from just off screen
 local angle=rnd()
 local x,y=dragon.x+cos(angle)*95,dragon.y+sin(angle)*95

 -- each level's legend is heralded once, one boss at a time
 if not boss and heralded<wrath then
  heralded+=1
  local legend=wrath_levels[heralded].legend
  if legend then spawn_boss(legend,x,y) end
 end

 -- reinforcements pour in during a battle and thin out between
 reinforce_timer-=battle and config.battle_rush or 1
 if reinforce_timer<=0 then
  reinforce_timer=700-wrath*100
  for i=1,1+wrath\2 do
   spawn_unit(rnd(list(wrath_levels[wrath].pool)),x+rnd(16)-8,y+rnd(16)-8)
  end
 end
end

function draw_bar(x,y,width,fraction,color,back)
 rectfill(x,y,x+width,y+1,back)
 rectfill(x,y,x+width*mid(0,fraction,1),y+1,color)
end

-- an arrow at the screen edge to the next step of the run: the
-- nearest settlement whose ward still stands (blue), and once
-- none do, the goal itself (gold)
function draw_compass()
 local target,nearest=goal.home,32000
 for home in all(settlements) do
  local distance=dragon_distance(home.tx*8,home.ty*8)
  if home.wards>0 and distance<nearest then
   target,nearest=home,distance
  end
 end
 local dx,dy=target.tx*8-dragon.x,target.ty*8-dragon.y
 if length(dx,dy)>80 then
  local angle=atan2(dx,dy)
  local x,y=64+cos(angle)*56,68+sin(angle)*52
  circfill(x,y,2,wards>0 and 12 or 10)
  line(x,y,x+cos(angle)*4,y+sin(angle)*4,7)
 end
end

-- flames lick in from the screen edges when things are going well,
-- in the colors of the dragon's own breath
function draw_blaze()
 local ramp=split(dragon.flame)
 for i=0,127,2 do
  local reach=3+rnd(4)+sin(i/50+frame/40)*3
  local color=ramp[2+flr(rnd(3))]
  line(i,127,i,127-reach,color)
  if i>9 then
   line(0,i,reach,i,color)
   line(127,i,127-reach,i,color)
  end
 end
end

function draw_hud()
 local blink=frame%8<4
 if state=="play" then
  if fury_time>0 or reel_time>0 or multiplier()==config.max_multiplier then
   draw_blaze()
  end
  if combo>1 then
   -- the hit counter swells for a moment with each new hit
   local text,width=combo.." hits",4
   if combo_pop>0 then
    text,width="\^w\^t"..text,8
   end
   print(text,126-#(combo.." hits")*width,13,blink and 10 or 9)
  end
  draw_compass()
  -- a red frame beats when the dragon is close to death
  if dragon.hp<30 and frame%20<10 then
   rect(0,9,127,127,8)
  end
  if fury>=100 and blink then
   print_centered("z+x: inferno!",110,10)
  end
 end

 rectfill(0,0,127,8,0)
 draw_bar(2,1,34,dragon.hp/dragon.max_hp,8,2)
 draw_bar(2,4,34,dragon.fire/dragon.max_fire,9,4)
 draw_bar(2,7,34,fury_time>0 and fury_time/config.fury_frames or fury/100,
  (fury_time>0 or fury>=100) and blink and 7 or 10,5)
 -- the score rolls up to its true value like a payout counter
 print(points(shown_score),40,1,shown_score<flr(score) and 10 or 7)
 -- the hoard: gold gathered towards the dragon's next growth
 draw_bar(40,7,22,hoard_fill(),10,4)
 print("ko "..kills,66,2,6)
 if combo>1 then
  -- the combo and how long is left to keep it going
  print("x"..multiplier(),94,1,blink and 10 or 9)
  line(94,7,94+combo_timer/config.combo_frames*10,7,10)
 end
 -- the realm's wrath (red) over the wards still standing (blue)
 for level=1,#wrath_levels do
  pset(106+level*4,3,level<=wrath and 8 or 5)
  if level<=wards then pset(106+level*4,6,12) end
 end

 if boss then
  local spec=boss.spec
  rectfill(0,119,127,127,0)
  print(spec.name,2,121,spec.color)
  draw_bar(60,122,65,boss.hp/spec.hp,8,2)
 end
 if message_timer>0 then
  print_centered(message,22)
 end
end

function draw_title()
 rectfill(0,24,127,100,0)
 print("\^w\^twyrmfire",33,31,8)
 print_centered("burn the churches. raze camelot.",48,9)
 print_centered("arrows  fly",62,6)
 print_centered("z  breathe fire",70,6)
 print_centered("x  charge & devour",78,6)
 print_centered("press x",90,7)
 if high_score>0 then
  print_centered("best "..points(high_score),106,10)
 end
end

function draw_game_over()
 local won=state=="won"
 local razed=flr((1-#buildings/#all_buildings)*100)
 rectfill(0,44,127,86,0)
 print_centered(won and "camelot is ash" or "the dragon is slain",50,won and 10 or 8)
 print_centered("score "..points(score).."  best "..points(high_score),60,7)
 print_centered(kills.." slain  "..razed.."% razed",68,6)
 if frame-end_frame>45 then
  print_centered("press x",78,5)
 end
end

function _init()
 cartdata("drachis_wyrmfire")
 high_score=dget(0)
 frame=0
 new_game()
 -- music keeps to channels 0 and 1, leaving two for effects
 music(0,0,3)
end

function _update()
 -- hit-stop: big impacts hold the frame for a moment
 if freeze>0 then
  freeze-=1
  return
 end
 frame+=1
 local pressed=btnp(4) or btnp(5)
 if state=="play" then
  update_dragon()
  update_units()
  update_shots()
  update_buildings()
  update_settlements()
  update_wrath()
  update_reel()
  combo_timer-=1
  if combo_timer<=0 then combo,coin_run=0,0 end
 elseif state=="title" then
  if pressed then state="play" end
 elseif pressed and frame-end_frame>45 then
  new_game()
 end
 update_fire()
 update_particles()
 shown_score+=ceil((flr(score)-shown_score)/6)
 combo_pop-=1
 shake*=.8
 message_timer-=1
end

function _draw()
 if flash>0 then
  -- a white frame for the biggest moments
  flash-=1
  cls(7)
  return
 end
 cls()
 -- the camera eases towards a point ahead of the dragon's nose,
 -- so there is always room to see what it is aiming at
 cam_x+=(mid(0,dragon.x+cos(dragon.angle)*24-64,384)-cam_x)*.15
 cam_y+=(mid(0,dragon.y+sin(dragon.angle)*24-64,384)-cam_y)*.15
 camera(cam_x+rnd(shake)-shake/2,cam_y+rnd(shake)-shake/2)
 map(cam_x\8,cam_y\8,cam_x\8*8,cam_y\8*8,17,17)
 draw_fire()
 draw_buildings()
 draw_units()
 draw_shots()
 draw_dragon()
 draw_particles()
 draw_shots(true)

 camera()
 if state=="title" then
  draw_title()
 else
  draw_hud()
  if state!="play" then draw_game_over() end
 end
 -- as the realm's wrath climbs, smoke dims the land: the screen
 -- palette swaps the greens for darker ones. pal() above resets
 -- it every frame, so it is set last.
 if wrath>=config.dusk_wrath then
  pal(3,131,1)
  pal(11,3,1)
 end
end
