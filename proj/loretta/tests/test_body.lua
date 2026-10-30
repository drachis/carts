-- test_body.lua : Loretta's body: paws planted in her trot, her ears and
-- tongue following her head as she runs, her ears flopping and belly
-- bouncing on landing (ears_landing). her poses are in test_poses.

local function feet()
 local placed={}
 for i=1,#loretta_legs,5 do
  local joint_x,joint_y,dx,lift=leg_place(hero,i)
  add(placed,{x=hero.x+joint_x+dx,down=lift==0})
 end
 return placed
end

local function ear_rise() return hero.y-hero.ears[2].y end

cases={
 {
  name="her paws stay planted while she trots, in diagonal pairs",buttons={1},frames=120,
  setup=function() arena(16) result.slip,result.last,result.steps=0,nil,0 end,
  each=function()
   local now=feet()
   if result.last and abs(hero.vx)>=0.4 then
    for i,foot in ipairs(now) do
     local before=result.last[i]
     if foot.down and before.down then result.slip=max(result.slip,abs(foot.x-before.x)) end
     if foot.down and not before.down then result.steps+=1 end
    end
   end
   result.last=now
   result.pairs=now[2].down==now[3].down and now[1].down==now[4].down and now[1].down!=now[2].down
  end,
  check=function() return result.slip<0.1 and result.pairs,"largest slip of a planted paw "..result.slip.."px, "..result.steps.." paws put down in 2 seconds, pairs together "..tostr(result.pairs) end,
 },
 {
  name="running, her ears lean back and her tongue trails behind",buttons={1},frames=90,
  setup=function() arena(16) end,
  check=function()
   local ear,tip,root=hero.ears[2],hero.tongue[3],hero.tongue[1]
   return ear.x<ear.bx-3 and tip.x<root.x,"ear tip "..flr(ear.x-ear.bx).."px across from its base, tongue tip "..flr(tip.x-root.x).."px across from the mouth"
  end,
 },
 {
  name="landing, her ears flop down then spring back, and her belly bounces",buttons={},frames=70,every_frame=true,
  setup=function() arena(40,30) result.lowest,result.belly,result.frame=0,0,0 end,
  each=function()
   result.frame+=1
   result.lowest=min(result.lowest==0 and 99 or result.lowest,ear_rise())
   result.belly=max(result.belly,hero.sag)
   if hero.squash==4 then dump_screen("ears_landing") end
  end,
  check=function() return result.belly>1.4 and ear_rise()>result.lowest+2,"belly sagged to "..result.belly..", ears from "..result.lowest.." to "..ear_rise().."px above her" end,
 },
}
