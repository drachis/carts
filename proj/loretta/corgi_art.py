"""corgi_art.py - Loretta's body parts, drawn from shapes for gen_cart.py.

Each part is built from ellipses and triangles in her colours, then given
one dark outline around the whole silhouette, so that pieces cut from one
picture (the body's rear and front) have no line where they meet.

Her character, which the parts serve (DESIGN.md, "Loretta's body"):
a long low loaf on stubby legs, a deep chest; huge mobile ears; the
fluffy white corgi butt; a fox face that is always smiling; a tricolour
coat: dark saddle, tan sides, white chest, belly and butt fluff.

Colours: 0 outline and eyes, 2 the saddle (near black), 4 tan shade,
9 tan, f tan light, 7 white, 6 white shade, e ear pink, b and 3 the
collar, d its tag.
"""


class Canvas:
    def __init__(self, width, height):
        self.width, self.height = width, height
        self.pixels = [["."] * width for _ in range(height)]

    def inside(self, x, y):
        return 0 <= x < self.width and 0 <= y < self.height

    def get(self, x, y):
        return self.pixels[y][x] if self.inside(x, y) else "."

    def set(self, x, y, colour):
        if self.inside(x, y):
            self.pixels[y][x] = colour

    def ellipse(self, cx, cy, rx, ry, colour, only=None):
        """Fill an ellipse; with `only`, recolour just pixels already that."""
        for y in range(self.height):
            for x in range(self.width):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                    if only is None or self.get(x, y) in only:
                        self.set(x, y, colour)

    def triangle(self, points, colour):
        (ax, ay), (bx, by), (cx, cy) = points

        def side(px, py, qx, qy, rx, ry):
            return (px - rx) * (qy - ry) - (qx - rx) * (py - ry)

        for y in range(self.height):
            for x in range(self.width):
                px, py = x + 0.5, y + 0.5
                d1 = side(px, py, ax, ay, bx, by)
                d2 = side(px, py, bx, by, cx, cy)
                d3 = side(px, py, cx, cy, ax, ay)
                if not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0)):
                    self.set(x, y, colour)

    def recolour(self, test, colour):
        """Recolour every filled pixel for which test(x, y) is true."""
        for y in range(self.height):
            for x in range(self.width):
                if self.get(x, y) != "." and test(x, y):
                    self.set(x, y, colour)

    def outline(self, colour="0", skip=lambda x, y: False):
        edge = []
        for y in range(self.height):
            for x in range(self.width):
                if self.get(x, y) == "." and not skip(x, y):
                    if any(self.get(x + dx, y + dy) not in (".", colour)
                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                        edge.append((x, y))
        for x, y in edge:
            self.set(x, y, colour)

    def text(self):
        return "\n".join("".join(row) for row in self.pixels)


def body():
    """Her body, 28x14, facing right: butt, back and chest as one loaf.

    loretta.lua cuts it into a rear piece (columns 0..15) and a front
    piece (12..27), so the seam between them never has its own outline."""
    c = Canvas(28, 14)
    c.ellipse(7, 7.5, 6.5, 6, "9")              # the butt, round and full
    c.ellipse(14, 7, 8.5, 5.5, "9")             # the back
    c.ellipse(22, 8, 5.5, 5.5, "9")             # the deep chest
    c.ellipse(12, 3, 7.5, 3.6, "2", only="9")   # the dark saddle on her back
    c.recolour(lambda x, y: c.get(x, y) == "9" and c.get(x, y - 1) == "2", "4")
    c.recolour(lambda x, y: y >= 11, "7")                                   # belly
    c.recolour(lambda x, y: ((x + 0.5 - 24) / 4.5) ** 2 + ((y + 0.5 - 10) / 5.5) ** 2 <= 1, "7")  # chest fluff
    c.recolour(lambda x, y: x <= 3 and y >= 7, "7")                         # white pants
    c.recolour(lambda x, y: y == 13, "6")
    c.recolour(lambda x, y: c.get(x, y) == "9" and 5 <= x <= 18 and y == 7, "f")  # a lit side
    c.set(0, 6, "7")                                                        # a tuft of tail fluff
    c.outline()
    return c.text()


def sit_body():
    """Her body sitting pretty, 24x16: the butt round on the ground, the
    chest up and the white front facing out; the face sits on top."""
    c = Canvas(24, 16)
    c.ellipse(8, 10, 7, 6, "9")                 # the butt
    c.ellipse(14, 7, 6, 7.5, "9")               # the chest, upright
    c.ellipse(8, 5, 6, 4, "2", only="9")        # the saddle down her back
    c.recolour(lambda x, y: c.get(x, y) == "9" and c.get(x, y - 1) == "2", "4")
    c.recolour(lambda x, y: ((x + 0.5 - 17) / 4) ** 2 + ((y + 0.5 - 9) / 7) ** 2 <= 1, "7")  # chest fluff
    c.recolour(lambda x, y: x <= 3 and y >= 9, "7")                         # white pants
    c.recolour(lambda x, y: y == 15, "6")
    c.outline()
    return c.text()


def face():
    """Her face without ears, 20x15: a fox face three quarters on, looking
    right, the muzzle out front, the white blaze, cheeks and chin. Eyes and
    mouth are drawn by loretta.lua, so they can blink, squint, pant and
    bark: the near eye goes at (12,6), the far one at (5,7)."""
    c = Canvas(20, 15)
    c.ellipse(8, 6.5, 7, 6, "9")               # the skull
    c.ellipse(10, 10, 7, 4, "9")               # cheeks and jaw
    c.ellipse(16.5, 10.5, 3, 2.2, "7")         # the muzzle
    c.recolour(lambda x, y: 8 <= x <= 9 and 1 <= y <= 8, "7")               # the blaze
    c.recolour(lambda x, y: ((x + 0.5 - 11) / 6) ** 2 + ((y + 0.5 - 13.5) / 3.5) ** 2 <= 1, "7")  # white cheeks
    c.recolour(lambda x, y: c.get(x, y) == "9" and y <= 2, "4")            # shade on the crown
    c.outline()
    c.set(19, 9, "0")
    c.set(19, 10, "0")
    c.set(18, 9, "0")                          # the nose
    for x in range(3, 11):
        c.set(x, 13, "b" if x != 7 else "a")   # the collar and its tag
        c.set(x, 14, "3" if x != 7 else "d")
    return c.text()


def ear(tilt, near):
    """An ear, 12x12: a big rounded triangle, pink inside; `tilt` leans its
    tip back (negative) or forward."""
    c = Canvas(12, 12)
    base_y, tip = 11.5, (5.5 + tilt, 0.2 + abs(tilt) / 2)
    c.triangle([(0.5, base_y), (10.5, base_y), tip], "9")
    inner_tip = (5.5 + tilt * 0.8, 3 + abs(tilt) / 2)
    c.triangle([(3, base_y), (8, base_y), inner_tip], "e" if near else "f")
    c.outline(skip=lambda x, y: y >= 11)
    return c.text()
