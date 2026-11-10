"""count_tokens.py - token counts for a cart, as counted by PICO-8 itself.

usage:
    py count_tokens.py game.p8      # total, and per #include
    py count_tokens.py other.p8

PICO-8 only reports a token count when a cart is over the limit, so each
measurement pads a temporary cart with filler until it is too large, reads the
count PICO-8 prints, and subtracts PICO-8's own count of the filler alone.
No tokenising is done here. Set PICO8 if the executable is elsewhere.
"""
import os
import re
import subprocess
import sys
import tempfile
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
LIMIT = 8192
CHAR_LIMIT = 65535
HEADER = "pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n"
FILLER = "_=0\n" * 3000  # comfortably over the limit on its own
TOO_LARGE = re.compile(r"(\d+)\s*/\s*%d" % LIMIT)
PROBE_SECONDS = 30


def strip_comment_lines(lua):
    """Drop whole-line comments and indentation, which cost no tokens.

    PICO-8 also limits a cart to 65535 characters of source; the probe carries
    filler on top of the game, so it sheds what it safely can. Lines inside
    [[ ]] data strings are left alone.
    """
    kept, in_string = [], False
    for line in lua.splitlines():
        if not in_string:
            line = line.strip()
            if line.startswith("--"):
                continue
        if "[[" in line:
            in_string = True
        if "]]" in line:
            in_string = False
        kept.append(line)
    return "\n".join(kept)


def pico8_count(lua):
    """Token count PICO-8 reports for `lua`, which must be over the limit."""
    lua = strip_comment_lines(lua)
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as folder:
        cart = os.path.join(folder, "probe.p8")
        with open(cart, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(HEADER + lua)
        process = subprocess.Popen(
            [PICO8, "-x", cart], cwd=folder, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        # an over-limit cart never exits, so stop as soon as the count appears
        watchdog = threading.Timer(PROBE_SECONDS, process.kill)
        watchdog.start()
        seen = []
        try:
            for line in process.stdout:
                seen.append(line)
                match = TOO_LARGE.search(line)
                if match:
                    return int(match.group(1))
        finally:
            watchdog.cancel()
            process.kill()
            process.wait()  # release the folder before it is cleaned up
    raise RuntimeError("PICO-8 printed no token count:\n" + "".join(seen))


def modules_of(cart):
    """Ordered (label, code) for each #include plus the cart's own lines."""
    source = open(cart, encoding="utf-8").read()
    lua = source.split("__lua__\n", 1)[1]
    lua = re.split(r"\n__(?:gfx|gff|map|sfx|music|label)__\n", lua)[0]
    modules, own = [], []
    for line in lua.splitlines():
        include = re.match(r"\s*#include\s+(\S+)", line)
        if include:
            path = os.path.join(os.path.dirname(cart), include.group(1))
            modules.append((include.group(1), open(path, encoding="utf-8").read()))
        else:
            own.append(line)
    modules.append(("(cart)", "\n".join(own)))
    return modules


def main(argv):
    if not argv:
        print("usage: py count_tokens.py <cart.p8>")
        return 2
    cart = os.path.abspath(argv[0])
    modules = modules_of(cart)
    filler = pico8_count(FILLER)
    whole = "\n".join(code for _, code in modules)
    total = pico8_count(whole + "\n" + FILLER) - filler
    print("%s  %d / %d  (%.0f%%, %d free)" % (
        os.path.basename(cart), total, LIMIT, total * 100.0 / LIMIT, LIMIT - total))
    print("  %d / %d characters of source" % (len(whole), CHAR_LIMIT))
    if len(modules) > 2:
        for label, code in modules:
            print("  %-14s %5d" % (label, pico8_count(code + "\n" + FILLER) - filler))
    return 0 if total <= LIMIT else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
