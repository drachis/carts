"""transition_metrics.py - when panels and cards come and go between screens.

usage: py balatro_ref/transition_metrics.py <motion.log> [more logs...]

Reads the ui and card lines harness.lua writes (and tests/motion.lua writes
for bal8tro). For each panel (cash_out, shop, sign, blind_select) prints
the frames (60fps) at which it first appears, starts moving, stops, and
leaves, relative to the play, cash_out, pack_open and shop_exit events,
with its y at each of those moments in card heights from the hand's top
left; and for the shop's and pack's cards, when they arrive and settle.
Data, not pictures: compare the numbers between games.
"""
import collections
import sys


def read(path):
    ui, cards, events = collections.defaultdict(list), collections.defaultdict(list), {}
    for line in open(path, encoding="utf-8", errors="replace"):
        p = line.split()
        if not p:
            continue
        if p[0] == "ui" and len(p) == 5:
            ui[p[2]].append((float(p[1]), float(p[3]), float(p[4])))
        elif p[0] == "card" and len(p) == 8 and p[3] in ("shop_jokers", "shop_booster", "pack"):
            cards[p[3]].append((float(p[1]), p[2], float(p[4]), float(p[5])))
        elif p[0] == "event" and len(p) == 3:
            events[p[2]] = float(p[1])
    return ui, cards, events


def anchor(events, seconds):
    """The latest event at or before seconds, and the frames since it."""
    best = None
    for name, at in events.items():
        if at <= seconds + 1e-6 and (best is None or at > best[1]):
            best = (name, at)
    return "%s+%d" % (best[0], round((seconds - best[1]) * 60)) if best else "start+%d" % round(seconds * 60)


def report(path):
    ui, cards, events = read(path)
    print("==", path)
    for name, track in sorted(ui.items()):
        moves, previous, moving = [], None, False
        for seconds, x, y in track:
            if previous is not None:
                now_moving = abs(y - previous[2]) > 0.01 or abs(x - previous[1]) > 0.01
                if now_moving != moving:
                    moves.append(("moves" if now_moving else "stops", seconds, y))
                    moving = now_moving
            previous = (seconds, x, y)
        gaps = [(b[0], a[0]) for a, b in zip(track, track[1:]) if b[0] - a[0] > 0.2]
        print(" %s appears %s at y %.2f" % (name, anchor(events, track[0][0]), track[0][2]))
        for kind, seconds, y in moves[:10]:
            print("   %s %s (y %.2f)" % (kind, anchor(events, seconds), y))
        for back, gone in gaps[:4]:
            print("   gone %s, back %s" % (anchor(events, gone), anchor(events, back)))
        print("   last seen %s at y %.2f" % (anchor(events, track[-1][0]), track[-1][2]))
    for area, samples in sorted(cards.items()):
        firsts = collections.OrderedDict()
        for seconds, ident, x, y in samples:
            firsts.setdefault(ident, (seconds, x, y))
        print(" %s cards first seen: %s" % (area, ", ".join(
            "%s (%.2f,%.2f)" % (anchor(events, s), x, y) for s, x, y in list(firsts.values())[:6])))


if __name__ == "__main__":
    for log_path in sys.argv[1:]:
        report(log_path)
