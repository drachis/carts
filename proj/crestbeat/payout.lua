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
 rows,tickets,paper={},max(ticket_total(),1),{}
 for row in all(payouts) do
  if stats[row.name]>0 then
   add(rows,{label=row.label,value=stats[row.name.."_tickets"]})
  end
 end
 panel_y,panel_vy,payout_age,shown_tickets,dispensed=128,0,0,0,0
end

function payout_done()
 return dispensed>=tickets
end

function update_payout()
 payout_age+=1
 panel_vy=mid(-8,(panel_vy+(payout_rest-panel_y)*spring)*damping,8)
 panel_y+=panel_vy
 local row=payout_age/row_frames
 if row==flr(row) and row<=#rows then sfx(5) end
 if payout_age>(#rows+1)*row_frames then
  shown_tickets=min(tickets,shown_tickets+max(1,tickets/total_frames))
  while dispensed<flr(shown_tickets) do
   dispensed+=1
   add(paper,{x=60+rnd(8),y=127,vx=rnd(3)-1.5,vy=-2-rnd(3)})
   if dispensed%2==0 then sfx(15) end
  end
 end
 for ticket in all(paper) do
  ticket.x+=ticket.vx
  ticket.y+=ticket.vy
  ticket.vy+=0.2
  if ticket.y>130 then del(paper,ticket) end
 end
end

function draw_payout()
 for ticket in all(paper) do
  rectfill(ticket.x,ticket.y,ticket.x+3,ticket.y+1,9)
  pset(ticket.x+1,ticket.y,8)
 end
 rectfill(56,125,71,127,5)
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
end
