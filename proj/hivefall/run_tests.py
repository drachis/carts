"""run_tests.py - run a PICO-8 project's test carts, each in its own window, and save their screenshots.

usage: py run_tests.py [--no-comments] [cart ...]

Copy this file and png.py into the project and run it there. With no carts
named it runs every tests/test_*.p8, in name order. Set PICO8 to the pico8
executable if it is not in the default location.

What it does:
  * runs gen_cart.py first, if the project has one (art, map, generated data);
  * runs each cart with `pico8 -run`, in a PICO-8 window of its own, and
    passes it only if it printed a line starting "ok " (printh("ok <name>"))
    and nothing containing "error". The carts print to tests/test_log.p8l
    through printh's file output; headless PICO-8 read through a pipe
    crashed unpredictably. A window will open over whatever is on screen;
  * stops only the PICO-8 it started;
  * turns any screen a cart dumped (tests/dump.lua) into <name>.png;
  * with --no-comments, fails if a game module has a Lua comment (for
    projects that keep notes in CODE_NOTES.md to save characters).

Exits non-zero on the first failure, with PICO-8's own message printed.
"""
import glob
import os
import re
import subprocess
import sys
import time

from png import write_png

HERE = os.getcwd()
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
LOG = os.path.join(HERE, "tests", "test_log.p8l")
TIMEOUT_SECONDS = 540
STALL_SECONDS = 60
SCREEN_ROW = re.compile(r"^(\w+) ([0-9a-f]{128})$")


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


def read_log():
    if not os.path.exists(LOG):
        return ""
    with open(LOG, encoding="utf-8", errors="replace") as handle:
        return handle.read()


def run_cart(cart):
    """Run a cart in its own PICO-8 window; True if it printed "ok" and no error.

    The cart writes to tests/test_log.p8l (see tests/dump.lua) and this
    watches the file. PICO-8 does not close a `-run` window when the cart
    asks it to, so the process started here is stopped here; no other
    PICO-8 is touched. One run, no retries.
    """
    if os.path.exists(LOG):
        os.remove(LOG)
    process = subprocess.Popen([PICO8, "-run", cart], cwd=HERE,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    started = last_growth = time.time()
    size, why = 0, None
    while why is None:
        time.sleep(0.25)
        log = read_log()
        if len(log) != size:
            size, last_growth = len(log), time.time()
        if any(line.startswith("ok ") for line in log.splitlines()):
            why = "ok"
        elif "error" in log.lower():
            why = "the cart reported an error"
        elif process.poll() is not None:
            why = "pico-8 closed (exit code %#x)" % (process.returncode & 0xffffffff)
        elif time.time() - last_growth > STALL_SECONDS:
            # an error on pico-8's own screen, or a cart too large to run,
            # leaves the window open and the log silent
            why = "nothing printed for %d seconds; look at the pico-8 window's message" % STALL_SECONDS
        elif time.time() - started > TIMEOUT_SECONDS:
            why = "still running after %d seconds" % TIMEOUT_SECONDS
    if process.poll() is None:
        process.kill()
    process.wait()
    print(save_screens(read_log()).strip())
    if why != "ok":
        print("FAIL: %s: %s" % (cart, why))
        return False
    return True


def comments_in_modules():
    """Where the game's own Lua has a comment, as "module:line"."""
    found = []
    for module in sorted(glob.glob(os.path.join(HERE, "*.lua"))):
        in_string = False
        with open(module, encoding="utf-8") as handle:
            for number, line in enumerate(handle, 1):
                if not in_string and "--" in line.split("[[")[0]:
                    found.append("%s:%d" % (os.path.basename(module), number))
                if "[[" in line:
                    in_string = True
                if "]]" in line:
                    in_string = False
    return found


def main(argv):
    if "--no-comments" in argv:
        argv.remove("--no-comments")
        commented = comments_in_modules()
        if commented:
            print("FAIL: comments in the Lua; they belong in CODE_NOTES.md: " + ", ".join(commented))
            return 1
    if os.path.exists(os.path.join(HERE, "gen_cart.py")):
        gen = subprocess.run([sys.executable, "gen_cart.py"], cwd=HERE, text=True, capture_output=True)
        print(gen.stdout.strip())
        if gen.returncode != 0:
            print(gen.stderr)
            return 1
    carts = argv or sorted(os.path.relpath(path, HERE)
                           for path in glob.glob(os.path.join(HERE, "tests", "test_*.p8")))
    if not carts:
        print("FAIL: no test carts (tests/test_*.p8)")
        return 1
    for cart in carts:
        if not run_cart(cart):
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
