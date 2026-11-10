function reset_stats()
 stats={}
 for row in all(payouts) do
  stats[row.name],stats[row.name.."_tickets"]=0,0
 end
end

function award(name,scale)
 stats[name]+=1
 stats[name.."_tickets"]+=payouts[name].each*(scale or 1)*(stage.tickets or 1)
end

function ticket_total()
 local total=0
 for row in all(payouts) do total+=stats[row.name.."_tickets"] end
 return total
end

function start_payout(won)
 if won then award("saved") end
 local points=ticket_total()
 rows,paper={},{}
 tickets=max(1,flr(top_tickets*(2^(ticket_curve*mid(0,points/perfect_points,1))-1)/(2^ticket_curve-1)))
 for row in all(payouts) do
  if stats[row.name]>0 then
   add(rows,{label=row.label,value=stats[row.name.."_tickets"]})
  end
 end
 add(rows,{label="points",value=points})
 panel_y,panel_vy,payout_age,shown_tickets,dispensed,cheered=128,0,0,0,0
end

function payout_done()
 return dispensed>=tickets
end

function update_payout()
 payout_age+=1
 if stats.saved>0 and payout_age%9==0 then
  local x,y,colour=10+rnd(108),8+rnd(24),rnd{14,12,10,11}
  burst(x,y,24,colour,2.5)
  ring(x,y,10,colour)
 end
 panel_vy=mid(-8,(panel_vy+(payout_rest-panel_y)*spring)*damping,8)
 panel_y+=panel_vy
 local row=payout_age/row_frames
 if row==flr(row) and row<=#rows then sfx(5) end
 if payout_age>(#rows+1)*row_frames then
  shown_tickets=min(tickets,shown_tickets+max(1,tickets/total_frames))
  while dispensed<flr(shown_tickets) do
   dispensed+=1
   if #paper<250 then add(paper,{x=rnd(128),y=-4-rnd(20),vy=0.6+rnd(0.9),spin=rnd(),hue=flr(rnd(6))}) end
   if dispensed%2==0 then
    local pitch=chime[dispensed\2%10+1]
    poke(0x35fe,@0x35fe&0xc0|pitch)
    poke(0x3600,@0x3600&0xc0|pitch+7)
    sfx(15)
   end
  end
 end
 if dispensed>=tickets and not cheered then
  cheered=true
  sfx(6)
 end
 for ticket in all(paper) do
  ticket.y+=ticket.vy
  ticket.x+=sin(ticket.spin+ticket.y/40)*0.5
  ticket.spin+=0.04
  if ticket.y>130 then del(paper,ticket) end
 end
end

function draw_payout()
 local top=flr(panel_y)
 local bottom=top+30+#rows*8
 rectfill(12,top,115,bottom,0)
 rect(12,top,115,bottom,10)
 local won=stats.saved>0
 centred(won and "city saved!" or "the city falls",top+4,won and 11 or 8)
 for i,row in ipairs(rows) do
  local age=payout_age-i*row_frames
  if age>=0 then
   local y=top+6+i*8
   print(row.label,16,y,7)
   local text=tostr(flr(row.value*min(1,age/count_frames)))
   print(text,111-#text*4,y,row.value<0 and 8 or 10)
  end
 end
 local total=tostr(flr(shown_tickets))
 print("tickets",16,bottom-10,9)
 print("\^w\^t"..total,111-#total*8,bottom-13,payout_age%8<4 and 10 or 9)
 if payout_done() then
  rectfill(46,bottom+2,81,bottom+10,0)
  centred("press z",bottom+4,tick_blink() and 10 or 5)
 end
 for ticket in all(paper) do
  local face=cos(ticket.spin)
  local half=abs(face)*3
  local colour=abs(face)>0.9 and 7 or ({8,9,10,11,12,14})[(ticket.hue+flr(ticket.spin*4))%6+1]
  rectfill(ticket.x-half,ticket.y,ticket.x+half,ticket.y+2,colour)
  if half>1 then pset(ticket.x,ticket.y+1,face>0 and 1 or 7) end
 end
end
