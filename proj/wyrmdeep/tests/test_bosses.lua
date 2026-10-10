-- test_bosses.lua : each legend in turn, alone on its screen, put through
-- the whole fight by a script and checked at every step:
--   watch  its bar is full, its bubbles are all there, it winds up at least
--          once, and it never leaves the screen
--   pop    charges take its bubbles one at a time, and the last staggers it
--   burn   staggered, it takes fire
--   wait   its bubbles come back when the stagger ends
--   kill   devouring it gives the next age and ends the stage, or wins
-- a line is printed for each legend; any failed check stops the cart.

local names=split"sir kay,sir gawain,merlin,king arthur"
local index,t,phase=0,0
local legend,wound_up,popped,before,burnt,age_before

local function begin()
 index+=1
 if index>#names then
  printh("ok bosses")
  extcmd("shutdown")
  return
 end
 state="play"
 enter_stage(index-1)
 cam_x=896
 units={}
 legend=spawn_unit(names[index],1000,cam_y+100)
 t,phase,wound_up,popped,age_before=0,"watch",false,0,age
end

function step()
 local d=dragon
 if not phase then begin() end
 if not phase then return end
 local b=legend
 local name=b.name
 t+=1
 d.hp,d.stamina,d.fire=d.max_hp,d.max_stamina,d.max_fire
 advance=nil
 muster=99
 hold()
 if phase!="kill" then
  assert(on_screen(b.x,b.y,0),name.." left the screen during "..phase)
 end

 if phase=="watch" then
  d.x,d.y,d.vx,d.vy=944,cam_y+20,0,0
  wound_up=wound_up or b.windup
  if t==40 then
   assert(boss==b,name.." has no health bar")
   assert(b.hp==b.max_hp and b.max_hp>0,name.." does not start at full health")
   local bar=127*(b.hp/b.max_hp)
   assert(bar==127,name.."'s bar is "..bar.." wide, not 127")
   assert(b.shields==b.shield,name.." starts with "..b.shields.." bubbles, not "..b.shield)
  end
  if t==300 then
   assert(wound_up,name.." never wound up in ten seconds")
   phase="pop"
  end
 elseif phase=="pop" then
  assert(t<900,name.."'s bubbles would not all pop")
  if b.shields==0 then
   assert(b.stun>0,name.." was not staggered by its last bubble")
   before=b.hp
   t,phase=0,"burn"
  elseif d.charge<=0 and d.windup<=0 then
   d.x,d.y,d.angle,d.facing=b.x-24-b.reach,b.cy,0,1
   d.vx,d.vy,d.charge_cooldown=0,0,0
   hold(5)
   popped+=1
  end
 elseif phase=="burn" then
  d.x,d.y,d.angle,d.facing,d.vx,d.vy=b.x-22-b.reach,b.cy,0,1,0,0
  hold(4)
  if t==40 then
   burnt=before-b.hp
   assert(burnt>0,name.." took no fire while staggered")
   phase="wait"
  end
 elseif phase=="wait" then
  d.x,d.y,d.vx,d.vy=944,cam_y+20,0,0
  assert(t<400,name.." never came out of its stagger")
  if b.stun<=0 then
   assert(b.shields==b.shield,name.."'s bubbles did not come back")
   phase="kill"
  end
 else
  damage_unit(b,b.hp,true)
  if index<#names then
   assert(age==age_before+1,name.." gave no age")
   assert(advance,name.."'s fall did not end the stage")
  else
   assert(state=="won",name.."'s fall did not win the game")
  end
  printh(name..": "..b.max_hp.." health, "..b.shield.." bubbles popped in "..popped
   .." charges, lost "..flr(burnt).." health to 40 frames of fire; ok")
  phase,legend=nil
 end
end
