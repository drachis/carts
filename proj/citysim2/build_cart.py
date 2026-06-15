# build_cart.py - inline every #include into a single self-contained cart.
# the dev cart (citysim2.p8) uses #include, which PICO-8 resolves relative to
# its working dir -> "could not #include file" if run from elsewhere. the dist
# cart has all modules pasted into __lua__, so it runs anywhere (splore, BBS,
# itch export). run: py build_cart.py   ->  citysim2_dist.p8
import re, os, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
SRC  = os.path.join(HERE, "citysim2.p8")
DST  = os.path.join(HERE, "citysim2_dist.p8")

# stamp version.lua with the short git hash of HEAD, so the running cart (dev or
# dist) shows which build it is (minimap detail line).
try:
    h = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=HERE).decode().strip()
except Exception:
    h = "dev"
open(os.path.join(HERE, "version.lua"), "w", encoding="utf-8", newline="\n").write(
    '-- version.lua : build id (short git hash), stamped by build_cart.py.\nver="%s"\n' % h)

src = open(SRC, encoding="utf-8").read()
# split: everything up to the lua body, the lua body, then __gfx__ onward.
head, body = src.split("__lua__\n", 1)
m = re.search(r"\n__(gfx|gff|sfx|map|sfx|music|label)__\n", body)
lua, tail = (body[:m.start()], body[m.start():]) if m else (body, "")

out = []
for line in lua.split("\n"):
    inc = re.match(r"\s*#include\s+(\S+)", line)
    if inc:
        path = os.path.join(HERE, inc.group(1))
        with open(path, encoding="utf-8") as f:
            out.append("-- >>> " + inc.group(1))
            out.append(f.read().rstrip("\n"))
    else:
        out.append(line)

dist = head + "__lua__\n" + "\n".join(out).rstrip("\n") + "\n" + tail
open(DST, "w", encoding="utf-8", newline="\n").write(dist)
print("built", DST)
