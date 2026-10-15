"""make_lite.py - per-cart copies of the game's drawing modules with unused functions emptied.

usage: py tests/make_lite.py      (gen_cart.py runs it before every test run)

The replay carts each include the whole game plus a shared scripted run, and
the game alone is past 7500 tokens, so a cart has little room left. Each
replay cart that never shows a screen gets copies of draw.lua and shop.lua
with that screen's functions emptied (`function f(...) end`, keeping the name
so calls still work), written to tests/lite/<cart>/ and included instead of
the real modules. test_boot is left out: it stays the one replay cart with
the whole, real game. A cart keeps every screen it dumps a picture of.
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)

# cart -> functions it never needs (it never reaches those screens, or
# reaches them without checking or dumping them)
EMPTY = {
    "deal": ["draw_info", "draw_pack_screen", "draw_shop", "draw_mini_tarot", "draw_mini_planet", "draw_pack"],
    "score": ["draw_info", "draw_pack_screen", "draw_shop", "draw_mini_tarot", "draw_mini_planet", "draw_pack"],
    "total": ["draw_info", "draw_pack_screen", "draw_shop", "draw_mini_tarot", "draw_mini_planet", "draw_pack"],
    "mid": ["draw_info", "draw_pack_screen", "draw_mini_tarot"],
    "table": ["draw_pack_screen", "draw_mini_tarot"],
    "late": ["draw_info"],
    "finale": ["draw_info", "draw_pack_screen", "draw_mini_tarot"],
}


def emptied(source, names):
    lines, out, skipping = source.split("\n"), [], None
    for line in lines:
        start = re.match(r"function (\w+)\((.*)\)$", line)
        if skipping:
            if line == "end":
                skipping = None
            continue
        if start and start.group(1) in names:
            out.append("function %s(%s) end" % (start.group(1), start.group(2)))
            skipping = start.group(1)
            continue
        out.append(line)
    return "\n".join(out)


def main():
    for cart, names in EMPTY.items():
        folder = os.path.join(HERE, "lite", cart)
        os.makedirs(folder, exist_ok=True)
        for module in ("draw.lua", "shop.lua"):
            with open(os.path.join(GAME, module), encoding="utf-8") as handle:
                text = emptied(handle.read(), names)
            path = os.path.join(folder, module)
            old = open(path, encoding="utf-8").read() if os.path.exists(path) else None
            if old != text:
                with open(path, "w", encoding="utf-8", newline="\n") as handle:
                    handle.write(text)


if __name__ == "__main__":
    main()
