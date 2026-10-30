"""check_levels.py - every level's chunks meet at the same ground height.

usage: py check_levels.py

Reads gen_cart.py's CHUNKS and LEVELS. For each pair of neighbouring
chunks in a level, the ground's top row at the first chunk's last column
must equal the second's at its first column (a pit or water at an edge is
reported too). Also checks each chunk is 16 rows of 32, and that data.lua's
levels are the same lists as LEVELS. Exits non-zero on any mismatch.
"""
import os
import re
import sys

import gen_cart

GROUND = "#_/\\"


def top(chunk, column):
    for y, row in enumerate(chunk):
        if row[column] in GROUND:
            return y
    return None


def main():
    problems = []
    for number, chunk in enumerate(gen_cart.CHUNKS):
        if len(chunk) != 16 or any(len(row) != 32 for row in chunk):
            problems.append("chunk %d is not 16 rows of 32" % number)
        # a chased squirrel escapes up a tree: any chunk with squirrels needs one
        if any("s" in row for row in chunk) and not any("T" in row for row in chunk):
            problems.append("chunk %d has squirrels but no tree to escape to" % number)
    for level, chunks in enumerate(gen_cart.LEVELS, 1):
        for a, b in zip(chunks, chunks[1:]):
            end, start = top(gen_cart.CHUNKS[a], 31), top(gen_cart.CHUNKS[b], 0)
            if end != start:
                problems.append("level %d: chunk %d ends at row %s, chunk %d starts at row %s" % (level, a, end, b, start))
    data = open(os.path.join(gen_cart.HERE, "data.lua"), encoding="utf-8").read()
    lists = re.findall(r'split"([0-9,]+)"', data.split("levels={", 1)[1].split("}", 1)[0])
    if [[int(n) for n in found.split(",")] for found in lists] != gen_cart.LEVELS:
        problems.append("data.lua's levels are not gen_cart.py's LEVELS")
    for problem in problems:
        print(problem)
    print("%d problems in %d levels" % (len(problems), len(gen_cart.LEVELS)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
