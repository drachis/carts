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
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
SOAK_CART = os.path.join(TESTS, "test_run.p8")
HARNESS = "#include test_run.lua"
TIMEOUT_SECONDS = 240

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
    assert HARNESS in source, "soak cart layout changed"
    path = os.path.join(TESTS, "hunt_%s.p8" % name)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(source.replace(HARNESS, VARIANTS[name] + "\n" + HARNESS))
    return path


def hunt(name, runs):
    cart = write_variant(name)
    homes = [tempfile.mkdtemp(prefix="pico8_home_") for _ in range(runs)]
    processes = [
        subprocess.Popen([PICO8, "-home", home, "-x", cart], cwd=TESTS, text=True,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        for home in homes]
    crashed, finished, other = 0, 0, 0
    for process in processes:
        try:
            output, _ = process.communicate(timeout=TIMEOUT_SECONDS)
        except subprocess.TimeoutExpired:
            process.kill()
            output, _ = process.communicate()
        if "INFO: ok soak" in output:
            finished += 1
        elif process.returncode not in (0, None) and process.returncode & 0xffffffff == 0xC0000005:
            crashed += 1
        else:
            other += 1
            tail = [line for line in output.splitlines() if not line.startswith("INFO: shot")]
            print("  unexpected end (exit %s): %s" % (process.returncode, tail[-3:]))
    for home in homes:
        shutil.rmtree(home, ignore_errors=True)
    os.remove(cart)
    print("%-14s %2d ran clean, %2d crashed, %d other" % (name, finished, crashed, other))


def main(argv):
    runs = int(argv[0]) if argv else 12
    names = argv[1:] or ["baseline"]
    for name in names:
        hunt(name, runs)


if __name__ == "__main__":
    main(sys.argv[1:])
