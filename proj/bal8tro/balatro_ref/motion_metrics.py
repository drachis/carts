"""motion_metrics.py - the timings that make a card game's rhythm, from a motion log.

usage: py balatro_ref/motion_metrics.py <motion.log> [more logs...]

Reads the format harness.lua writes (and tests/test_motion.lua writes for
bal8tro):
    card <seconds> <id> <area> <x> <y> <scale> <rotation>
    hud <seconds> <chips> <mult> <score>
    event <seconds> <name>
x and y are in card widths and heights from the hand area's top left, so
logs from games of different sizes compare. Prints, for each log, in 60fps
frames: the deal (gap between cards setting off, each card's travel time),
the pick (rise in card heights, frames to settle), the discard and the
play (frames to leave or land), and the scoring (frames from the play to
each card's pulse and each change of chips or mult on the hud).
"""
import collections
import sys

FPS = 60


def read(path):
    cards = collections.defaultdict(list)
    hud, events = [], {}
    for line in open(path, encoding="utf-8", errors="replace"):
        parts = line.split()
        if not parts:
            continue
        if parts[0] == "card" and len(parts) == 8:
            cards[parts[2]].append((float(parts[1]), parts[3], float(parts[4]), float(parts[5]),
                                    float(parts[6]), float(parts[7])))
        elif parts[0] == "hud" and len(parts) == 5:
            hud.append((float(parts[1]), parts[2], parts[3], parts[4]))
        elif parts[0] == "event" and len(parts) == 3:
            events[parts[2]] = float(parts[1])
    return cards, hud, events


def frames(seconds):
    return round(seconds * FPS)


def settle_time(track, start, key, tolerance=0.03):
    """Seconds from start until the value stops moving (within tolerance of its last)."""
    after = [sample for sample in track if sample[0] >= start]
    if not after:
        return None
    final = key(after[-1])
    moving = [sample[0] for sample in after if abs(key(sample) - final) > tolerance]
    return (moving[-1] - start) if moving else 0.0


def report(path):
    cards, hud, events = read(path)
    print("==", path)
    deal = events.get("deal")
    if deal is not None:
        entries = []
        for ident, track in cards.items():
            in_hand = [s for s in track if s[1] == "hand" and s[0] >= deal]
            if in_hand and in_hand[0][0] < deal + 4:
                entries.append((in_hand[0][0], ident, in_hand))
        entries.sort()
        starts = [entry[0] for entry in entries[:8]]
        gaps = [frames(b - a) for a, b in zip(starts, starts[1:])]
        travels = [frames(settle_time(track, start, lambda s: s[2] + s[3], 0.1) or 0) for start, _, track in entries[:8]]
        print("deal: first card %d frames after the event; gaps %s; travel %s" % (
            frames(starts[0] - deal) if starts else -1, gaps, travels))
    for name in ("pick", "pick_discard"):
        at = events.get(name)
        if at is None:
            continue
        rises = []
        for ident, track in cards.items():
            before = [s for s in track if s[0] < at and s[1] == "hand"]
            after = [s for s in track if at <= s[0] < at + 0.9 and s[1] == "hand"]
            if before and after:
                rise = before[-1][3] - min(s[3] for s in after)
                if rise > 0.05:
                    rises.append((round(rise, 2), frames(settle_time(after, at, lambda s: s[3]) or 0)))
        print("%s: rise (card heights, frames to settle) %s" % (name, rises))
    for name, area in (("discard", "discard"), ("play", "play")):
        at = events.get(name)
        if at is None:
            continue
        lands = []
        for ident, track in cards.items():
            moved = [s for s in track if s[0] >= at and s[1] == area]
            if moved and moved[0][0] < at + 2:
                window = [s for s in track if at <= s[0] < moved[0][0] + 1.5]
                lands.append((frames(moved[0][0] - at), frames(settle_time(window, at, lambda s: s[2] + s[3]) or 0)))
        print("%s: (frames until in its area, frames until still) %s" % (name, sorted(lands)))
    play = events.get("play")
    if play is not None:
        pulses = []
        for ident, track in cards.items():
            last_big = None
            for sample in track:
                if play <= sample[0] < play + 8 and sample[4] > 1.04:
                    if last_big is None or sample[0] - last_big > 0.15:
                        pulses.append((frames(sample[0] - play), sample[1]))
                    last_big = sample[0]
        print("score: card pulses (frames after play, area) %s" % sorted(pulses))
        changes, previous = [], None
        for seconds, chips, mult, score in hud:
            if seconds >= play and (chips, mult) != previous:
                changes.append((frames(seconds - play), chips, mult))
                previous = (chips, mult)
        print("score: hud changes (frames after play, chips, mult) %s" % changes[:16])


if __name__ == "__main__":
    for log_path in sys.argv[1:]:
        report(log_path)
