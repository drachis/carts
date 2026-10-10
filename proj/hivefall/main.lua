-- main.lua : states, the wave director, the hud, and pico-8's callbacks.

function reset()
 foes,shots,sparks,rings={},{},{},{}
 score,shake,freeze,white,grid_flash=0,0,0,0,0
 player={
  x=0,vx=0,armor=100,heat=0,weapon=1,
  hurt_flash=0,muzzle=0,recoil=0,gun_side=1
 }
 for weapon in all(weapon_specs) do weapon.wait=0 end
 start_wave(1)
end

function start_wave(number)
 wave=number
 groups=split(wave_specs[number])
 group_wait=180
 banner=150
 player.armor=min(100,player.armor+10)
 sfx(snd_wave)
end

-- groups come a few seconds apart, sooner if the hill is empty
function update_waves()
 banner=max(banner-1)
 if #groups>0 then
  group_wait-=1
  if #foes==0 then group_wait=min(group_wait,45) end
  if group_wait<=0 then
   local parts=split(deli(groups,1),"*")
   spawn_group(parts[1],parts[2])
   group_wait=300
  end
 elseif #foes==0 then
  if wave==#wave_specs then
   end_game(true)
  else
   start_wave(wave+1)
  end
 end
end

function end_game(won)
 state="over"
 game_won=won
 over_wait=90
end

function _init()
 state,over_wait="title",0
 reset()
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
 else
  over_wait=max(over_wait-1)
  if over_wait==0 and (btnp(4) or btnp(5)) then
   reset()
   state="play"
  end
 end
 update_effects()
end

function bar(x,y,fraction,colour)
 rect(x-1,y-1,x+41,y+3,5)
 rectfill(x,y,x+40*mid(0,fraction,1),y+2,colour)
end

function centred(text,y,colour)
 print(text,64-#text*2,y,colour)
end

function draw_hud()
 rectfill(0,0,17,17,0)
 rect(0,0,17,17,player.hurt_flash>0 and 8 or 6)
 if player.hurt_flash>0 then pal(12,8) end
 sspr(64,16,16,16,1,1)
 pal()
 bar(21,2,player.armor/100,player.armor>30 and 11 or 8)
 local heat_colour=9
 if player.overheated then heat_colour=tick%8<4 and 8 or 7 end
 bar(21,8,player.heat/max_heat,heat_colour)

 local current=weapon_specs[player.weapon]
 print(current.name,21,14,current.wait>0 and 5 or current.colour)
 for i,weapon in ipairs(weapon_specs) do
  local x=15+i*6
  if weapon.wave<=wave then
   rectfill(x,21,x+3,23,weapon.wait>0 and 5 or weapon.colour)
  end
  if i==player.weapon then rect(x-1,20,x+4,24,7) end
 end

 local text=score.."00"
 print(text,128-#text*4,2,7)
 print("wave "..wave,104,9,6)

 if banner>0 then
  centred("wave "..wave,28,7)
  for weapon in all(weapon_specs) do
   if weapon.wave==wave and wave>1 then
    centred("new weapon: "..weapon.name,36,weapon.colour)
   end
  end
 end
end

function _draw()
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 draw_sky()
 sort_foes()
 draw_foes(true)
 draw_hill()
 draw_foes(false)
 if state=="play" then draw_aim() end
 draw_shots()
 if state!="over" or game_won then draw_player() end
 draw_effects()
 camera()
 if white>0 then rectfill(0,0,127,127,7) end

 if state=="play" then
  draw_hud()
 elseif state=="title" then
  print("\^w\^thivefall",32,24,7)
  centred("hold the hill",40,6)
  centred("left/right  move",70,13)
  centred("z fire   x next weapon",78,13)
  if tick%60<40 then centred("press z to deploy",92,10) end
 else
  rectfill(20,44,107,84,0)
  rect(20,44,107,84,game_won and 11 or 8)
  centred(game_won and "the hive is broken" or "mech destroyed",50,7)
  centred("score "..score.."00",60,10)
  centred("wave "..wave,68,6)
  if over_wait==0 then centred("press z",76,13) end
 end
end
