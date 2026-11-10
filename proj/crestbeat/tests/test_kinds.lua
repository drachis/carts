function sfx() end
music=sfx

local function check(name,passed,detail)
 printh((passed and "pass: " or "error: ")..name.." ("..tostr(detail)..")")
end

local function kinds_test()
 reset("play")
 send_alien(0,0,kinds.gold)
 hit_alien(aliens[1],99,judgements[1])
 check("a golden alien pays its bonus",score==kinds.gold.bonus and stats.golds==1 and stats.kills==0,"score "..score)


 reset("play")
 start_stage(#stages)
 local shots=0
 for spot in all(titan.spots) do
  spot.open=99
  while spot.hp>0 do
   hit_spot(spot,guns[2].damage,judgements[1])
   shots+=1
  end
 end
 printh("the queen takes "..shots.." shock rifle shots, "..(shots/guns[2].shots).." bars (asked for "..stages[#stages].bars..")")
 reset("play")
 send_alien(-1,0,kinds.gold)
 local streets=""
 for beat=4,12,kinds.gold.track do
  clock=beat
  update_aliens()
  streets..=aliens[1].lane.." "
 end
 check("a golden alien crosses the streets halfway up the hill",streets=="-1 0 1 " and aliens[1].t==kinds.gold.depth,"streets "..streets.."at depth "..aliens[1].t)
 clock=6.5
 update_aliens()
 check("straddling two streets it can be shot from either",front_alien(-1)==aliens[1] and front_alien(0)==aliens[1] and front_alien(1)==nil,"at "..aliens[1].pos)
 reset("play")
 send_alien(-1,0,kinds.gold)
 send_alien(0,-2)
 clock=4
 update_aliens()
 check("and an alien nearer in its street shields it",front_alien(0) and not front_alien(0).harmless and #aliens==2,"front is "..(front_alien(0).harmless and "gold" or "an alien"))

 reset("play")
 send_alien(-1,0,kinds.weaver)
 streets=""
 for beat=-0.6,7.5,2 do
  clock=beat
  update_aliens()
  streets..=aliens[1].lane.." "
 end
 check("a weaver walks down sweeping across the streets every two beats",streets=="-1 0 1 0 -1 ","streets "..streets)
 reset("play")
 for i=1,10 do award("kills") end
 award("golds")
 award("civilians")
 award("civilians")
 start_payout(true)
 local lowest=panel_y
 for i=1,200 do
  update_payout()
  lowest=min(lowest,panel_y)
 end
 local expected=10*payouts.kills.each+payouts.golds.each+2*payouts.civilians.each+payouts.saved.each
 check("the payout adds up each row at level one and pays tickets on the curve",rows[5].value==expected and tickets==22,rows[5].value.." points, "..tickets.." tickets")
 check("and dispenses every one",dispensed==tickets and payout_done(),dispensed.." dispensed")
 check("its panel springs up past its rest and settles",lowest<payout_rest-1 and abs(panel_y-payout_rest)<0.5,"lowest "..lowest..", rests at "..panel_y)
 reset("play")
 start_payout(false)
 check("a run with nothing pays one ticket",tickets==1,tickets.." tickets")
 local curve=""
 for share in all({1,0.99,0.5}) do
  stats.kills_tickets=perfect_points*share
  start_payout(false)
  curve..=tickets.." "
 end
 check("tickets rise exponentially to 500 for a perfect run only",curve=="500 490 166 ",curve)
 reset("play")
 send_alien(0,0)
 send_alien(1,0)
 clock=kinds.alien.walk+1.5
 update_aliens()
 check("an alien reaching the robot's street is body-blocked: a heart, but downed; one elsewhere leaks",robot.hp==max_hp-2 and stats.kills==1,"hp "..robot.hp..", downed "..stats.kills)
 printh("ok kinds")
 extcmd("shutdown")
end

local done
function _update()
 if not done then
  done=true
  run_frame(kinds_test)
 end
end
function _draw() end
