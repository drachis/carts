"""golden_compare.py - has a refactor changed anything? Compare a deterministic run, line by line.

usage:
    py golden_compare.py save    --run "<command>" --log <file> --base <file> [--match <regex>]
    py golden_compare.py compare --run "<command>" --log <file> --base <file> [--match <regex>]
    py golden_compare.py compare --log <file> --base <file>     (compare a log already written)

The run is a game or program made deterministic (fixed clock, fixed seed,
scripted input) that writes one line per frame or step: its state and a
checksum of what it shows. `--run` is run first if given (it must exit 0),
then the lines of `--log` matching `--match` (default: lines starting with
a digit, i.e. a frame number) are kept.

save     keeps those lines as the baseline (`--base`). Do this on the code
         before the refactor, and keep the baseline out of version control.
compare  prints the first frames that differ, before and after, and
         "same: N frames" when none do. Exits 1 on any difference, 2 if the
         run failed or produced no lines.
"""
import argparse
import re
import subprocess
import sys


def read_lines(path, pattern):
    with open(path, encoding="utf-8", errors="replace") as handle:
        return [line.rstrip("\n") for line in handle if pattern.match(line)]


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("action", choices=["save", "compare"])
    parser.add_argument("--run", help="command that writes the log (run in the current folder)")
    parser.add_argument("--log", required=True, help="the file the run writes")
    parser.add_argument("--base", required=True, help="the baseline file")
    parser.add_argument("--match", default=r"^\d", help="regex for the lines to keep")
    parser.add_argument("--show", type=int, default=5, help="differing frames to print")
    args = parser.parse_args(argv)
    if args.run:
        result = subprocess.run(args.run, shell=True)
        if result.returncode != 0:
            print("the run failed (exit %d)" % result.returncode)
            return 2
    lines = read_lines(args.log, re.compile(args.match))
    if not lines:
        print("no matching lines in %s" % args.log)
        return 2
    if args.action == "save":
        with open(args.base, "w", encoding="utf-8", newline="\n") as handle:
            handle.write("\n".join(lines) + "\n")
        print("saved %d frames to %s" % (len(lines), args.base))
        return 0
    before = read_lines(args.base, re.compile(r".*"))
    before = [line for line in before if line]
    differ = [(number, a, b) for number, (a, b) in enumerate(zip(before, lines), 1) if a != b]
    if len(before) != len(lines):
        print("%d frames before, %d now" % (len(before), len(lines)))
    for number, a, b in differ[:args.show]:
        print("line %d\n  before: %s\n  now:    %s" % (number, a, b))
    if not differ and len(before) == len(lines):
        print("same: %d frames" % len(lines))
        return 0
    print("%d frames differ" % len(differ))
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
