"""run_tests.py - regenerate the cart's data, run the test carts, save screenshots.

usage: py run_tests.py
Set PICO8 to the pico8 executable if it is not in the default location.
Exits non-zero if the level fails its checks, a cart fails to run or reports
an error, or a cart never prints its "ok" line.

Carts print screens as text (tests/dump.lua); each becomes <name>.png here.
"""
import os
import re
import subprocess
import sys
import threading

from png import write_png

HERE = os.path.dirname(os.path.abspath(__file__))
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
TEST_CARTS = [os.path.join("tests", name) for name in ("test_data.p8", "test_run.p8")]
MODULES = ["data.lua", "core.lua", "world.lua", "units.lua", "dragon.lua", "main.lua"]
TIMEOUT_SECONDS = 540
SCREEN_ROW = re.compile(r"^INFO: (\w+) ([0-9a-f]{128})$")


def save_screens(log):
    """Pull dumped screens out of a cart's output; return the rest of it."""
    screens, rest = {}, []
    for line in log.splitlines():
        row = SCREEN_ROW.match(line)
        if row:
            screens.setdefault(row.group(1), []).append(row.group(2))
        else:
            rest.append(line)
    for name, rows in screens.items():
        if len(rows) == 128:
            write_png(os.path.join(HERE, name + ".png"), rows)
            rest.append("wrote %s.png" % name)
        else:
            rest.append("incomplete screen %s: %d rows" % (name, len(rows)))
    return "\n".join(rest)


def run_cart(cart):
    # the soak runs in a window: headless pico-8 sometimes dies on it with an
    # access violation, as it did on wyrmfire (see ../wyrmfire/DESIGN.md)
    mode = "-run" if cart.endswith("test_run.p8") else "-x"
    process = subprocess.Popen([PICO8, mode, cart], cwd=HERE, text=True,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # a cart that is over budget or has a syntax error idles instead of
    # exiting, so stop it at the time limit
    watchdog = threading.Timer(TIMEOUT_SECONDS, process.kill)
    watchdog.start()
    lines, finished = [], False
    for line in process.stdout:
        lines.append(line)
        if line.startswith("INFO: ok ") and not finished:
            finished = True
            threading.Timer(3, process.kill).start()
        if "too large" in line or "error" in line.lower():
            lines += process.stdout.readlines(2000)
            process.kill()
            break
    watchdog.cancel()
    process.wait()
    log = "".join(lines)
    print(save_screens(log).strip())
    if not finished or "error" in log.lower():
        print("FAIL: %s did not complete cleanly (pico8 exit code %#x)"
              % (cart, process.returncode & 0xffffffff))
        return False
    return True


def comments_in_modules():
    """Where the game's Lua has a comment, as "module:line".

    The modules carry none: PICO-8 counts them against its character limit,
    so notes on the code are kept in CODE_NOTES.md instead.
    """
    found = []
    for module in MODULES:
        in_string = False
        with open(os.path.join(HERE, module), encoding="utf-8") as handle:
            for number, line in enumerate(handle, 1):
                if not in_string and "--" in line.split("[[")[0]:
                    found.append("%s:%d" % (module, number))
                if "[[" in line:
                    in_string = True
                if "]]" in line:
                    in_string = False
    return found


def main():
    commented = comments_in_modules()
    if commented:
        print("FAIL: comments in the Lua; they belong in CODE_NOTES.md: " + ", ".join(commented))
        return 1
    gen = subprocess.run([sys.executable, "gen_cart.py"], cwd=HERE, text=True, capture_output=True)
    print(gen.stdout.strip())
    if gen.returncode != 0:
        print(gen.stderr)
        return 1
    for cart in TEST_CARTS:
        if not run_cart(cart):
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
