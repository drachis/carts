"""png.py - writes rows of PICO-8 colour digits as a PNG, with no dependencies."""
import struct
import zlib

PALETTE = [(0, 0, 0), (29, 43, 83), (126, 37, 83), (0, 135, 81), (171, 82, 54),
           (95, 87, 79), (194, 195, 199), (255, 241, 232), (255, 0, 77),
           (255, 163, 0), (255, 236, 39), (0, 228, 54), (41, 173, 255),
           (131, 118, 156), (255, 119, 168), (255, 204, 170)]


def write_png(path, rows, scale=4):
    """`rows` are strings of hex digits, one PICO-8 colour per digit."""
    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    raw = bytearray()
    for row in rows:
        line = b"".join(bytes(PALETTE[int(digit, 16)]) * scale for digit in row)
        raw += (b"\x00" + line) * scale
    width, height = len(rows[0]) * scale, len(rows) * scale
    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)))
        handle.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        handle.write(chunk(b"IEND", b""))
