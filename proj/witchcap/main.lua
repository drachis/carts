-- main.lua : the loop, the screens and the hud.
--
-- mode is "title", "play", "brewed" (the recipe was delivered in time) or
-- "cold" (the time ran out). the best brewing time, in frames, is kept in
-- cartdata slot 0; 0 means no potion has been brewed yet.

cartdata("witchcap_1")

function _init()
 place_limbs()
 -- the tune keeps the first three channels and leaves one for sounds
 music(0,0,7)
 mode,mode_frames="title",0
 best_frames=dget(0)
end

function start_run()
 make_forest(flr(rnd(9999)))
 reset_witch()
 reset_hut()
 reset_effects()
 frames_left=level_seconds*60
 mode="play"
end

function end_run(brewed)
 mode,mode_frames=brewed and "brewed" or "cold",0
 run_frames=level_seconds*60-frames_left
 new_best=brewed and (best_frames==0 or run_frames<best_frames)
 if new_best then
  best_frames=run_frames
  dset(0,best_frames)
 end
 sfx(brewed and 4 or 5)
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
  -- a moment before a press counts, so the ending is seen
  mode_frames=min(mode_frames+1,60)
  if mode_frames>30 and btnp(5) then start_run() end
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
 print_centred("arrows run   o jump   x pick",92,6)
 if best_frames>0 then
  print_centred("best brew "..seconds_text(best_frames),104,11)
 end
 print_centred("press x",116,7)
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
 local away=near(cauldron_x)-witch.x
 if abs(away)>70 then
  print(away>0 and "pot >" or "< pot",66,121,6)
 end
 print(ceil(frames_left/60),114,121,frames_left<600 and 8 or 7)
end

function draw_ending()
 rectfill(14,38,113,92,0)
 rect(14,38,113,92,5)
 if mode=="brewed" then
  print_centred("the potion is brewed!",44,11)
  print_centred("in "..seconds_text(run_frames),56,7)
  if new_best then
   print_centred("your fastest brew",66,10)
  else
   print_centred("best "..seconds_text(best_frames),66,6)
  end
 else
  local delivered=0
  for slot in all(recipe) do
   if slot.state==2 then delivered+=1 end
  end
  print_centred("the pot went cold",44,8)
  print_centred(delivered.." of "..#recipe.." in the pot",56,7)
 end
 print_centred("x: another forest",80,6)
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
 draw_moon(frames_left/60/level_seconds)
 -- the world is drawn `view_drop` pixels down the screen, which also
 -- leaves room below it for the view to be shaken
 camera(camera_x+rnd(shake/4)-shake/8,rnd(shake/4)-shake/8-view_drop)
 draw_forest(camera_x)
 draw_witch()
 draw_effects()
 if message_frames>0 then
  print(message,witch.x-#message*2,witch.y-24,message_colour)
 end
 camera()
 draw_hud()
 if mode!="play" then draw_ending() end
end
