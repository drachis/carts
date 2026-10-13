-- main.lua : the loop, the screens and the hud.
--
-- mode is "title", "play", "brewed" (the recipe was delivered in time) or
-- "cold" (the time ran out).
--
-- there are nine levels. `level` is the one being played and `unlocked`
-- the highest that may be: brewing a level unlocks the next. cartdata
-- slot 1 keeps `unlocked`, and slot 10+level the fastest brew of each
-- level, in frames, 0 when it has not been brewed.

cartdata("witchcap_1")

function _init()
 -- the tune keeps the first three channels and leaves one for sounds
 music(0,0,7)
 mode,mode_frames="title",0
 unlocked=mid(1,dget(1),9)
 level=unlocked
end

function start_run()
 level_seconds=level_clock[level]
 make_forest(flr(rnd(9999)))
 reset_witch()
 reset_hut()
 reset_effects()
 frames_left=level_seconds*60
 mode="play"
end

-- on the title and after a failure, left and right choose a level from
-- those unlocked
function choose_level()
 if btnp(0) then level=max(level-1,1) end
 if btnp(1) then level=min(level+1,unlocked) end
end

function print_level(y)
 print_centred((level>1 and "< " or "  ").."level "..level
  ..(level<unlocked and " >" or "  "),y,10)
end

-- what a recipe brews is settled by what went into it
potion_colours=split"8,9,10,11,12,14,13,7"
potion_names=split"crimson draught,amber tonic,golden elixir,green brew,blue philtre,rose cordial,violet tincture,moonlight essence"

function end_run(brewed)
 mode,mode_frames=brewed and "brewed" or "cold",0
 run_frames=level_seconds*60-frames_left
 best_frames=dget(10+level)
 new_best=brewed and (best_frames==0 or run_frames<best_frames)
 if new_best then
  best_frames=run_frames
  dset(10+level,best_frames)
 end
 if brewed and level==unlocked and level<9 then
  unlocked+=1
  dset(1,unlocked)
 end
 local kinds=0
 for slot in all(recipe) do kinds+=slot.kind end
 potion=kinds%8+1
 sfx(brewed and 2 or 5)
end

-- the victory, by mode_frames: the pot boils over in the potion's colour
-- for boil_frames, then goes up in a burst and the bottle rises out of it
-- to the middle of the screen, and then the words come
boil_frames,words_frame,again_frame=70,115,150

function update_victory()
 local x,y=pot_mouth()
 local colour=potion_colours[potion]
 if mode_frames<boil_frames and mode_frames%3==0 then
  burst(x,y,3,colour,1.4)
 elseif mode_frames==boil_frames then
  burst(x,y,40,colour,2.5)
  burst(x,y,15,7,1.5)
  shake=16
  sfx(4)
 end
end

function _update60()
 if mode!="title" then update_effects() end
 if mode=="play" then
  update_witch()
  update_hut()
  if btnp(5) then pick_mushroom() end
  frames_left-=1
  message_frames=max(message_frames-1)
  if deliver() then
   end_run(true)
  elseif frames_left<=0 then
   end_run(false)
  end
 else
  mode_frames=min(mode_frames+1,300)
  if mode=="brewed" then
   update_victory()
  else
   choose_level()
  end
  -- a press does not count until the screen has been seen
  if mode_frames>(mode=="brewed" and again_frame or 30) and btnp(5) then
   -- from a brewed potion, on to the next level
   if mode=="brewed" then level=min(level+1,unlocked) end
   start_run()
  end
 end
end

function seconds_text(frames)
 return flr(frames/6)/10 .."s"
end

