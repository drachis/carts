last_frame=200

function check(n)
 if n==89 then
  expect("a scoring card throws sparks and bumps chips",#particles>0 and chips_bump>0,true)
  expect("a scoring card is kicked",played[1].kick>0,true)
 end
 if n==120 or n==148 then
  local flames=0
  for p in all(particles) do if p.spec.name=="flame" then flames+=1 end end
  expect("flames at frame "..n.." (on once 80x6 beats 300)",flames>0,n==148)
 end
 if n==125 then expect("a joker shakes when it fires",jokers[1].kick>0,true) end
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
