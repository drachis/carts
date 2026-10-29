-- arena.lua : shared by test_moves and test_body, after harness.lua: the
-- real level with no things in it but what a case puts there. the street
-- has a sidewalk at y 96, so Loretta stands at y 82.

ground_y,result=82,{}

function arena(x,y)
 start_level()
 mode,things,hero="play",{},new_loretta(x,y or ground_y)
 hero.held=0
 view=new_camera(hero)
end

function thing_at(name,x,y)
 return add(things,setmetatable({x=x,y=y,vx=0,vy=0,age=0,petting=0},thing_specs[name]))
end
