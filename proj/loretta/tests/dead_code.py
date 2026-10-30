"""dead_code.py - names in the game's Lua that appear only once: never read,
never called, or a value set and not used. usage: py tests/dead_code.py

Names built at run time ("update_"..name, "touch_"..name, "draw_"..name) are
not dead just for appearing once; they are listed apart. A hint, not a proof.
"""
import os
import re
from collections import Counter

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODULES = ["data.lua", "world.lua", "scenery.lua", "loretta.lua", "things.lua", "camera.lua", "main.lua"]
LUA = set("""and break do else elseif end false for function goto if in local nil not or repeat
return then true until while""".split())
API = set("""abs add all atan2 btn btnp camera ceil circ circfill clip cls cos del dget dset extcmd fget fillp flr
ipairs line map max mget mid min music pal palt pairs peek poke print printh pset pget rect rectfill rnd sfx sgn
sin split spr sspr sqrt srand sub t time tostr tonum unpack setmetatable cartdata count deli _ENV""".split())

text = "\n".join(open(os.path.join(HERE, m), encoding="utf-8").read() for m in MODULES)
without_shapes = re.sub(r'"[^"\n]*"', lambda m: " ".join(re.findall(r"[a-z_][a-z_0-9]*", m.group(0))) if "," in m.group(0) or " " in m.group(0) else m.group(0), text)
names = Counter(re.findall(r"[A-Za-z_][A-Za-z_0-9]*", without_shapes))
once = sorted(n for n, c in names.items() if c == 1 and n not in LUA and n not in API)
dynamic = [n for n in once if re.match(r"(update|touch|draw)_", n)]
print("appear once:", " ".join(n for n in once if n not in dynamic))
print("built at run time:", " ".join(dynamic))
