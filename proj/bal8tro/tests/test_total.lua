last_frame=200

function check(n)
 if n==150 then
  printh("cpu while scoring with flames: "..stat(1).." at "..stat(7).." fps")
  dump_screen("boot_score")
 end
 if n==161 then expect("the total holds the game for a beat",freeze>0,true) end
 if n==162 then
  local big
  for p in all(pops) do if p.big then big=p.text end end
  expect("the total pops up big",big,"480")
  expect("the total shakes the screen",shake>1,true)
  dump_screen("boot_total")
 end
end
