-- main.lua : states, the wave director (a wave is a city district), score, the hud, and pico-8's
-- callbacks. states: title, play, shop (pick an upgrade), over.

function reset()
 foes,shots,sparks,rings,popups,drops,blasts={},{},{},{},{},{},{}
 parse_record(run_start,",",_ENV)
 player=parse_record(player_start,",")
 boss,alpha_told=nil
 restock()
 start_wave(1)
end

function restock()
 for weapon in all(weapon_specs) do
  weapon.wait,weapon.rounds=0,weapon.ammo
 end
end

-- a foe that gets past the mech is loose in the city. there is no bar
-- for it: the houses show it (see draw_hill).
function hurt_city(amount,sx)
 if city>30 and city-amount<=30 then
  bark("the city is burning!")
 elseif city_flash==0 then
  bark("they're in the city!")
 end
 city-=amount
 city_flash=30
 shake=max(shake,4)
 burst(sx or 64,122,12,9,3)
 sfx(snd_hurt)
 if city<=0 then end_game(false,"the city has fallen") end
end

-- the pilot says something beside the portrait
function bark(text)
 bark_text,bark_wait=text,150
end

function start_wave(number)
 wave=number
 groups=split(wave_specs[number])
 group_wait,banner,clear_wait=180,150,0
 for i,weapon in ipairs(weapon_specs) do
  if weapon.wave==number and number>1 then
   player.weapon=i
   bark(weapon.name.." online")
  end
 end
 safety,player.alpha=true,0
 sfx(snd_wave)
end

-- groups come a few seconds apart, sooner if the hill is empty; when
-- the last is dead there is a beat, then the shop or the ending
function update_waves()
 banner=max(banner-1)
 bark_wait=max(bark_wait-1)
 combo_wait=max(combo_wait-1)
 if combo_wait==0 then combo=0 end
 if dying>0 then return update_dying() end
 if #groups>0 then
  group_wait-=1+boost*250
  if #foes==0 then group_wait=min(group_wait,45) end
  if group_wait<=0 then
   local parts=split(deli(groups,1),"*")
   spawn_group(parts[1],parts[2])
   group_wait=300
  end
 elseif #foes==0 then
  player.alpha=0
  clear_wait+=1
  if clear_wait==20 then bark("district clear") end
  if clear_wait>100 then
   if wave==#wave_specs then
    end_game(true,"the hive is broken")
   else
    open_shop()
   end
  end
 end
end

-- kills in quick succession chain; every fifth raises the multiplier.
-- points also charge the alpha strike.
function add_score(points,x,y)
 combo+=1
 combo_wait=combo_frames
 local worth=points*multiplier()
 score+=worth
 charge=min(alpha_cost,charge+points)
 if charge==alpha_cost and not alpha_told then
  alpha_told=true
  bark("alpha strike ready")
 end
 if worth>=3 then
  add(popups,{x=x,y=y,text=worth.."00",life=45})
 end
end

function multiplier()
 return min(8,1+combo\5)
end

function open_shop()
 state,shop_armed,chosen="shop",false,2
 choices={}
 while #choices<3 do
  local pick=rnd(upgrade_specs)
  if count(choices,pick)==0 then add(choices,pick) end
 end
end

-- fire has to be let go once before it can confirm, since the pilot
-- arrives here holding it
function update_shop()
 if btnp(0) then chosen=max(1,chosen-1) end
 if btnp(1) then chosen=min(3,chosen+1) end
 if not btn(4) then
  shop_armed=true
 elseif shop_armed and btnp(4) then
  local pick=choices[chosen]
  player[pick.stat]+=pick.amount
  player.armor=min(player.max_armor,player.armor+20)
  restock()
  sfx(snd_upgrade)
  white=2
  state="play"
  start_wave(wave+1)
 end
end

function end_game(won,text)
 state,game_won,over_wait,over_text="over",won,90,text
end

function _init()
 state="title"
 reset()
 music(0,0,3)
end

function _update60()
 tick+=1
 if state=="play" then
  if freeze>0 then
   freeze-=1
   return
  end
  update_player()
  update_waves()
  update_foes()
  update_shots()
  update_drops()
 elseif state=="shop" then
  update_shop()
 else
  over_wait=max(over_wait-1)
  if over_wait==0 and (btnp(4) or btnp(5)) then
   reset()
   state="play"
  end
 end
 update_effects()
