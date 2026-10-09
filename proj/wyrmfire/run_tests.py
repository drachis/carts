"""run_tests.py - regenerate art, run the headless test carts, save screenshots.

usage: py run_tests.py
Set PICO8 to the pico8 executable if it is not in the default location.
Exits non-zero if a cart fails to run, reports a runtime error, or never
prints its "ok" line.

There are three carts because the game plus its tests no longer fit in one
cart's 8192 tokens: test_data checks the data tables without the world,
test_title draws the menus with the whole game, and test_run soaks the game
with those menus stubbed out to make room for its harness.

Carts print screens as text (tests/dump.lua); each becomes <name>.png here.
"""
import os
import re
import struct
import subprocess
import sys
import threading
import zlib

import count_tokens

HERE = os.path.dirname(os.path.abspath(__file__))
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
TEST_CARTS = [os.path.join("tests", name) for name in
              ("test_data.p8", "test_title.p8", "test_run.p8")]
WINDOWED = {os.path.join("tests", "test_run.p8")}
MODULES = ["data.lua", "core.lua", "world.lua", "units.lua", "dragon.lua", "main.lua"]
# the game leaves no room in a cart for a test harness, in tokens or in
# characters. so the soak and title carts include tests/gen_<module>, copies
# with the comments stripped, and each swaps one of those for a copy with
# functions that cart never needs emptied as well:
# generated file -> (source module, functions to stub)
GENERATED = {
    # the soak has no menus, no sound (so no music to pace) and can spare
    # the inferno's edge flames
    "soak_main.lua": ("main.lua", ["draw_title", "draw_game_over", "update_music", "draw_blaze"]),
    "title_dragon.lua": ("dragon.lua", ["breathe_fire", "charge_impacts", "inferno"]),
}
TIMEOUT_SECONDS = 180
SCREEN_ROW = re.compile(r"^INFO: (\w+) ([0-9a-f]{128})$")
PNG_SCALE = 4
PALETTE = [(0, 0, 0), (29, 43, 83), (126, 37, 83), (0, 135, 81), (171, 82, 54),
           (95, 87, 79), (194, 195, 199), (255, 241, 232), (255, 0, 77),
           (255, 163, 0), (255, 236, 39), (0, 228, 54), (41, 173, 255),
           (131, 118, 156), (255, 119, 168), (255, 204, 170)]


def run(args, **kwargs):
    return subprocess.run(args, cwd=HERE, text=True, capture_output=True, **kwargs)


def write_png(path, rows):
    """Write rows of hex digits (one PICO-8 colour per digit) as a scaled PNG."""
    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    raw = bytearray()
    for row in rows:
        line = b"".join(bytes(PALETTE[int(digit, 16)]) * PNG_SCALE for digit in row)
        raw += (b"\x00" + line) * PNG_SCALE
    width, height = len(rows[0]) * PNG_SCALE, len(rows) * PNG_SCALE
    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)))
        handle.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        handle.write(chunk(b"IEND", b""))


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
    # the soak runs in a window: headless (-x) pico-8 crashes on it about
    # half the time (see DESIGN.md) and windowed pico-8 has not been seen to
    mode = "-run" if cart in WINDOWED else "-x"
    process = subprocess.Popen([PICO8, mode, cart], cwd=HERE, text=True,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # a cart that is over budget or has a syntax error idles instead of
    # exiting, and a windowed pico-8 does not close when a cart shuts down:
    # so stop it at the time limit, or shortly after it says it is done
    watchdog = threading.Timer(TIMEOUT_SECONDS, process.kill)
    watchdog.start()
    lines, finished = [], False
    for line in process.stdout:
        lines.append(line)
        if line.startswith("INFO: ok ") and not finished:
            finished = True
            threading.Timer(3, process.kill).start()
    watchdog.cancel()
    process.wait()
    log = "".join(lines)
    print(save_screens(log).strip())
    if not finished or "error" in log.lower():
        print("FAIL: %s did not complete cleanly (pico8 exit code %#x)"
              % (cart, process.returncode & 0xffffffff))
        return False
    return True


def stub_module(target, module, stubs, strip=True):
    """Write tests/<target>: a copy of a module with some functions emptied.

    With `strip` its comments and indentation go too: a cart may hold only
    65535 characters of source, and the game's own are most of that.
    """
    source = open(os.path.join(HERE, module), encoding="utf-8").read()
    for name in stubs:
        # a top-level function runs to the first `end` at the start of a line
        pattern = r"\nfunction %s\([^)]*\).*?\nend\n" % name
        source, count = re.subn(pattern, "\nfunction %s() end\n" % name, source, flags=re.S)
        if count != 1:
            raise RuntimeError("could not find %s in %s" % (name, module))
    if strip:
        source = count_tokens.strip_comment_lines(source)
    with open(os.path.join(HERE, "tests", target), "w",
              encoding="utf-8", newline="\n") as handle:
        handle.write("-- generated from %s; do not edit\n" % module + source + "\n")


def build_generated():
    for module in MODULES:
        stub_module("gen_" + module, module, [])
    for target, (module, stubs) in GENERATED.items():
        stub_module(target, module, stubs)


def main():
    build_generated()
    gen = run([sys.executable, "gen_gfx.py"])
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
