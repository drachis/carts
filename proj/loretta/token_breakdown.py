"""token_breakdown.py - PICO-8's own token count for each top-level function
and statement of the cart's modules, largest first.

usage: py token_breakdown.py [module.lua ...]   (default: every module)

Each top-level chunk (a function to its closing `end`, or a statement) is
counted by count_tokens.pico8_count, so the numbers are PICO-8's, not an
estimate. Chunks are counted in parallel; one PICO-8 window a chunk.
"""
import os
import re
import sys
from concurrent.futures import ThreadPoolExecutor

import count_tokens

HERE = os.path.dirname(os.path.abspath(__file__))
MODULES = ["data.lua", "world.lua", "scenery.lua", "loretta.lua", "things.lua", "camera.lua", "main.lua"]


def chunks(path):
    """Top-level pieces: a line at column 0 starts one, `end` at column 0 closes a function."""
    out, current = [], []
    for line in open(path, encoding="utf-8").read().split("\n"):
        if not line.strip():
            continue
        text = "\n".join(current)
        inside_string = text.count("[[") > text.count("]]")
        if current and not inside_string and line[0] not in " \t" and not line.startswith("end"):
            out.append(current)
            current = []
        current.append(line)
    if current:
        out.append(current)
    return out


def name_of(lines):
    first = lines[0]
    found = re.match(r"function ([\w.:]+)", first)
    return found.group(1) if found else first[:40]


def main(argv):
    modules = argv or MODULES
    pieces = [(module, name_of(lines), "\n".join(lines))
              for module in modules for lines in chunks(os.path.join(HERE, module))]
    filler = count_tokens.FILLER
    base = count_tokens.pico8_count(filler)
    with ThreadPoolExecutor(8) as pool:
        counts = list(pool.map(lambda piece: count_tokens.pico8_count(piece[2] + "\n" + filler) - base, pieces))
    rows = sorted(zip(counts, pieces), key=lambda row: -(row[0] or 0))
    for count, (module, name, _) in rows:
        print("%5s  %-12s %s" % (count, module, name))
    print("%5d  total" % sum(count or 0 for count in counts))


if __name__ == "__main__":
    main(sys.argv[1:])
