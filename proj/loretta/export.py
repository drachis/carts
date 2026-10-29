"""export.py - build the cart for release: the web page, a zip of it, and a .p8.png.

usage: py export.py [name]

Run it in the project folder after a passing test run. Writes:
  * build/<GAME>: the cart with every #include inlined and the modules
    stripped of comments, blank lines and indents (run_tests.stripped),
    keeping the cart's own first two comment lines, which PICO-8 prints on
    the cartridge as its name and author; the label is a screen a test
    dumped (LABEL_LOG, LABEL_SCREEN), so it is never stale;
  * <name>.html and <name>.js (index by default, which itch.io wants);
  * release/<stem>_web.zip of those two, to upload to itch.io;
  * release/<stem>.p8.png, the cartridge for the Lexaloffle BBS.

PICO-8 refuses a cart whose compressed code is too large ("code block too
large"); stripping is what keeps a commented project under it. PICO-8 also
writes the export name it is given into the page as the script's src, so
the name passed is relative: an absolute path loads nothing once uploaded.
Check the page served over HTTP (py -m http.server), not opened from disk.
Set PICO8 to the pico8 executable if it is not in the default location.
"""
import os
import re
import subprocess
import sys
import zipfile

from run_tests import PICO8, stripped

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = "loretta.p8"
LABEL_LOG = os.path.join("tests", "log_boot.p8l")
LABEL_SCREEN = "boot_start"
INCLUDE = re.compile(r"^#include (\S+)$")


def label():
    """The cart's label: a screen a test dumped. PICO-8 will not export without one."""
    with open(os.path.join(HERE, LABEL_LOG), encoding="utf-8") as log:
        rows = [line.split()[1] for line in log if line.startswith(LABEL_SCREEN + " ")]
    assert len(rows) == 128, "no %s screen in %s: run py run_tests.py first" % (LABEL_SCREEN, LABEL_LOG)
    return ["__label__"] + rows


def build():
    """Write build/<GAME> and return its path."""
    with open(os.path.join(HERE, GAME), encoding="utf-8") as handle:
        cart = handle.read().split("\n")
    lines, in_lua, name_lines = [], False, 0
    for line in cart:
        include = INCLUDE.match(line.strip())
        if line == "__lua__":
            in_lua = True
            lines.append(line)
        elif include:
            lines.append(stripped(os.path.join(HERE, include.group(1))).rstrip("\n"))
        elif line == "__gff__":
            lines += label() + [line]
        elif line.startswith("__"):
            in_lua = False
            lines.append(line)
        elif in_lua and line.strip().startswith("--"):
            if name_lines < 2:
                lines.append(line)
                name_lines += 1
        else:
            lines.append(line)
    os.makedirs(os.path.join(HERE, "build"), exist_ok=True)
    path = os.path.join(HERE, "build", GAME)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines))
    return path


def export(cart, target):
    """Have PICO-8 export the cart to `target`, relative to the project; True if it was written."""
    path = os.path.join(HERE, target)
    before = os.path.getmtime(path) if os.path.exists(path) else 0
    result = subprocess.run([PICO8, cart, "-export", target], cwd=HERE,
                            capture_output=True, text=True, timeout=60)
    if result.stdout.strip():
        print(result.stdout.strip())
    return os.path.exists(path) and os.path.getmtime(path) > before


def main(argv):
    name = argv[0] if argv else "index"
    stem = GAME[:-len(".p8")]
    cart = build()
    print("wrote " + os.path.relpath(cart, HERE))
    if not export(cart, name + ".html"):
        print("FAIL: pico-8 did not write %s.html" % name)
        return 1
    with open(os.path.join(HERE, name + ".html"), encoding="utf-8") as page:
        assert '"%s.js"' % name in page.read(), "the page does not load %s.js by a relative name" % name
    os.makedirs(os.path.join(HERE, "release"), exist_ok=True)
    with zipfile.ZipFile(os.path.join(HERE, "release", stem + "_web.zip"), "w", zipfile.ZIP_DEFLATED) as zipped:
        for part in (name + ".html", name + ".js"):
            zipped.write(os.path.join(HERE, part), part)
    if not export(cart, os.path.join("release", stem + ".p8.png")):
        print("FAIL: pico-8 did not write release/%s.p8.png" % stem)
        return 1
    print("exported %s.html, %s.js, release/%s_web.zip and release/%s.p8.png" % (name, name, stem, stem))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
