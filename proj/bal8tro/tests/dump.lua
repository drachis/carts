-- dump.lua : test helpers, included by every test cart before its test.
--
-- everything a test prints goes to a log of the cart's own, tests/<log_name>.p8l,
-- through printh's own file output (manual 6.1), and run_tests.py reads
-- that file. each cart sets log_name before its includes ("log_boot" for
-- test_boot.p8), so the carts can all run at once. they run in pico-8
-- windows of their own, not headless with a pipe: headless pico-8
-- crashed unpredictably that way.
local console,log_started=printh
function printh(text)
 console(text,log_name,not log_started)
 log_started=true
end

-- a test cart's _update60 is `run_frame(work)`, with the frame's real work
-- in a function. the work is run as a coroutine, because a runtime error
-- inside a coroutine does not stop pico-8 at its own screen, where only
-- a person can see it: coresume returns false and the message (manual,
-- 6.14), and the message goes to the log, where run_tests.py fails the
-- cart at once. the first frame prints "started", which is how the
-- runner tells a cart that is running from one that never loaded.
local started,crashed
function run_frame(work)
 if crashed then return end
 if not started then
  started=true
  printh("started")
 end
 local finished,message=coresume(cocreate(work))
 if not finished then
  crashed=true
  printh("error: "..tostr(message))
 end
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
