"""compare_motion.py - Balatro's and bal8tro's card motions over the same moments, as data.

usage: py balatro_ref/compare_motion.py [balatro log] [bal8tro log]

Defaults to reference/motion.log (from run_balatro_ref.py) and
reference/bal8tro_motion.log (copied from tests/motion.p8l after
`py run_tests.py tests/motion.p8`). For each moment (deal, pick, discard,
play) it takes a window of frames from the event, resamples each log to
60fps and writes reference/motion_<moment>.csv: one row per frame, and for
each game each moving card's x and y (card widths and heights from the
hand's top left; blank when off the table). Data, not a picture: the user
found tables read better than plots for many cards at once. Same dance,
fewer dancers: the columns should rise and fall at the same frames.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(HERE)
OUT = os.path.join(PROJECT, "reference")
WINDOWS = {"deal": 240, "pick": 60, "discard": 60, "play": 420}


def read(path):
    cards, events = {}, {}
    for line in open(path, encoding="utf-8", errors="replace"):
        parts = line.split()
        if parts and parts[0] == "card" and len(parts) == 8:
            cards.setdefault(parts[2], []).append((float(parts[1]), float(parts[4]), float(parts[5])))
        elif parts and parts[0] == "event" and len(parts) == 3:
            events[parts[2]] = float(parts[1])
    return cards, events


def window_log(cards, start, frames, path):
    """Write `m frame x1 y1 x2 y2 ...` lines; returns how many cards."""
    chosen = []
    for ident, track in cards.items():
        inside = [s for s in track if start <= s[0] < start + frames / 60]
        if len(inside) > 2:
            xs, ys = [s[1] for s in inside], [s[2] for s in inside]
            if max(xs) - min(xs) > 0.05 or max(ys) - min(ys) > 0.05:
                chosen.append((inside[0][0], track))
    chosen.sort()
    chosen = [track for _, track in chosen[:8]]
    with open(path, "w") as handle:
        for frame in range(frames):
            at = start + frame / 60
            row = []
            for track in chosen:
                near = min(track, key=lambda s: abs(s[0] - at))
                row += [near[1], near[2]] if abs(near[0] - at) < 0.1 else [-1, -1]
            handle.write("m %d %s\n" % (frame, " ".join("%.3f" % value for value in row)))
    return len(chosen)


def main():
    logs = {"balatro": sys.argv[1] if len(sys.argv) > 1 else os.path.join(OUT, "motion.log"),
            "bal8tro": sys.argv[2] if len(sys.argv) > 2 else os.path.join(OUT, "bal8tro_motion.log")}
    read_logs = {game: read(path) for game, path in logs.items()}
    for moment, frames in WINDOWS.items():
        columns, header = [], ["frame"]
        for game, (cards, events) in read_logs.items():
            if moment not in events:
                continue
            table = os.path.join(OUT, "motion_%s_%s.txt" % (moment, game))
            count = window_log(cards, events[moment], frames, table)
            rows = [line.split()[2:] for line in open(table)]
            os.remove(table)
            columns.append(rows)
            header += ["%s_c%d_%s" % (game, card + 1, axis) for card in range(count) for axis in "xy"]
        out = os.path.join(OUT, "motion_%s.csv" % moment)
        with open(out, "w") as handle:
            handle.write(",".join(header) + "\n")
            for frame in range(frames):
                cells = [str(frame)]
                for rows in columns:
                    cells += ["" if value == "-1.000" else value for value in rows[frame]]
                handle.write(",".join(cells) + "\n")
        print(out)


if __name__ == "__main__":
    main()
