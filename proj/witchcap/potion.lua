-- potion.lua : the recipe, and what picking and delivering do to it.
--
-- mushrooms are kinds 1..16: four families of four forms, kind
-- family*4+form+1. the forms of a family are nearly alike, and none is
-- the good one: each run the recipe names one form from each of three
-- families, and every other form of those families is its lookalike.
--
-- the recipe is a list of slots, each a mushroom kind and a state:
-- 0 still wanted, 1 in the basket, 2 in the cauldron. what is in the
-- cauldron is safe; a lookalike spoils something from the basket.

function new_recipe()
 local wanted={}
 for family=0,3 do
  add(wanted,family*4+flr(rnd(4))+1)
 end
 -- one family sits the run out
 del(wanted,rnd(wanted))
 recipe={}
 for kind in all{wanted[1],wanted[2],wanted[3],rnd(wanted),rnd(wanted)} do
  add(recipe,{kind=kind,state=0})
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
  if abs(mushroom.x-witch.x)<7 and abs(mushroom.y-witch.y)<10 then
   local wanted=slot_in(0,mushroom.kind)
   if wanted then
    del(mushrooms,mushroom)
    wanted.state=1
    sfx(1)
   elseif slot_in(nil,mushroom.kind) then
    say("enough of those",6)
    sfx(6)
   else
    del(mushrooms,mushroom)
    witch.poison=poison_frames
    local spoiled=slot_in(1)
    if spoiled then spoiled.state=0 end
    say(spoiled and "a lookalike! one spoiled" or "a lookalike!",8)
    sfx(3)
   end
   return
  end
 end
end

-- at the cauldron the basket goes in; true once the recipe is complete
function deliver()
 if abs(witch.x-cauldron_x)>12 or not witch.grounded then return end
 local carried=slot_in(1)
 while slot_in(1) do slot_in(1).state=2 end
 if carried then
  say("into the pot",11)
  sfx(2)
 end
 return not slot_in(0)
end
