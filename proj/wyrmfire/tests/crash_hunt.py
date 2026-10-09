"""crash_hunt.py - run many soak tests at once to chase an intermittent crash.

usage: py tests/crash_hunt.py [runs_per_variant] [variant ...]

Headless PICO-8 runs in real time, so one soak takes a couple of minutes and
a crash that shows up once in eight runs is slow to study one at a time.
This runs `runs_per_variant` copies of the soak cart in parallel for each
variant and reports how many crashed. Every copy gets its own PICO-8 home
folder (-home), so the copies cannot trip over each other's log, config or
save files, nor over a PICO-8 the user has open.

A variant is some Lua run after the game is loaded and before the soak
starts, used to switch parts of the game off. Run run_tests.py first so the
soak cart and its generated main module are up to date.
"""
import os
import shutil
import subprocess
import sys
import tempfile

TESTS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(TESTS))
import run_tests  # noqa: E402  (for its module-stubbing helper)

PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
SOAK_CART = os.path.join(TESTS, "test_run.p8")
HARNESS = "#include test_run.lua"
SOAK_MAIN = "#include soak_main.lua"
SOAK_STUBS = run_tests.GENERATED["soak_main.lua"][1]
TIMEOUT_SECONDS = 240

# a variant can also edit the text of main.lua before it is built: a list
# of (old, new) replacements. this costs no tokens, which matters because
# the soak cart has none to spare for the Lua variants below; those may now
# be refused by pico-8 as too large, which shows up as "other".
EDITS = {
    # the two outline circles the hud draws
    "no_meal_ring": [("  circ(34,4,14-belly_pop,10)\n", "")],
    "no_ward_rings": [("  circ(86+ward*7,4,2,12)\n", "")],
    # the hud's outline circles kept, but neither reaching off the screen
    "small_meal_ring": [("circ(34,4,14-belly_pop,10)", "circ(34,4,3,10)")],
    # everything in the hud but its outline circles
    "no_hud_circ": [("  circ(34,4,14-belly_pop,10)\n", ""), ("  circ(86+ward*7,4,2,12)\n", "")],
    # the hud's outline circles drawn filled instead
    "hud_circfill": [("  circ(34,4,14-belly_pop,10)\n", "  circfill(34,4,14-belly_pop,10)\n"),
                     ("  circ(86+ward*7,4,2,12)\n", "  circfill(86+ward*7,4,2,12)\n")],
    # the game unchanged, but printing lua's memory use (kb of 2048) and
    # counts of live objects every 100 frames, to see what a run looks
    # like just before it dies. (update_reel is stubbed to make room.)
    "memory_trace": [(" shake*=.8\n",
                      " shake*=.8\n if frame%100==0 then printh('mem '..frame..' '"
                      "..stat(0)..' '..#particles..' '..#units..' '..#shots) end\n")],
    # other hud suspects, with its circles left in
    "no_hits_text": [("   print(text,126-#text*4,12,blink and 10 or 9)\n", "")],
    "no_compass": [("\n draw_compass()\n", "\n")],
}

# functions a variant stubs in main.lua, beyond the soak's own, for room
EXTRA_STUBS = {"memory_trace": ["update_reel"]}

