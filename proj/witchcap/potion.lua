-- potion.lua : the recipe, and what picking and delivering do to it.
--
-- mushrooms are kinds 1..16: four families of four forms, kind
-- family*4+form+1. the forms of a family are nearly alike, and none is
-- the good one: each run the recipe names its own kinds, all different,
-- and the other forms of their families are the lookalikes. exactly one
-- of each wanted kind grows.
--
-- the recipe is a list of slots, each a mushroom kind and a state:
-- 0 still wanted, 1 in the basket, 3 in the air on its way to the
-- cauldron, 2 in the cauldron. nothing is ever taken back out: picking
-- the wrong mushroom poisons her, which slows her, grounds her broom and
-- sets the mushrooms dancing faster (see `dance` in effects.lua).

-- as many mushrooms as the level wants, no two the same and no more than
-- two of a family. one family, picked at random, is left out of every
-- recipe, so that there is always something that is plainly not wanted.
function new_recipe()
 recipe={}
 local from_family={0,0,0,0}
 from_family[flr(rnd(4))+1]=2
 while #recipe<level_wanted[level] do
  local kind=flr(rnd(16))+1
  local family=(kind-1)\4+1
  if from_family[family]<2 and not slot_in(nil,kind) then
   from_family[family]+=1
   add(recipe,{kind=kind,state=0})
  end
 end
 message_frames=0
end

function say(text,colour)
 message,message_colour,message_frames=text,colour,90
end

-- the first slot in a state (or in any, given nil), of one kind or of any
function slot_in(state,kind)
 for slot in all(recipe) do
  if (not state or slot.state==state) and (not kind or slot.kind==kind) then
   return slot
  end
 end
end

function pick_mushroom()
 for mushroom in all(mushrooms) do
  if abs(near(mushroom.x)-witch.x)<7 and abs(mushroom.y-witch.y)<10 then
   local wanted=slot_in(0,mushroom.kind)
   del(mushrooms,mushroom)
   if wanted then
    wanted.state=1
    -- a good one goes off in gold
    burst(witch.x,witch.y-6,12,10,1.2)
    burst(witch.x,witch.y-6,5,7,0.7)
    sfx(1)
   else
    -- a bad one poisons her: it bursts in a sick green cloud and jolts
    -- the view. it costs her the time the poison lasts and nothing else;
    -- what she has gathered is safe.
    witch.poison=poison_frames
    burst(witch.x,witch.y-6,18,11,1.6)
    burst(witch.x,witch.y-6,10,2,1)
    shake=14
    say("a lookalike!",8)
    sfx(3)
   end
   return
  end
 end
end

-- at the cauldron the basket empties: each mushroom flies from her
-- pocket to the pot, one after another. true once every mushroom of the
-- recipe has landed in it.
function deliver()
 if abs(witch.x-near(cauldron_x))<=12 and witch.grounded then
  local wait=#flights*8
  for slot in all(recipe) do
   if slot.state==1 then
    slot.state=3
    add(flights,{slot=slot,x=witch.x,y=witch.y-6,frame=-wait})
    wait+=8
   end
  end
 end
 for slot in all(recipe) do
  if slot.state!=2 then return end
 end
 return true
end
