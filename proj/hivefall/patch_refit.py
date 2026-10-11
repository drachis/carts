"""Extends refit.py with the blocks/rooftops and ammo-rarity notes; deleted after running."""
s = open('refit.py', encoding='utf-8').read()

start = s.index("sub('world.lua', [\n (\"    if wrecked then roof,wall=5,0 end")
end = s.index(" (\"function update_effects()\n\"")
new_world = r'''sub('world.lua', [
 (" local near=mid(0,(far_z/z-1)/(far_z-1),1)\n", " local near=max((far_z/z-1)/(far_z-1))\n"),
])
between('world.lua', "-- the hill is drawn over anything still behind its crest.", "-- sparks, rings and popups live in screen space.",
"""-- the hill is drawn over anything still behind its crest. its slope is
-- the city, sliding toward the mech as it advances and on under it to the
-- bottom of the screen. streets run along every second grid line, so the
-- cube houses stand in blocks of four. the more of the swarm has got
-- through, the more of the houses are burnt-out wrecks.
function draw_hill()
 circfill(64,crest_y+350,350,0)
 rectfill(0,crest_y+12,127,127,0)

 local colour=grid_flash>0 and 13 or 1
 local slide=travel/0.625%1
 local turn=travel\0.625
 local depths={far_z}
 for k=8,0,-1 do
  local z=1+(k-slide)*0.625
  if (k+turn)%2==0 and z>0.9 then add(depths,z) end
 end
 add(depths,0.9)
 for z in all(depths) do
  line()
  for x=-100,100,20 do grid_point(x,z,colour) end
 end
 for x=-100,100,40 do
  line()
  for z in all(depths) do grid_point(x,z,colour) end
 end

 for k=8,-1,-1 do
  local row=(k+turn)%8
  local front=1+(k-slide)*0.625
  local back=min(front+0.625,far_z)
  -- a gap for the street on the block's outer sides only
  if row%2==0 then front+=0.12 else back-=0.12 end
  front=max(front,0.9)
  if back>front then
   for column=0,9 do
    local left=column*20-100
    local right=left+20
    if column%2==0 then left+=4 else right-=4 end
    local seed=(column*7+row*13)%20
    local wrecked=seed<(100-city)/5
    local height=wrecked and 2 or 4+seed%9
    local x1,top,scale=project(left,front,height)
    local x2=project(right,front,height)
    local _,far_top=project(left,back,height)
    local roof,wall=1,5
    if wrecked then roof,wall=2,0 end
    if city_flash>0 and k<3 and tick%4<2 then roof,wall=8,2 end
    rectfill(x1,far_top,x2,top,roof)
    rectfill(x1,top+1,x2,top+height*scale,wall)
    if wrecked then
     pset(x1+seed%4,far_top+1,(tick\6+seed)%3==0 and 9 or 8)
     pset(x2-seed%3,top-1,(tick\5+seed)%3==0 and 10 or 0)
     if rnd()<0.01 then
      burst((x1+x2)/2,far_top,1,rnd{8,9,6},0.5,-0.04)
     end
    elseif scale>0.5 then
     -- a lit window, and something on the roof to fly over
     pset(x1+1+seed%3,top+2,10)
     rectfill(x1+2,far_top+2,x1+2+scale*3,far_top+1+scale*2,13)
    end
   end
  end
 end
end

""")
sub('world.lua', [
'''
s = s[:start] + new_world + s[end:]

s = s.replace("print(\"refit applied\")", r'''between('foes.lua', " elseif roll<0.6 then\n", "  if weapon then kind,colour", """ elseif roll<0.6 then
  -- ammo for a gun that has room, the heavier the shell the rarer
  local total=0
  for candidate in all(weapon_specs) do
   if candidate.wave<=wave and candidate.ammo>0
    and candidate.rounds<candidate.ammo then
    local weight=1/sqrt(candidate.damage*candidate.count+candidate.splash/4)
    total+=weight
    if rnd(total)<weight then weapon=candidate end
   end
  end
""")
sub('foes.lua', [
 ("-- plate when armour is low, else ammo for the emptiest gun, a charge of",
  "-- plate when armour is low, else ammo (rarer for heavier guns), a charge of"),
])
print("refit applied")''')
open('refit.py', 'w', encoding='utf-8', newline='\n').write(s)
