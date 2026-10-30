"""dead_py.py - top-level names in gen_cart.py and level_gen.py nothing reads,
and shapes and thing kinds in data.lua no level uses. usage: py tests/dead_py.py"""
import ast
import os
import re
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, HERE)
for name in ("gen_cart.py", "level_gen.py"):
    source = open(os.path.join(HERE, name), encoding="utf-8").read()
    tree = ast.parse(source)
    defined = set()
    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.ClassDef)):
            defined.add(node.name)
        elif isinstance(node, ast.Assign):
            defined |= {t.id for t in node.targets if isinstance(t, ast.Name)}
    print(name, "unread:", " ".join(sorted(n for n in defined if len(re.findall(r"\b%s\b" % n, source)) == 1)))

import gen_cart

data = open(os.path.join(HERE, "data.lua"), encoding="utf-8").read()
used = {cell for chunk in gen_cart.CHUNKS for row in chunk for cell in row}
tiles = {gen_cart.LETTER_TILES[c] for c in used if c in gen_cart.LETTER_TILES}
print("chunks never used in a level:", sorted(set(range(16)) - {c for l in gen_cart.LEVELS for c in l}))
specs = re.findall(r"^([a-z_0-9]+),(\d+),", data, flags=re.M)
print("thing kinds with no marker in any chunk:", " ".join(n for n, t in specs if int(t) not in tiles))
shapes = re.findall(r"^([a-z_0-9]+)=[rblctp] ", data, flags=re.M)
lua = "\n".join(open(os.path.join(HERE, m), encoding="utf-8").read() for m in ("things.lua", "main.lua"))
print("shapes:", " ".join(shapes))
