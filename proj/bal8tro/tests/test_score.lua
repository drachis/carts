last_frame=151

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
end
