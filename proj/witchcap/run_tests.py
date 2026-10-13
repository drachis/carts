"""run_tests.py - run a PICO-8 project's test carts, all at once, and save their screenshots.

usage: py run_tests.py [--no-comments] [cart ...]

Run it in the project folder. With no carts named it runs every
tests/test_*.p8. Set PICO8 to the pico8 executable if it is not in the
default location.

What it does:
  * runs gen_cart.py first, if the project has one (art, map, generated data);
  * starts every cart at the same time with `pico8 -run`, each in a PICO-8
    window of its own, so the run takes as long as the slowest cart and
    not the sum of them. A window for each cart will open over whatever is
    on screen;
  * passes a cart only if it printed a line starting "ok " (printh("ok
    <name>")) and nothing containing "error". Each cart prints to a log of
    its own, tests/log_<name>.p8l for tests/test_<name>.p8, through
    printh's file output (see tests/dump.lua); headless PICO-8 read
    through a pipe crashed unpredictably;
  * stops only the PICO-8s it started;
  * turns any screen a cart dumped (tests/dump.lua) into <name>.png;
  * with --no-comments, fails if a game module has a Lua comment (for
    projects that keep notes in CODE_NOTES.md to save characters).

Results are printed in cart order once every cart has finished. Exits
non-zero if any cart failed. One run a cart, no retries.
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


class Run:
    """One cart running in its own PICO-8 window, and the log it writes."""

    def __init__(self, cart):
        self.cart = cart
        name = os.path.splitext(os.path.basename(cart))[0]
        self.log = os.path.join(HERE, "tests", name.replace("test_", "log_", 1) + ".p8l")
        if os.path.exists(self.log):
            os.remove(self.log)
        self.process = subprocess.Popen([PICO8, "-run", cart], cwd=HERE,
                                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.started = self.last_growth = time.time()
        self.size = 0
        self.why = None

    def read_log(self):
        if not os.path.exists(self.log):
            return ""
        with open(self.log, encoding="utf-8", errors="replace") as handle:
            return handle.read()

    def poll(self):
        """Decide whether the cart has finished, and stop its PICO-8 if so.

        PICO-8 does not close a `-run` window when the cart asks it to, so
        the process started here is stopped here; no other PICO-8 is touched.
        """
        if self.why:
            return
        log = self.read_log()
        if len(log) != self.size:
            self.size, self.last_growth = len(log), time.time()
        if any(line.startswith("ok ") for line in log.splitlines()):
            self.why = "ok"
        elif "error" in log.lower():
            self.why = "the cart reported an error"
        elif self.process.poll() is not None:
            self.why = "pico-8 closed (exit code %#x)" % (self.process.returncode & 0xffffffff)
        elif time.time() - self.last_growth > STALL_SECONDS:
            # an error on pico-8's own screen, or a cart too large to run,
            # leaves the window open and the log silent
            self.why = ("nothing printed for %d seconds; look at the pico-8 window's message"
                        % STALL_SECONDS)
        elif time.time() - self.started > TIMEOUT_SECONDS:
            self.why = "still running after %d seconds" % TIMEOUT_SECONDS
        if self.why:
            self.seconds = time.time() - self.started
            if self.process.poll() is None:
                self.process.kill()
            self.process.wait()


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
    started = time.time()
    runs = [Run(cart) for cart in carts]
    while any(run.why is None for run in runs):
        time.sleep(0.25)
        for run in runs:
            run.poll()
    failed = 0
    for run in runs:
        print("--- %s (%.0f seconds)" % (run.cart, run.seconds))
        print(save_screens(run.read_log()).strip())
        if run.why != "ok":
            print("FAIL: %s: %s" % (run.cart, run.why))
            failed += 1
    print("%d of %d carts passed in %.0f seconds" % (len(runs) - failed, len(runs), time.time() - started))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
