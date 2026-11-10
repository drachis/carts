"""capture.py - record the itch.io GIFs and screenshots with PICO-8's own
extcmd("rec"), extcmd("video") and extcmd("screen").

usage: py itch/capture.py

Builds tests/cap_main.p8: the game as tests/capture.lua (gen_cart.py's
build of it without the plan chevrons and the music sync, which no clip
shows, so the script fits beside it), the test bot steering along each stage's plan or golden
route, and itch/cap_main.lua, which films each section for 8 seconds.
PICO-8 saves to its desktop folder; this moves every crestbeat_* file it
made there into itch/, by exact name, leaving the user's own files alone.
"""
import glob
import os
import shutil
import subprocess
import sys
import time

ITCH = os.path.dirname(os.path.abspath(__file__))
HERE = os.path.dirname(ITCH)
DESKTOPS = [os.path.expanduser(r"~\OneDrive\Desktop"), os.path.expanduser(r"~\Desktop")]

with open(os.path.join(HERE, "crestbeat.p8"), encoding="utf-8") as handle:
    data = "__gfx__" + handle.read().split("__gfx__", 1)[1]
code = 'log_name="cap_main"\n'
code += "#include capture.lua\n"
code += "#include dump.lua\n#include bot.lua\n#include ../itch/cap_main.lua\n"
cart = os.path.join(HERE, "tests", "cap_main.p8")
with open(cart, "w", encoding="utf-8", newline="\n") as handle:
    handle.write("pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n" + code + data)

started = time.time()
try:
    subprocess.run([sys.executable, "run_tests.py", "tests/cap_main.p8"], cwd=HERE, check=True)
finally:
    os.remove(cart)
    for desktop in DESKTOPS:
        for path in glob.glob(os.path.join(desktop, "crestbeat_*")):
            shutil.move(path, os.path.join(ITCH, os.path.basename(path)))
            print("moved", os.path.basename(path))
