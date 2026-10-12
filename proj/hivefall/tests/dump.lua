-- dump.lua : test helpers, included by every test cart before its test.
--
-- everything a test prints goes to tests/test_log.p8l, through printh's
-- own file output (manual 6.1), and run_tests.py reads that file. the
-- tests run in a pico-8 window of their own, not headless with a pipe:
-- headless pico-8 crashed unpredictably that way.
local console,log_started=printh
function printh(text)
 console(text,"test_log",not log_started)
 log_started=true
end

-- prints the screen as 128 lines of hex digits, one per pixel, each line
-- tagged with a name; run_tests.py collects them and writes <name>.png.
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
