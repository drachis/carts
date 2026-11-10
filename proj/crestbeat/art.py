"""art.py - crestbeat's figures, drawn from shapes at the size they are shown.

gen_cart.py stamps them into the sprite sheet. Nothing here is scaled in the
game: the user asked for many sprites rather than scaled ones, so the swarm
is drawn once for each size it appears at, and the giant is a set of parts
(after witchcap's hut) each drawn at its own pixel size.

A figure is a list of (shape, colour) painted in order, in unit coordinates
(0..1 across and down), mirrored about the middle when `mirror` is set.
render() paints it four times over and keeps, for each pixel, the colour that
covers most of it, so small sizes keep their thin parts.
"""
import math

SUPER = 4


def ellipse(cx, cy, rx, ry):
    return lambda u, v: ((u - cx) / rx) ** 2 + ((v - cy) / ry) ** 2 <= 1


def capsule(x0, y0, x1, y1, r):
    def inside(u, v):
        dx, dy = x1 - x0, y1 - y0
        f = max(0, min(1, ((u - x0) * dx + (v - y0) * dy) / (dx * dx + dy * dy or 1)))
        return math.hypot(u - x0 - dx * f, v - y0 - dy * f) <= r
    return inside


def triangle(a, b, c):
    def side(p, q, u, v):
        return (q[0] - p[0]) * (v - p[1]) - (q[1] - p[1]) * (u - p[0])

    def inside(u, v):
        s1, s2, s3 = side(a, b, u, v), side(b, c, u, v), side(c, a, u, v)
        return (s1 >= 0 and s2 >= 0 and s3 >= 0) or (s1 <= 0 and s2 <= 0 and s3 <= 0)
    return inside


def band(y0, y1, inside_of):
    return lambda u, v: y0 <= v <= y1 and inside_of(u, v)


def render(figure, width, height, mirror=True, keep="78ab"):
    """The figure as rows of colour digits, "0" transparent. A colour in
    `keep` (eyes, claw tips) wins any pixel it covers a quarter of."""
    big_w, big_h = width * SUPER, height * SUPER
    canvas = [["0"] * big_w for _ in range(big_h)]
    for y in range(big_h):
        v = (y + 0.5) / big_h
        for x in range(big_w):
            u = (x + 0.5) / big_w
            if mirror:
                u = min(u, 1 - u)
            for shape, colour in figure:
                if shape(u, v):
                    canvas[y][x] = colour
    rows = []
    for y in range(height):
        row = ""
        for x in range(width):
            counts = {}
            for dy in range(SUPER):
                for dx in range(SUPER):
                    c = canvas[y * SUPER + dy][x * SUPER + dx]
                    counts[c] = counts.get(c, 0) + 1
            solid = {c: n for c, n in counts.items() if c != "0"}
            special = [c for c in keep if solid.get(c, 0) * 4 >= SUPER * SUPER]
            if special:
                row += special[0]
            elif sum(solid.values()) * 2 >= SUPER * SUPER:
                row += max(solid, key=solid.get)
            else:
                row += "0"
        rows.append(row)
    return rows


def tyranid(frame):
    """The swarm's bug, front on: scything talons up, a dark carapace over a
    green body, red eyes, grey legs. 11 and 3 are swapped for each kind."""
    raise_talon = 0.06 * frame
    legs = [(0.40, 0.62, 0.10 + 0.04 * frame, 0.97), (0.43, 0.68, 0.27 - 0.04 * frame, 0.99)]
    figure = [(capsule(x0, y0, x1, y1, 0.035), "6") for x0, y0, x1, y1 in legs]
    figure += [
        (ellipse(0.5, 0.63, 0.21, 0.2), "3"),
        (band(0.55, 0.58, ellipse(0.5, 0.63, 0.17, 0.2)), "b"),
        (band(0.66, 0.69, ellipse(0.5, 0.63, 0.15, 0.2)), "b"),
        (ellipse(0.5, 0.43, 0.16, 0.13), "b"),
        (ellipse(0.5, 0.29, 0.11, 0.1), "b"),
        (triangle((0.43, 0.25), (0.47, 0.22), (0.36, 0.06)), "3"),
        (ellipse(0.445, 0.29, 0.03, 0.025), "8"),
        (capsule(0.47, 0.36, 0.485, 0.42, 0.015), "7"),
        (capsule(0.37, 0.41, 0.17, 0.22 - raise_talon, 0.045), "b"),
        (capsule(0.17, 0.22 - raise_talon, 0.11, 0.44 - raise_talon, 0.035), "b"),
        (capsule(0.12, 0.38 - raise_talon, 0.11, 0.45 - raise_talon, 0.03), "7"),
    ]
    return figure


SWARM_SIZES = [8, 10, 12, 14, 16, 18, 22, 24, 28, 32]


def swarm_layout():
    """Where each size's two frames go in the sheet: rows of sizes packed
    left to right, each row as tall as its largest."""
    rows = [[8, 10, 12, 14, 16], [18, 22, 24], [28, 32]]
    layout, top = {}, 0
    for row in rows:
        left = 0
        for size in row:
            layout[size] = (left, top)
            left += size * 2
        assert left <= 128, "row of sizes %s is %d wide" % (row, left)
        top += max(row)
    return layout, top


