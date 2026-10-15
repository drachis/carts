"""function_tokens.py - token counts per top-level function, as counted by PICO-8.

usage: py function_tokens.py [game.p8] [top]

Splits every #included module at lines that start a top-level function and
measures each piece with count_tokens.pico8_count (the padding probe), so the
numbers are PICO-8's own. Prints the largest first. Each piece is one PICO-8
run, so this takes a while.
"""
import re
import sys

from count_tokens import FILLER, modules_of, pico8_count


def pieces(name, code):
    current, label = [], name + " (top)"
    for line in code.splitlines():
        match = re.match(r"function\s+([\w.:]+)", line)
        if match:
            if any(part.strip() for part in current):
                yield label, "\n".join(current)
            current, label = [], name + " " + match.group(1)
        current.append(line)
    if any(part.strip() for part in current):
        yield label, "\n".join(current)


def main(argv):
    cart = argv[1] if len(argv) > 1 else "bal8tro.p8"
    top = int(argv[2]) if len(argv) > 2 else 40
    filler = pico8_count(FILLER)
    counts = []
    for name, code in modules_of(cart):
        for label, piece in pieces(name, code):
            counts.append((pico8_count(piece + "\n" + FILLER) - filler, label))
    counts.sort(reverse=True)
    print("total %d" % sum(count for count, _ in counts))
    for count, label in counts[:top]:
        print("%5d  %s" % (count, label))


if __name__ == "__main__":
    main(sys.argv)