function print_centred(text,y,colour)
 print(text,64-#text*2,y,colour)
end

function draw_title()
 cls(1)
 draw_backdrop(0)
 draw_moon(1)
 print_centred("witchcap",30,10)
 print_centred("fill the recipe from the forest",46,7)
 print_centred("and bring it to the pot",53,7)
 print_centred("beware the lookalikes",63,8)
 -- two forms of each family, side by side
 for family=0,3 do
  spr(96+family*4,22+family*24,74)
  spr(97+family*4,31+family*24,74)
 end
 print_centred("o jump  x pick  up broom",90,6)
 print_level(101)
 local best=dget(10+level)
 if best>0 then
  print_centred("best brew "..seconds_text(best),109,11)
 end
 print_centred("press x",118,7)
end

-- the recipe runs along the bottom of the screen, over the earth, and
-- leaves the sky to the hut and the moon
function draw_hud()
 rectfill(0,117,127,127,0)
 for number,slot in ipairs(recipe) do
  local x=number*11-8
  spr(95+slot.kind,x,119)
  -- yellow once it is in the basket, green once it is in the pot
  if slot.state>0 then
   rect(x-1,118,x+8,127,slot.state==2 and 11 or 10)
  end
 end
 -- which way the pot is: the cauldron, small, in a green glow, with an
 -- arrow on the side it lies
 local away=near(cauldron_x)-witch.x
 if abs(away)>70 then
  circfill(68,122,5,3)
  circ(68,122,5+t()*2%2,11)
  pal(5,0)
  sspr(112,16,16,16,64,118,8,8)
  pal(5,5)
  print(away>0 and ">" or "<",away>0 and 76 or 57,120,11)
 end
 print(ceil(frames_left/60),114,121,frames_left<600 and 8 or 7)
 -- the level, between the pot and the broom
 print("l"..level,83,121,6)
 -- the broom, and under it how rested it is
 local rested=1-witch.broom_wait/broom_rest
 line(96,125,104,120,rested==1 and 4 or 5)
 line(96,125,94,122,rested==1 and 10 or 5)
 line(96,125,93,126,rested==1 and 10 or 5)
 line(95,127,95+rested*10,127,rested==1 and 11 or 6)
end

function draw_cold()
 rectfill(14,38,113,92,0)
 rect(14,38,113,92,5)
 local delivered=0
 for slot in all(recipe) do
  if slot.state==2 then delivered+=1 end
 end
 print_centred("the pot went cold",43,8)
 print_centred(delivered.." of "..#recipe.." in the pot",53,7)
 -- try again, or pick another level that is unlocked
 print_level(66)
 print_centred("x: try it",80,6)
end

-- `pot_x` is where the pot is on the screen
function draw_victory(pot_x)
 local colour=potion_colours[potion]
 if mode_frames>=boil_frames then
  -- the bottle, drawn blue and shown in the potion's colour, rising
  -- from the pot to the middle of the screen at twice its size
  local share=min((mode_frames-boil_frames)/40,1)
  local pot_y=clearing_row*8+view_drop-40
  local x,y=pot_x+(64-pot_x)*share,pot_y+(20-pot_y)*share
  pal(12,colour)
  sspr(80,64,16,16,x-16,y,32,32)
  pal(12,12)
  -- and a ring of glints going round it
  for glint=1,6 do
   local angle=t()/3+glint/6
   pset(x+cos(angle)*24,y+16+sin(angle)*20,7)
  end
 end
 if mode_frames>=words_frame then
  rectfill(10,60,117,110,0)
  rect(10,60,117,110,colour)
  print_centred("you brewed a",64,7)
  print_centred(potion_names[potion],72,colour)
  print_centred("in "..seconds_text(run_frames),82,7)
  if new_best then
   print_centred("your fastest brew",90,10)
  else
   print_centred("best "..seconds_text(best_frames),90,6)
  end
  if mode_frames>again_frame then
   print_centred(level<unlocked and "x: on to level "..level+1
    or "x: brew another",101,6)
  end
 end
end

function _draw()
 pal()
 if mode=="title" then
  draw_title()
  return
 end
 local camera_x=witch.x-64
 -- poison turns the night sky green and sets the view swaying from side
 -- to side; up and down would show what is under the ground
 if witch.poison>0 then
  pal(1,3,1)
  camera_x+=sin(t()*2)*3
 end
 cls(1)
 draw_backdrop(camera_x)
 draw_hut(camera_x)
 -- the world is drawn `view_drop` pixels down the screen, which also
 -- leaves room below it for the view to be shaken
 camera(camera_x+rnd(shake/4)-shake/8,rnd(shake/4)-shake/8-view_drop)
 draw_forest(camera_x)
 draw_witch()
 draw_effects()
 camera()
 draw_foreground(camera_x)
 -- the moon last of all the scene: it is the clock
 draw_moon(frames_left/60/level_seconds)
 if message_frames>0 then
  print(message,witch.x-#message*2,witch.y-24,message_colour)
 end
 camera()
 draw_hud()
 if mode=="brewed" then
  draw_victory(near(cauldron_x)-camera_x)
 elseif mode=="cold" then
  draw_cold()
 end
end
