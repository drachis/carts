"""capture.py - build and run carts that record the itch.io GIFs and
screenshots with PICO-8's own extcmd("rec"), extcmd("video"), extcmd("screen").
PICO-8 saves them to its desktop folder. usage: py itch/capture.py

Each cart is the game with the screens it does not film cut out, so that its
scripted player fits 8192 tokens.
"""
import os
import re
import subprocess
import sys

ITCH = os.path.dirname(os.path.abspath(__file__))
HERE = os.path.dirname(ITCH)
TESTS = os.path.join(HERE, "tests")
MODULES = ["data", "world", "scenery", "loretta", "things", "camera", "main"]
CARTS = {
    "cap_main": ["_init", "go_title", "draw_title", "update_title", "update_over", "game_over", "touch_bone", "update_bone", "draw_bone"],
}

for cart, names in CARTS.items():
    with open(os.path.join(HERE, "loretta.p8"), encoding="utf-8") as handle:
        art = handle.read().split("__gfx__", 1)[1]
    code = ""
    for module in MODULES:
        with open(os.path.join(HERE, module + ".lua"), encoding="utf-8") as handle:
            text = handle.read()
        for name in names:
            text = re.sub(r"^function %s\(.*?^end\n" % re.escape(name), "", text, flags=re.M | re.S)
        code += text
    with open(os.path.join(ITCH, cart + ".lua"), encoding="utf-8") as handle:
        code += handle.read()
    path = os.path.join(TESTS, cart + ".p8")
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n" + code + "\n__gfx__" + art)
    subprocess.run([sys.executable, "run_tests.py", "tests/%s.p8" % cart], cwd=HERE, check=True)
    os.remove(path)
