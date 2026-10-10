"""run_tests.py - run a PICO-8 project's test carts headless and save their screenshots.

usage: py run_tests.py [--no-comments] [cart ...]

Copy this file and png.py into the project and run it there. With no carts
named it runs every tests/test_*.p8, in name order. Set PICO8 to the pico8
executable if it is not in the default location.

What it does:
  * runs gen_cart.py first, if the project has one (art, map, generated data);
  * runs each cart with `pico8 -x`, and passes it only if it printed a line
    starting "ok " (printh("ok <name>")) and nothing containing "error";
  * runs a cart again if headless PICO-8 itself died with an access
    violation, which it does now and then for no reason a cart controls;
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
import threading

from png import write_png

HERE = os.getcwd()
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
TIMEOUT_SECONDS = 540
SCREEN_ROW = re.compile(r"^INFO: (\w+) ([0-9a-f]{128})$")
CRASHED = 0xC0000005  # headless pico-8's own access violation
ATTEMPTS = 4


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
    """Run a cart headless; True if it printed its "ok" line and no error."""
    for attempt in range(ATTEMPTS):
        passed, code = run_once(cart)
        if passed or code != CRASHED:
            return passed
        print("pico-8 crashed on %s (attempt %d); running it again" % (cart, attempt + 1))
    return False


def run_once(cart):
    process = subprocess.Popen([PICO8, "-x", cart], cwd=HERE, text=True,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # a cart that is over budget or has a syntax error can idle instead of
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
    code = process.returncode & 0xffffffff
    print(save_screens(log).strip())
    if not finished or "error" in log.lower():
        print("FAIL: %s did not complete cleanly (pico8 exit code %#x)" % (cart, code))
        return False, code
    return True, code


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
