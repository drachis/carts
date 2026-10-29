function _init()
 cartdata("loretta_corgi_quest")
 best=dget(0)
 apply_stats()
 set_palette()
 go_title()
end

function play_music(pattern)
 if pattern!=playing_music then music(pattern or -1,0,7) end
 playing_music=pattern
end

function start_level()
 load_level()
 hearts,coins,score,shake,respawn,mode_frames=max_hearts,0,0,0,0,0
 barks,puffs,floaters={},{},{}
 for thing in all(things) do
  if thing.name=="start" then
   hero=new_loretta(thing.x,thing.y)
   respawn_x,respawn_y=thing.x,thing.y
   del(things,thing)
  end
 end
 view=new_camera(hero)
end

function go_title()
 start_level()
 mode="title"
 play_music(0)
end

function start_game()
 start_level()
 mode="play"
 sfx(snd_menu)
end

function save_best()
 best=max(best,score)
 dset(0,best)
end

function game_over()
 mode,mode_frames="over",0
 hero.state,hero.hurt,hero.vx="nap",0,0
 play_music()
 sfx(snd_over)
 save_best()
end

function win()
 mode,mode_frames="win",0
 hero.vx=0
 play_music()
 sfx(snd_howl)
end

function update_title()
 update_loretta(hero,mode_frames%90<10 and 16 or 0)
 if btnp(4) then start_game() end
end

function update_play()
 if respawn>0 then
  respawn-=1
  if respawn==0 then
   hero=new_loretta(respawn_x,respawn_y)
   if hearts<=0 then return game_over() end
   hero.hurt=hurt_frames
  end
 else
  update_loretta(hero,read_input())
  if area_has(hero.x,hero.y,hero_w,hero_h,2) or hero.y>124 then fall_in(hero) end
 end
 update_things(hero)
 update_barks()
end

function update_win()
 update_loretta(hero,0)
 hero.state=mode_frames%60<40 and "sit" or "bark"
 if mode_frames%60==40 then float_text("aroo!",hero.x,hero.y-10,7) end
 if mode_frames>=60 and mode_frames%20==0 and hearts>0 then
  hearts-=1
  add_score(heart_bonus)
  sfx(snd_coin)
  if hearts==0 then save_best() end
 end
 if mode_frames>150 and hearts==0 and btnp(4) then go_title() end
end

function update_over()
 update_loretta(hero,0)
 hero.state="nap"
 if mode_frames%30==0 then float_text("z",hero.x+12+mode_frames%60/10,hero.y-4,7) end
 if mode_frames>60 and btnp(4) then go_title() end
end

function _update60()
 mode_frames=min(mode_frames+1,30000)
 _ENV["update_"..mode]()
 update_effects()
 update_camera(view,hero)
end

function outlined(text,x,y,colour)
 for dx=-1,1 do
  for dy=-1,1 do print(text,x+dx,y+dy,0) end
 end
 print(text,x,y,colour)
end

function score_text(points)
 local text=points.."0"
 while #text<7 do text="0"..text end
 return text
end

function draw_hud()
 for heart=1,max_hearts do
  spr(heart<=hearts and 45 or 46,2+(heart-1)*9,2)
 end
 spr(36,32,2)
 outlined("x"..coins,41,3,7)
 outlined("score "..score_text(score),75,3,7)
end

function draw_logo(text,x,y)
 local big="\^w\^t"..text
 for dx=-2,2 do
  for dy=-2,3 do print(big,x+dx,y+dy,2) end
 end
 for dx=-1,1 do
  for dy=-1,1 do print(big,x+dx,y+dy,14) end
 end
 print(big,x,y,9)
 clip(0,0,128,y+5)
 print(big,x,y,10)
 clip()
end

function draw_title()
 draw_logo("loretta",36,8+sin(t()/3)*1.5)
 outlined("\135 corgi quest \135",30,26,7)
 for sparkle=1,6 do
  if (t()*1.5+sparkle/6)%1<0.5 then spr(47,sparkle*41%120,8+sparkle*13%30) end
 end
 rectfill(3,44,58,74,0)
 rect(3,44,58,74,14)
 if t()%1<0.6 then print("\145",6,48,14) end
 print("start",15,48,7)
 print("high score",7,58,6)
 print(score_text(best),15,66,10)
 rectfill(66,40,125,119,0)
 rect(66,40,125,119,14)
 print("player 1",80,43,7)
 rect(79,50,112,83,13)
 sspr(16,24,16,16,80,51,32,32)
 print("loretta",82,86,9)
 for row,name in ipairs(stat_names) do
  local y=88+row*6
  print(name,69,y,6)
  for bar=0,4 do
   rectfill(98+bar*5,y,101+bar*5,y+3,bar<stats[name] and stat_colours[row] or 1)
  end
 end
 outlined("\142 jump \151 bark \131 sit",8,121,7)
end

function draw_banner(lines,top)
 rectfill(14,top,113,top+40,0)
 rect(14,top,113,top+40,14)
 for row,text in ipairs(split(lines,"|")) do
  print(text,64-#text*2,top-2+row*8,row==1 and 10 or 7)
 end
end

function _draw()
 cls()
 draw_backdrop(view.x)
 camera(view.x+(shake%4<2 and 0 or shake/4),0)
 draw_things(1)
 map(0,0,0,0,128,16)
 draw_things()
 draw_barks()
 if respawn==0 then draw_loretta(hero) end
 draw_effects()
 camera()
 if mode=="title" then draw_title() else draw_hud() end
 if mode=="win" then draw_banner("you made it!|loretta saw the stars|score "..score_text(score)..(hearts==0 and "|\142 back to the start" or ""),74) end
 if mode=="over" then draw_banner("loretta needs a nap|score "..score_text(score).."|\142 try again",22) end
end
