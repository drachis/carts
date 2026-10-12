-- test_drops.lua : what each kind of foe leaves. every gun is issued and
-- half empty, the mech's armour is full, and each kind of foe is made to
-- drop 300 times. any ammo it leaves must be for the gun it is weak to
-- (flak if it has no weakness) or, rarely, the redeemer. prints the
-- counts. it does not check how often a kill drops anything in play.

function sfx() end
music=sfx

function _draw() end

function _update60()
 reset()
 wave=8
 for spec in all(enemy_specs) do
  local counts,line={},spec.name..":"
  for try=1,300 do
   drops={}
   for weapon in all(weapon_specs) do weapon.rounds=weapon.ammo\2 end
   maybe_drop{points=50,z=3,x=0,weak=spec.weak}
   local kind=drops[1] and drops[1].kind or "nothing"
   counts[kind]=(counts[kind] or 0)+1
   local weapon=drops[1] and drops[1].weapon
   if weapon and weapon.name!="redeemer"
    and weapon.name!=(spec.weak or "flak") then
    printh("error: "..spec.name.." left "..weapon.name.." ammo")
   end
  end
  for kind,count in pairs(counts) do
   line..=" "..kind.." "..count
  end
  printh(line)
  if not counts[spec.weak or "flak"] then
   printh("error: "..spec.name.." never left ammo for its weakness")
  end
 end
 printh("ok drops")
 extcmd("shutdown")
end