end

-- a bar on a grey back plate a pixel bigger all round
function bar(x,y,width,fraction,colour)
 rectfill(x-1,y-1,x+width+1,y+3,5)
 rectfill(x,y,x+width*mid(0,fraction,1),y+2,colour)
end

function centred(text,y,colour)
 print(text,64-#text*2,y,colour)
end

-- the hud keeps to a strip along the top: portrait, three bars (armour,
-- heat, alpha), the gun in hand with its ammo, a pip per gun, score.
-- the pilot's line and the boss's bar sit just under it.
function draw_hud()
 local blink=tick%8<4
 rectfill(0,0,127,18,0)
 line(0,18,127,18,5)
 if player.hurt_flash>0 or player.armor<=30 and blink then pal(12,8) end
 sspr(64,16,16,16,1,1)
 pal()

 bar(20,2,38,player.armor/player.max_armor,player.armor>30 and 11 or 8)
 if player.chill>0 then
  bar(20,7,38,player.chill/chill_frames,blink and 7 or 12)
 else
  local heat_colour=9
  if player.overheated then heat_colour=blink and 8 or 7 end
  bar(20,7,38,player.heat/max_heat,heat_colour)
 end
 local ready=charge>=alpha_cost
 bar(20,12,38,player.alpha>0 and player.alpha/alpha_frames or charge/alpha_cost,
  (ready or player.alpha>0) and blink and 7 or 12)

 local current=weapon_specs[player.weapon]
 sspr(player.weapon*8-8,48,8,8,62,1,16,16)
 if current.ammo>0 then print(current.rounds,81,2,7) end
 print(current.name,81,8,current.wait>0 and 5 or current.colour)
 for i,weapon in ipairs(weapon_specs) do
  if weapon.wave<=wave then
   local x=77+i*4
   local dry=weapon.ammo>0 and weapon.rounds<=0
   rectfill(x,14,x+2,16,(dry or weapon.wait>0) and 5 or weapon.colour)
   if i==player.weapon then line(x,17,x+2,17,7) end
  end
 end

 local text=score.."00"
 print(text,128-#text*4,2,7)
 if combo>=5 then
  print("x"..multiplier(),120,8,blink and 10 or 9)
 end
 print(wave.."/"..#wave_specs,116,13,6)

 if bark_wait>0 then
  print(bark_text,1,21,7)
 elseif ready then
  print("down: alpha strike!",1,21,blink and 7 or 12)
 end
 if boss and boss.hp>0 then
  bar(14,29,100,boss.hp/enemy_specs.tyrant.hp,8)
 end
 if banner>0 then
  centred(boss and boss.hp>0 and "the hive tyrant" or district_names[wave],42,7)
 end
end

function draw_shop()
 centred("field refit: pick one",40,7)
 for i,pick in ipairs(choices) do
  local x=i*42-40
  rectfill(x,50,x+38,76,0)
  rect(x,50,x+38,76,i==chosen and 10 or 5)
  print(pick.name,x+3,54,i==chosen and 10 or 6)
  print(pick.blurb,x+3,64,13)
 end
 centred("left/right, fire to fit",82,6)
end

function _draw()
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 draw_sky()
 sort_foes()
 draw_foes(true)
 draw_hill()
 draw_foes(false)
 draw_drops()
 if state=="play" then draw_aim() end
 draw_shots()
 if state!="over" or game_won then draw_player() end
 draw_effects()
 camera()
 if white>0 then rectfill(0,0,127,127,7) end

 if state=="play" then
  draw_hud()
 elseif state=="shop" then
  draw_hud()
  draw_shop()
 elseif state=="title" then
  print("\^w\^thivefall",32,6,7)
  centred("race to the capitol",21,12)
  rectfill(4,66,123,106,0)
  rect(4,66,123,106,5)
  centred("left/right  move",70,6)
  centred("o fire  x next gun  o+x vent",78,6)
  centred("up advance  down alpha strike",86,12)
  if tick%60<40 then centred("press fire to deploy",98,10) end
 else
  rectfill(20,44,107,84,0)
  rect(20,44,107,84,game_won and 11 or 8)
  centred(over_text,50,7)
  centred("score "..score.."00",60,10)
  centred(district_names[wave],68,6)
  if over_wait==0 then centred("press fire",76,13) end
 end
end
