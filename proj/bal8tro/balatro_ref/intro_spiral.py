"""intro_spiral.py - how far round the centre a splash card turns on its way in.

usage: py balatro_ref/intro_spiral.py

Balatro's splash cards are drawn through its vortex shader, which twists each
card about the screen centre more the nearer it is, and more as time passes,
so a card falling straight in is seen to curve. This tracks cards through
reference/intro.log (nearest card a frame later; the log has the straight
paths, before the shader), applies vortex.fs's twist to each point, and
prints, for cards passing 6 card widths out in each second, the turn in
degrees between 6 card widths out and 1 card width out; then the same from
bal8tro's intro.lua formula.
"""
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(os.path.dirname(HERE), "reference", "intro.log")


def balatro_tracks():
    frames, start = {}, None
    for line in open(LOG):
        part = line.split()
        if not part:
            continue
        if part[0] == "splash" and start is None and float(part[5]) >= 0:
            start = float(part[1]) - float(part[5])
        if part[0] == "intro":
            x, y = float(part[2]), float(part[3]) * 1.4
            if math.hypot(x, y) > 0.05:
                frames.setdefault(part[1], []).append((x, y))
    tracks, open_tracks = [], []
    for stamp in sorted(frames, key=float):
        moved = []
        for x, y in frames[stamp]:
            best = min(open_tracks, key=lambda t: math.hypot(t[-1][1] - x, t[-1][2] - y), default=None)
            if best and math.hypot(best[-1][1] - x, best[-1][2] - y) < 0.6:
                open_tracks.remove(best)
                best.append((float(stamp) - start, x, y))
                moved.append(best)
            else:
                moved.append([(float(stamp) - start, x, y)])
        tracks += [t for t in open_tracks if len(t) > 20]
        open_tracks = moved
    return tracks


def shader_angle(t, x, y):
    """the angle Balatro's vortex.fs draws a point at: x, y in card widths
    from the centre at 960x540 (a card 98px wide), t its splash clock."""
    px, py = x * 98, y * 98
    diagonal = math.hypot(960, 540)
    length = math.hypot(px / diagonal * 960 / 540, py / diagonal)
    radius_limit, amount = 1.6 - 0.05 * t, 0.5 + 0.15 * t
    edge = min(max(1 - length / radius_limit, 0), 1)
    return math.degrees(math.atan2(py, px) + amount * edge * edge * (3 - 2 * edge))


def sweep(track):
    def angle_at(limit, outward):
        for t, x, y in (track if outward else reversed(track)):
            if (math.hypot(x, y) <= limit) == outward:
                return t, shader_angle(t, x, y)
        return None
    out, near = angle_at(6, True), angle_at(1, False)
    if not out or not near:
        return None
    turn = (near[1] - out[1] + 180) % 360 - 180
    return out[0], turn


def bal8tro_sweep(spawn_frame, life_frames, size):
    def angle(frame):
        left = (frame - spawn_frame) / life_frames
        distance = (1 - min(left / .9, 1)) * (18 + size) * 6.4
        edge = max(1 - distance / 150, 0)
        return (.08 + frame / 2513) * edge * edge * (3 - 2 * edge) * 360, distance / 15
    frames = range(spawn_frame, spawn_frame + int(life_frames))
    out = next(f for f in frames if angle(f)[1] <= 6)
    near = next(f for f in frames if angle(f)[1] <= 1)
    return angle(near)[0] - angle(out)[0]


def main():
    rows = {}
    for track in balatro_tracks():
        found = sweep(track)
        if found:
            rows.setdefault(int(found[0]), []).append(found[1])
    print("seconds  balatro turn (deg, median of cards)  bal8tro turn")
    t, i, spawns = 3.0, 0, []
    for i in range(1, 201):
        spawns.append((round(t * 60), max(2 - i * .005, .001) * 60))
        t += max(1 / i, max(0.2 * (170 - i) / 500, 0.016))
    for second in sorted(rows):
        turns = sorted(rows[second])
        ours = [bal8tro_sweep(f, life, 3) for f, life in spawns if int(f / 60) == second]
        print("%5d    %6.1f  (%d cards)                    %6.1f" % (
            second, turns[len(turns) // 2], len(turns), sum(ours) / len(ours) if ours else float("nan")))


if __name__ == "__main__":
    main()
