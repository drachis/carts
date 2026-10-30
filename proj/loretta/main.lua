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
 hearts,shake,respawn,mode_frames=max_hearts,0,0,0
 barks,puffs,floaters={},{},{}
 hero,respawn_x,respawn_y=new_loretta(16,82),16,82
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
 level,score,coins=1,0,0
 start_level()
 mode,hero.x,hero.held="title",50,0
 play_music(0)
end

function start_game()
 start_level()
 mode="play"
 sfx(snd_menu)
end

function next_level()
 level+=1
 start_game()
 play_music(0)
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
 hero.drop=2
 update_loretta(hero,mode_frames%100<8 and 16 or 0)
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
 hero.happy=2
 hero.state=mode_frames%60<40 and "sit" or "bark"
 if mode_frames%60==40 then float_text("aroo!",hero.x,hero.y-10,7) end
 if mode_frames>=60 and mode_frames%20==0 and hearts>0 then
  hearts-=1
  add_score(heart_bonus)
  sfx(snd_coin)
  if hearts==0 then save_best() end
 end
 if mode_frames>150 and hearts==0 and btnp(4) then
  if level<#levels then next_level() else go_title() end
 end
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
  spr(heart<=hearts and 42 or 43,2+(heart-1)*9,2)
 end
 sspr(16,16,16,16,32,2,8,8)
 outlined("x"..coins,41,3,7)
 outlined("score "..score_text(score),75,3,7)
 if mode=="play" and mode_frames<150 then
  local text=level..": "..level_names[level]
  outlined(text,64-#text*2,16,10)
 end
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
 draw_logo("loretta",36,6+sin(t()/3)*1.5)
 outlined("\135 corgi quest \135",30,24,7)
 for sparkle=1,6 do
  if (t()*1.5+sparkle/6)%1<0.5 then spr(44,sparkle*41%120,8+sparkle*13%40) end
 end
 rectfill(1,36,44,62,0)
 rect(1,36,44,62,14)
 if t()%1<0.6 then print("\145",3,40,14) end
 print("start",13,40,7)
 print("best",4,48,6)
 print(score_text(best),4,55,10)
 rectfill(86,36,126,76,0)
 rect(86,36,126,76,14)
 print("player 1",90,39,7)
 print("loretta",92,46,9)
 for row,name in ipairs(stat_names) do
  local y=47+row*6
  print(name,88,y,6)
  for bar=0,4 do
   rectfill(110+bar*3,y,111+bar*3,y+3,bar<stats[name] and stat_colours[row] or 1)
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
 local cam=camera_x()
 draw_backdrop(cam)
 camera(cam+(shake%4<2 and 0 or shake\4),-view_drop)
 draw_things(1)
 draw_level(cam)
 draw_things()
 draw_barks()
 if respawn==0 then draw_loretta(hero) end
 draw_effects()
 camera()
 if mode=="title" then draw_title() else draw_hud() end
 if mode=="win" then
  local last=level==#levels
  draw_banner((last and "you made it!|loretta saw the stars" or landmarks[level].."!|"..praises[level]).."|score "..score_text(score)..(hearts==0 and (last and "|\142 back to the start" or "|\142 on to "..level_names[level+1]) or ""),74)
 end
 if mode=="over" then draw_banner("loretta needs a nap|score "..score_text(score).."|\142 try again",22) end
end
