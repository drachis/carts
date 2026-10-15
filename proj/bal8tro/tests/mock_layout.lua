function box(x0,y0,x1,y1,fill,edge)
 rectfill(x0,y0,x1,y1,fill)
 if edge then rect(x0,y0,x1,y1,edge) end
end

function label(text,x,y,colour,width)
 print(text,x+(width-#text*4)\2+1,y,colour)
end

function mini_joker(name,x,y,focused)
 box(x,y,x+19,y+19,7,focused and 10 or 13)
 label(name,x,y+2,2,20)
 circfill(x+10,y+12,4,focused and 9 or 14)
end

function draw_mock(with_tip)
 draw_swirl(3,1,0)
 box(0,0,38,127,1)
 line(39,0,39,127,0)
 box(1,1,37,11,12)
 label("small",1,2,7,37)
 label("blind",1,7,7,37)
 box(2,14,36,27,0)
 label("score at",2,15,6,35)
 label("least 300",2,21,8,35)
 box(2,30,36,41,0)
 label("round",2,31,6,35)
 label("0",2,36,7,35)
 label("pair lv1",1,45,7,37)
 box(2,52,18,60,12)
 box(20,52,36,60,8)
 label("10",2,54,7,17)
 label("2",20,54,7,17)
 box(2,64,18,78,0)
 box(20,64,36,78,0)
 label("hand",2,65,6,17)
 label("4",2,72,12,17)
 label("disc",20,65,6,17)
 label("3",20,72,8,17)
 box(2,82,36,94,0)
 label("$4",2,86,10,35)
 box(2,98,18,110,0)
 box(20,98,36,110,0)
 label("ante",2,99,6,17)
 label("1/8",2,105,10,17)
 label("round",20,99,6,17)
 label("1",20,105,9,17)
 label("⬆️jokers",1,116,5,37)
 mini_joker("joker",42,3,with_tip)
 mini_joker("sly",63,3)
 mini_joker("jolly",84,3)
 rect(105,3,124,22,11)
 label("0/2",105,25,5,20)
 draw_back(110,40)
 draw_back(109,39)
 for i,c in ipairs(split"1,2,9,13,13,7,4,2") do
 end
 local ranks,suits=split"13,13,11,9,7,5,4,2",split"1,2,3,4,1,2,3,4"
 for i=1,8 do
  local picked=i<=2
  draw_card({rank=ranks[i],suit=suits[i],glide_x=40+(i-1)*11,glide_y=picked and 72 or 78,wait=0},40+(i-1)*11,picked and 72 or 78)
 end
 rect(51-1,71,51+15,93,10)
 box(42,104,80,113,12)
 label("play hand",42,107,7,39)
 box(86,104,124,113,8)
 label("discard",86,107,7,39)
 label("8/8",40,117,6,88)
 if with_tip then
  box(40,25,98,45,7,0)
  label("joker",40,27,2,58)
  label("+4 mult",40,33,8,58)
  label("$2 sell $1",40,39,5,58)
 end
end

frame=0
function _update60()
 run_frame(function()
  frame+=1
  draw_mock(frame>2)
  if frame==2 then dump_screen("mock_layout") end
  if frame==4 then
   dump_screen("mock_layout_tip")
   printh("ok layout")
   extcmd("shutdown")
  end
 end)
end

function _draw() end
