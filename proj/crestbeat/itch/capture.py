"""capture.py - record the itch.io GIFs and screenshots with PICO-8's own
extcmd("rec"), extcmd("video") and extcmd("screen").

usage: py itch/capture.py

Builds two carts and runs them at once: tests/cap_play.p8 films the stages
and tests/cap_menus.p8 the title and the payout. Each includes a gen_cart.py
build of the game without what its clips never show (tests/capture_play.lua,
tests/capture_menus.lua), so the script fits beside it, the test bot
steering along each stage's plan or golden route, and itch/cap_main.lua,
which films each of its sections for 8 seconds. PICO-8 saves to its desktop
folder; this moves every crestbeat_* file there into itch/, by exact name,
leaving the user's own files alone, even when a run fails.
"""
import glob
import os
import shutil
import subprocess
import sys

ITCH = os.path.dirname(os.path.abspath(__file__))
HERE = os.path.dirname(ITCH)
DESKTOPS = [os.path.expanduser(r"~\OneDrive\Desktop"), os.path.expanduser(r"~\Desktop")]
CARTS = {
    "cap_play": ("capture_play.lua", "hill streets titan queen fever finale"),
    "cap_menus": ("capture_menus.lua", "title payout"),
}

with open(os.path.join(HERE, "crestbeat.p8"), encoding="utf-8") as handle:
    data = "__gfx__" + handle.read().split("__gfx__", 1)[1]
carts = []
for name, (build, sections) in CARTS.items():
    code = 'log_name="%s"\n' % name
    code += 'filming={}\nfor name in all(split("%s"," ")) do filming[name]=true end\n' % sections
    code += "#include %s\n#include dump.lua\n#include bot.lua\n#include ../itch/cap_main.lua\n" % build
    cart = os.path.join("tests", name + ".p8")
    with open(os.path.join(HERE, cart), "w", encoding="utf-8", newline="\n") as handle:
        handle.write("pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n" + code + data)
    carts.append(cart)

try:
    subprocess.run([sys.executable, "run_tests.py"] + carts, cwd=HERE, check=True)
finally:
    for cart in carts:
        os.remove(os.path.join(HERE, cart))
    for desktop in DESKTOPS:
        for path in glob.glob(os.path.join(desktop, "crestbeat_*")):
            shutil.move(path, os.path.join(ITCH, os.path.basename(path)))
            print("moved", os.path.basename(path))
