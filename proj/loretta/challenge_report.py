"""challenge_report.py - does the level's challenge grow? read from bot runs.

usage: py challenge_report.py [tests/bot_playthrough.p8l]

tests/bot_playthrough.p8 plays the level with a dozen imperfect bots.
For each of the eight sections this prints how many runs reached it, and
per run that reached it: seconds spent, jumps made, hits from squirrels,
falls into water, and runs that ended there. A section's challenge is
hits + 2 x falls + 4 x deaths per run that reached it, plus jumps per
second (how busy it keeps you). Then it says whether the challenge grows:
the slope of challenge over sections, and the last three sections'
average against the first three's.

What it cannot know: how hard a jump looks to a person, or how a person
hesitates; the bots never sit, bark or turn back.
"""
import sys

NAMES = ["street", "lawns", "fern dell", "yard", "trailhead", "ravine", "switchback", "observatory"]


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "tests/bot_playthrough.p8l"
    sections = {s: {"runs": 0, "frames": 0, "jumps": 0, "hits": 0, "falls": 0, "ended": 0} for s in range(1, 9)}
    outcomes = []
    for line in open(path):
        parts = line.split()
        if parts and parts[0] == "sec":
            _, _, s, frames, jumps, hits, falls = parts
            stat = sections[int(s)]
            stat["runs"] += 1
            stat["frames"] += int(frames)
            stat["jumps"] += int(jumps)
            stat["hits"] += int(hits)
            stat["falls"] += int(falls)
        elif parts and parts[0] == "end":
            _, run, outcome, s, frames = parts
            outcomes.append((outcome, int(s), int(frames)))
            if outcome == "lost":
                sections[int(s)]["ended"] += 1
    print("%-12s %5s %6s %6s %6s %6s %6s %9s" % ("section", "runs", "secs", "jumps", "hits", "falls", "ended", "challenge"))
    challenge = []
    for s in range(1, 9):
        stat = sections[s]
        runs = max(stat["runs"], 1)
        seconds = stat["frames"] / 60 / runs
        score = (stat["hits"] + 2 * stat["falls"] + 4 * stat["ended"]) / runs + stat["jumps"] / max(stat["frames"] / 60, 1)
        challenge.append(score)
        print("%-12s %5d %6.1f %6.1f %6.2f %6.2f %6d %9.2f" % (NAMES[s - 1], stat["runs"], seconds,
              stat["jumps"] / runs, stat["hits"] / runs, stat["falls"] / runs, stat["ended"], score))
    won = sum(1 for o in outcomes if o[0] == "won")
    print("runs: %d, won %d, lost %d, stuck %d" % (len(outcomes), won,
          sum(1 for o in outcomes if o[0] == "lost"), sum(1 for o in outcomes if o[0] == "stuck")))
    n = len(challenge)
    mean_x, mean_y = (n + 1) / 2, sum(challenge) / n
    slope = sum((x + 1 - mean_x) * (y - mean_y) for x, y in enumerate(challenge)) / sum((x + 1 - mean_x) ** 2 for x in range(n))
    first, last = sum(challenge[:3]) / 3, sum(challenge[-3:]) / 3
    rises = sum(1 for a, b in zip(challenge, challenge[1:]) if b >= a)
    grows = slope > 0 and last > first
    print("slope %.3f a section; first three %.2f, last three %.2f; %d of 7 steps rise or hold"
          % (slope, first, last, rises))
    print("the challenge %s" % ("grows" if grows else "does not grow"))
    return 0 if grows else 1


if __name__ == "__main__":
    sys.exit(main())
