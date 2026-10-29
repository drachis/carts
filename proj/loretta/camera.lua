function new_camera(hero)
 local view={look=0}
 view.x=focus_x(hero,view)
 return view
end

function focus_x(hero,view)
 return mid(0,hero.x+hero_w/2-64+view.look,level_w-128)
end

function update_camera(view,hero)
 local speed=abs(hero.vx)/run_max
 view.look+=(sgn(hero.vx)*camera_lookahead*min(speed,1)*(speed>0.1 and 1 or 0)-view.look)*camera_lookahead_speed
 view.x+=(focus_x(hero,view)-view.x)*camera_speed_change
end
