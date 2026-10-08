"""run_tests.py - regenerate art, run the headless soak test, save a screenshot.

usage: py run_tests.py
Set PICO8 to the pico8 executable if it is not in the default location.
Exits non-zero if the cart fails to run or reports a runtime error.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
TEST_CART = os.path.join("tests", "test_run.p8")
FRAME_DUMP = os.path.join("tests", "shot_fb.p8")
SCREENSHOT = "shot.png"
TIMEOUT_SECONDS = 120


def run(args, **kwargs):
    return subprocess.run(args, cwd=HERE, text=True, capture_output=True, **kwargs)


def main():
    gen = run([sys.executable, "gen_gfx.py"])
    print(gen.stdout.strip())
    if gen.returncode != 0:
        print(gen.stderr)
        return 1

    try:
        result = run([PICO8, "-x", TEST_CART], timeout=TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired as hung:
        # an over-budget or syntactically broken cart idles instead of exiting
        print("FAIL: pico8 did not exit\n", hung.stdout or "", hung.stderr or "")
        return 1
    log = result.stdout + result.stderr
    print(log.strip())
    if "INFO: ok " not in log or "error" in log.lower():
        print("FAIL: soak test did not complete cleanly")
        return 1

    shot = run([sys.executable, "fb_to_png.py", FRAME_DUMP, SCREENSHOT, "4"])
    print(shot.stdout.strip() or shot.stderr.strip())
    return shot.returncode


if __name__ == "__main__":
    sys.exit(main())
