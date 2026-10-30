"""motion_report.py - sums up test_motion's per-frame log by phase.

usage: py motion_report.py [tests/log_motion.p8l]

For each stretch of the scripted run (standing, trotting, stopping,
landing) prints the mean pixel churn and flicker (pixels back to what
they were two frames before) of her own drawing and through the game's
camera, and how often each animated value changes, as counts of
"flips" (a whole-pixel value changing) and "reversals" (a value turning
back), which is how jitter shows in numbers.
"""
import sys

PHASES = [("standing", 1, 90), ("trotting", 91, 210), ("stopping", 211, 270), ("landing", 271, 330)]
FIELDS = ["frame", "x", "vx", "gait", "bob", "rump", "head_bob", "sag", "ear_x", "ear_y",
          "tongue_x", "tongue_y", "own_churn", "own_flicker", "flicker_top", "flicker_middle",
          "flicker_bottom", "game_churn", "game_flicker"]


def rows(path):
    for line in open(path):
        parts = line.split()
        if parts and parts[0] == "m":
            yield dict(zip(FIELDS, (float(p) for p in parts[1:])))


def flips(values):
    whole = [round(v) for v in values]
    return sum(1 for a, b in zip(whole, whole[1:]) if a != b)


def reversals(values):
    steps = [b - a for a, b in zip(values, values[1:]) if abs(b - a) > 0.01]
    return sum(1 for a, b in zip(steps, steps[1:]) if a * b < 0)


def main():
    data = list(rows(sys.argv[1] if len(sys.argv) > 1 else "tests/log_motion.p8l"))
    for name, first, last in PHASES:
        part = [r for r in data if first <= r["frame"] <= last][1:]
        n = len(part)
        mean = lambda key: sum(r[key] for r in part) / n
        print("%-9s frames %3d  own churn %5.1f flicker %5.1f (ears %4.1f body %4.1f legs %4.1f)  game churn %5.1f flicker %5.1f"
              % (name, n, mean("own_churn"), mean("own_flicker"), mean("flicker_top"), mean("flicker_middle"),
                 mean("flicker_bottom"), mean("game_churn"), mean("game_flicker")))
        for key in ("bob", "rump", "head_bob", "sag", "ear_x", "ear_y", "tongue_x", "tongue_y"):
            values = [r[key] for r in part]
            print("    %-9s flips %3d  reversals %3d  range %6.2f..%6.2f"
                  % (key, flips(values), reversals(values), min(values), max(values)))


if __name__ == "__main__":
    main()