VARIANTS = {
    "baseline": "",
    "no_draw": "function _draw() end",
    # the whole game updates, but drawing is one trivial call
    "trivial_draw": "function _draw() cls(frame%16) end",
    # none of the game's drawing, just a great deal of harmless slow drawing
    "slow_trivial_draw": ("function _draw()\n for i=1,300 do circfill(64,64,63,i%16) end\nend"),
    # the same, but only about as costly as the game's own drawing
    "medium_trivial_draw": ("function _draw()\n for i=1,25 do circfill(64,64,63,i%16) end\nend"),
    # only the two parts whose removal stopped the crash
    "only_world_and_particles": ("function draw_dragon() end\nfunction draw_hud() end\n"
                                 "function map() end"),
    # the world's parts switched off one at a time
    "no_fire_drawn": "function draw_fire() end",
    "no_buildings_drawn": "function draw_buildings() end",
    "no_units_drawn": "function draw_units() end",
    "no_shots_drawn": "function draw_shots() end",
    # outline circles are the one call that buildings (domes), shots
    # (landing rings) and particles (shockwaves) share
    "no_circ": "function circ() end",
    "whole_radius_circ": ("local real_circ=circ\n"
                          "function circ(x,y,r,c) real_circ(x,y,flr(r),c) end"),
    "whole_everything_circ": ("local real_circ=circ\n"
                              "function circ(x,y,r,c) real_circ(flr(x),flr(y),flr(r),c) end"),
    # circ untouched, but every odd argument reported (once per kind)
    "report_circ": ("local real_circ,seen=circ,{}\n"
                    "function circ(x,y,r,c)\n"
                    " local note=(r==nil and 'nil radius') or (r<0 and 'negative radius')\n"
                    "  or (r!=flr(r) and 'fractional radius') or (r>100 and 'huge radius')\n"
                    "  or (c==nil and 'nil color') or (c!=flr(c) and 'fractional color')\n"
                    " if note and not seen[note] then\n"
                    "  seen[note]=true printh('circ: '..note..' r='..tostr(r)..' c='..tostr(c))\n"
                    " end\n"
                    " real_circ(x,y,r,c)\n"
                    "end"),
    # circ replaced by a lua function that passes everything through unchanged
    "passthrough_circ": ("local real_circ=circ\n"
                         "function circ(x,y,r,c) real_circ(x,y,r,c) end"),
    # one part of the drawing switched off at a time
    "no_dragon_drawn": "function draw_dragon() end",
    "no_particles_drawn": "function draw_particles() end",
    "no_hud_drawn": "function draw_hud() end",
    "no_map_drawn": "function map() end",
    "no_world_drawn": ("function draw_fire() end\nfunction draw_buildings() end\n"
                       "function draw_units() end\nfunction draw_shots() end"),
    "no_particles": "function add_particle() return {} end",
    "no_units": "function spawn_unit() end",
    "no_shots": "function shoot() end",
    "no_fire": "function ignite() end",
    "no_unit_grid": "memset=function() end\npoke=memset",
}


def write_variant(name):
    """A copy of the soak cart with the variant's Lua ahead of the harness."""
    source = open(SOAK_CART, encoding="utf-8").read()
    assert HARNESS in source and SOAK_MAIN in source, "soak cart layout changed"
    # each variant gets its own copy of the soak's main module
    hunt_main = "hunt_main_%s.lua" % name
    run_tests.stub_module(hunt_main, "main.lua", SOAK_STUBS + EXTRA_STUBS.get(name, []))
    main_path = os.path.join(TESTS, hunt_main)
    text = open(main_path, encoding="utf-8").read()
    for old, new in EDITS.get(name, []):
        assert old in text, "%s: could not find %r in main.lua" % (name, old)
        text = text.replace(old, new)
    with open(main_path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
    source = source.replace(SOAK_MAIN, "#include " + hunt_main)
    path = os.path.join(TESTS, "hunt_%s.p8" % name)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(source.replace(HARNESS, VARIANTS.get(name, "") + "\n" + HARNESS))
    return path


def hunt(name, runs):
    cart = write_variant(name)
    homes = [tempfile.mkdtemp(prefix="pico8_home_") for _ in range(runs)]
    processes = [
        subprocess.Popen([PICO8, "-home", home, "-x", cart], cwd=TESTS, text=True,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        for home in homes]
    crashed, finished, other = 0, 0, 0
    notes = set()  # anything a variant reports about itself, e.g. report_circ
    for process in processes:
        try:
            output, _ = process.communicate(timeout=TIMEOUT_SECONDS)
        except subprocess.TimeoutExpired:
            process.kill()
            output, _ = process.communicate()
        notes.update(line for line in output.splitlines() if line.startswith("INFO: circ:"))
        if "INFO: ok soak" in output:
            finished += 1
        elif process.returncode not in (0, None) and process.returncode & 0xffffffff == 0xC0000005:
            crashed += 1
            # the last things a crashed run said
            said = [line for line in output.splitlines()
                    if line.startswith("INFO:") and not line.startswith("INFO: shot")]
            print("  crashed after: " + " | ".join(said[-3:]))
        else:
            other += 1
            tail = [line for line in output.splitlines() if not line.startswith("INFO: shot")]
            print("  unexpected end (exit %s): %s" % (process.returncode, tail[-3:]))
    for home in homes:
        shutil.rmtree(home, ignore_errors=True)
    os.remove(cart)
    print("%-14s %2d ran clean, %2d crashed, %d other" % (name, finished, crashed, other))
    for note in sorted(notes):
        print("  " + note)


def main(argv):
    runs = int(argv[0]) if argv else 12
    names = argv[1:] or ["baseline"]
    for name in names:
        hunt(name, runs)


if __name__ == "__main__":
    main(sys.argv[1:])