def kaiju_torso():
    """The giant's trunk, 40x32: shoulders, a scaled chest and a ridged belly."""
    return [
        (ellipse(0.5, 0.55, 0.42, 0.45), "3"),
        (ellipse(0.16, 0.22, 0.16, 0.2), "3"),
        (ellipse(0.5, 0.62, 0.2, 0.36), "5"),
        (band(0.4, 0.44, ellipse(0.5, 0.62, 0.2, 0.36)), "d"),
        (band(0.56, 0.6, ellipse(0.5, 0.62, 0.2, 0.36)), "d"),
        (band(0.72, 0.76, ellipse(0.5, 0.62, 0.2, 0.36)), "d"),
        (band(0.88, 0.92, ellipse(0.5, 0.62, 0.2, 0.36)), "d"),
        (ellipse(0.2, 0.5, 0.025, 0.03), "1"),
        (ellipse(0.12, 0.34, 0.025, 0.03), "1"),
        (ellipse(0.24, 0.78, 0.025, 0.03), "1"),
        (ellipse(0.3, 0.3, 0.025, 0.03), "1"),
        (triangle((0.1, 0.12), (0.2, 0.08), (0.1, -0.1)), "6"),
        (triangle((0.24, 0.07), (0.32, 0.06), (0.26, -0.12)), "6"),
    ]


def queen_head():
    """The hive queen's head, 24x24: our own queen of the swarm, crowned. A
    narrow, sharp face with glowing eyes and high cheek ridges, spined
    tendrils sweeping down from the skull to her shoulders, and a gold chitin
    crown with red gems. 3 is her body (pink in the game)."""
    figure = [
        (capsule(0.36, 0.3, 0.12, 0.95, 0.05), "2"),
        (capsule(0.4, 0.28, 0.24, 1.0, 0.045), "2"),
        (capsule(0.3, 0.38, 0.06, 0.8, 0.04), "2"),
        (ellipse(0.5, 0.5, 0.24, 0.26), "3"),
        (triangle((0.3, 0.55), (0.5, 0.55), (0.5, 0.92)), "3"),
        (capsule(0.29, 0.52, 0.4, 0.6, 0.03), "1"),
        (triangle((0.34, 0.5), (0.45, 0.53), (0.36, 0.56)), "b"),
        (capsule(0.44, 0.78, 0.5, 0.79, 0.015), "1"),
        (band(0.2, 0.3, ellipse(0.5, 0.3, 0.26, 0.12)), "a"),
        (triangle((0.26, 0.26), (0.34, 0.26), (0.24, 0.02)), "a"),
        (triangle((0.38, 0.24), (0.46, 0.24), (0.4, 0.06)), "a"),
        (triangle((0.46, 0.24), (0.54, 0.24), (0.5, 0.0)), "a"),
        (ellipse(0.5, 0.24, 0.04, 0.04), "8"),
        (ellipse(0.32, 0.25, 0.025, 0.025), "8"),
        (band(0.27, 0.3, ellipse(0.5, 0.3, 0.26, 0.12)), "9"),
    ]
    return figure


def kaiju_head(open_jaw):
    """Its head, 24x20, front on: a horned lizard skull, red eyes under a
    heavy brow, a snout of teeth; the jaw drops open when it spits."""
    drop = 0.12 if open_jaw else 0
    figure = [
        (triangle((0.24, 0.32), (0.34, 0.26), (0.06, 0.0)), "6"),
        (ellipse(0.5, 0.42, 0.36, 0.3), "3"),
        (ellipse(0.5, 0.72 + drop / 2, 0.24, 0.2 + drop / 2), "3"),
        (capsule(0.22, 0.34, 0.4, 0.42, 0.04), "1"),
        (ellipse(0.36, 0.48, 0.06, 0.05), "8"),
        (ellipse(0.38, 0.47, 0.02, 0.02), "a"),
    ]
    if open_jaw:
        figure += [(ellipse(0.5, 0.76, 0.17, 0.13), "2")]
    figure += [(triangle((x, 0.64), (x + 0.06, 0.64), (x + 0.03, 0.74)), "7") for x in (0.32, 0.42)]
    figure += [(triangle((x, 0.88 + drop), (x + 0.06, 0.88 + drop), (x + 0.03, 0.8 + drop)), "7")
               for x in (0.36,)]
    return figure


def kaiju_claw():
    """A hand, 8x8: three hooked talons."""
    return [
        (ellipse(0.5, 0.35, 0.36, 0.32), "3"),
        (capsule(0.22, 0.5, 0.12, 0.95, 0.09), "7"),
        (capsule(0.5, 0.55, 0.5, 1.0, 0.09), "7"),
        (capsule(0.78, 0.5, 0.88, 0.95, 0.09), "7"),
    ]


def kaiju_foot():
    """A foot, 16x8: a splayed, clawed lizard foot."""
    return [
        (ellipse(0.5, 0.45, 0.42, 0.4), "3"),
        (capsule(0.12, 0.6, 0.02, 0.95, 0.07), "7"),
        (capsule(0.5, 0.65, 0.5, 1.0, 0.07), "7"),
        (capsule(0.88, 0.6, 0.98, 0.95, 0.07), "7"),
    ]


def outlined(rows, colour="1"):
    """Rows with a one-pixel outline round everything solid."""
    height, width = len(rows), len(rows[0])
    out = [list(r) for r in rows]
    for y in range(height):
        for x in range(width):
            if rows[y][x] == "0" and any(
                    0 <= y + dy < height and 0 <= x + dx < width and rows[y + dy][x + dx] not in "01"
                    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0))):
                out[y][x] = colour
    return ["".join(r) for r in out]
