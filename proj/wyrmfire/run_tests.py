"""run_tests.py - regenerate art, run the headless test carts, save a screenshot.

usage: py run_tests.py
Set PICO8 to the pico8 executable if it is not in the default location.
Exits non-zero if a cart fails to run, reports a runtime error, or never
prints its "ok" line.

There are two carts because the game plus its tests no longer fit in one
cart's 8192 tokens: test_data checks the data tables without the world or
main loop, test_run soaks the whole game.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
TEST_CARTS = [os.path.join("tests", "test_data.p8"), os.path.join("tests", "test_run.p8")]
FRAME_DUMP = os.path.join("tests", "shot_fb.p8")
SCREENSHOT = "shot.png"
TIMEOUT_SECONDS = 180


def run(args, **kwargs):
    return subprocess.run(args, cwd=HERE, text=True, capture_output=True, **kwargs)


def run_cart(cart):
    try:
        result = run([PICO8, "-x", cart], timeout=TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired as hung:
        # an over-budget or syntactically broken cart idles instead of exiting
        print("FAIL: %s did not exit\n" % cart, hung.stdout or "", hung.stderr or "")
        return False
    log = result.stdout + result.stderr
    print(log.strip())
    if "INFO: ok " not in log or "error" in log.lower():
        print("FAIL: %s did not complete cleanly (pico8 exit code %s)" % (cart, result.returncode))
        return False
    return True


def main():
    gen = run([sys.executable, "gen_gfx.py"])
    print(gen.stdout.strip())
    if gen.returncode != 0:
        print(gen.stderr)
        return 1

    for cart in TEST_CARTS:
        if not run_cart(cart):
            return 1

    shot = run([sys.executable, "fb_to_png.py", FRAME_DUMP, SCREENSHOT, "4"])
    print(shot.stdout.strip() or shot.stderr.strip())
    return shot.returncode


if __name__ == "__main__":
    sys.exit(main())
