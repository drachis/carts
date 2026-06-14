# fb_to_png.py : decode a PICO-8 framebuffer dump (a .p8 whose __gfx__ holds a
# cstore of screen memory 0x6000) into a scaled PNG. no external deps.
# usage: py fb_to_png.py shot_fb.p8 out.png [scale]
import sys, re, zlib, struct

PAL = [(0,0,0),(29,43,83),(126,37,83),(0,135,81),(171,82,54),(95,87,79),
       (194,195,199),(255,241,232),(255,0,77),(255,163,0),(255,236,39),
       (0,228,54),(41,173,255),(131,118,156),(255,119,168),(255,204,170)]

def gfx_lines(p8):
    s = open(p8, encoding="utf-8").read()
    g = s.split("__gfx__", 1)[1]
    g = re.split(r"\n__\w+__", g)[0]
    return [ln.strip() for ln in g.splitlines() if re.fullmatch(r"[0-9a-fA-F]{1,128}", ln.strip() or "x")]

def write_png(path, w, h, rgb):
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data +
                struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            raw += bytes(rgb[y*w + x])
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))

src, out = sys.argv[1], sys.argv[2]
scale = int(sys.argv[3]) if len(sys.argv) > 3 else 3
lines = gfx_lines(src)
W, H = 128*scale, 128*scale
rgb = [(0,0,0)] * (W*H)
for y in range(128):
    line = lines[y] if y < len(lines) else "0"*128
    for x in range(128):
        col = PAL[int(line[x], 16)] if x < len(line) else PAL[0]
        for sy in range(scale):
            for sx in range(scale):
                rgb[(y*scale+sy)*W + (x*scale+sx)] = col
write_png(out, W, H, rgb)
print("wrote", out, "%dx%d" % (W, H))
