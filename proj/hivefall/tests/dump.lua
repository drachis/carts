-- dump.lua : test helper. prints the screen as 128 lines of hex digits,
-- one per pixel, each line tagged with a name; run_tests.py collects the
-- lines and writes <name>.png.
--
-- (saving the screen with cstore to a second cart is less code, but
-- headless pico-8 crashed with an access violation now and then while
-- doing it, more often the more it was called.)
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
