-- screen.lua : prints the screen as 128 lines of hex digits, one per pixel,
-- each line tagged with a name; run_tests.py collects them and writes
-- <name>.png. included after dump.lua by the carts that dump screens;
-- test_boot leaves it out to keep the whole game's room.
function dump_screen(name)
 for y=0,127 do
  local row=""
  for x=0,127 do
   local digit=pget(x,y)+1
   row..=sub("0123456789abcdef",digit,digit)
  end
  printh(name.." "..row)
 end
end
