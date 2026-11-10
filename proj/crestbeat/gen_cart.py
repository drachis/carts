"""gen_cart.py - draws crestbeat's sprites, sounds and music into its carts.

usage: py gen_cart.py

Rewrites everything from __gfx__ on in crestbeat.p8 and tests/*.p8, leaving
the Lua alone, and writes sheet.png so the sprites can be looked at.
run_tests.py runs this first.

Sprites are rows of PICO-8 colour digits; "." is colour 0, transparent.
Symmetrical things are drawn as their left half and mirrored.

    swarm      rows 0-71: ten sizes, 8 to 32px, two frames each (art.py;
               where each lies is swarm_sprites in data.lua)
    robot      36x36, in the map's top half (build_map), not the sheet
    civilian   at 8, 12, 16 and 24px (art.py CIVILIAN_SIZES)
    giant      a hand 8x8 at (80,72), a foot 16x8 at (88,72), the torso
               40x32 at (0,96), the head 24x20 at (40,96) and with its jaw
               open at (64,96), the queen's crowned head 24x24 at (88,96)
               (art.py); its wings are drawn in titan.lua

The music is 120 BPM: sfx speed 15, a note a quarter beat, 32 notes (eight
beats) a pattern. Channel 0 is the drums, and the game reads its note
number to keep its clock on the beat, so every pattern has drums on 0.
"""
import glob
import re
import os
import time

from png import write_png
import art

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = "crestbeat.p8"

REST = (0, 0, 0, 0)
# The song: synthwave in A minor at 120 BPM, about three minutes through
# once, as long as a run, so it barely repeats (the user: "mostly unique for
# the entire run"). Every music sfx is 32 sixteenths at speed 15, two bars;
# channel 0 is always drums, which sync_clock follows, so even the
# breakdown keeps a quiet drum part. Pitches: 12 an octave, C0 = 0, A1 = 21.
KICK, HAT, OPEN = (10, 0, 7, 3), (50, 6, 2, 0), (48, 6, 3, 5)
SNARE, TAIL, GHOST = (32, 6, 6, 0), (30, 6, 3, 5), (34, 6, 2, 0)
SOFT_HAT, ROLL = (50, 6, 1, 0), (36, 6, 5, 0)


def bar(hits):
    """A bar of sixteen sixteenths from {step: note}, rests elsewhere."""
    return [hits.get(step, REST) for step in range(16)]


ROLL_BAR = bar({0: KICK, 2: SNARE, 4: SNARE, 6: KICK, 8: SNARE, 9: SNARE, 10: SNARE, 11: SNARE,
                12: ROLL, 13: (34, 6, 5, 0), 14: (32, 6, 4, 0), 15: OPEN})
VERSE_BAR = bar({0: KICK, 2: HAT, 4: SNARE, 5: TAIL, 6: HAT, 8: KICK, 10: HAT, 11: KICK, 12: SNARE,
                 13: TAIL, 14: OPEN})
BREAK_BAR = bar({0: KICK, 1: HAT, 2: HAT, 3: HAT, 4: SNARE, 5: TAIL, 6: HAT, 7: GHOST, 9: HAT, 10: KICK,
                 11: HAT, 12: SNARE, 13: TAIL, 14: HAT, 15: GHOST})
AMEN_BAR = bar({0: KICK, 1: HAT, 2: KICK, 3: HAT, 4: SNARE, 5: HAT, 6: GHOST, 7: SNARE, 8: HAT, 9: GHOST,
                10: KICK, 11: KICK, 12: SNARE, 13: HAT, 14: GHOST, 15: SNARE})
DRUMS = {
    "intro": bar({0: KICK, 8: KICK, 12: SOFT_HAT}) * 2,
    "verse": VERSE_BAR * 2,
    "verse fill": VERSE_BAR + ROLL_BAR,
    "break": BREAK_BAR * 2,
    "break fill": BREAK_BAR + ROLL_BAR,
    "amen": BREAK_BAR + AMEN_BAR,
    "half": bar({0: KICK, 4: HAT, 8: SNARE, 9: TAIL, 12: HAT, 14: KICK}) * 2,
    "hats": bar({0: SOFT_HAT, 4: SOFT_HAT, 8: SOFT_HAT, 12: SOFT_HAT, 14: SOFT_HAT}) * 2,
}
CHORDS = {"am": (21, [45, 48, 52, 57]), "f": (17, [45, 48, 53, 57]), "c": (24, [48, 52, 55, 60]),
          "g": (19, [47, 50, 55, 59]), "em": (16, [47, 52, 55, 59]), "dm": (14, [50, 53, 57, 62]),
          "e": (16, [47, 52, 56, 59])}


def bass(first, second):
    """Outrun bass: pumping sixteenths on the root, the octave on the third of each beat."""
    notes = []
    for name in (first, second):
        root = CHORDS[name][0]
        notes += [(root, 2, 5, 0), (root, 2, 3, 5), (root + 12, 2, 4, 0), (root, 2, 3, 5)] * 4
    return notes


def held(first, second):
    """A bar-long bass note a chord, a sine that swells in and fades out."""
    notes = []
    for name in (first, second):
        root = CHORDS[name][0] + 12
        notes += [(root, 0, 5, 4)] + [(root, 0, 5, 0)] * 14 + [(root, 0, 5, 5)]
    return notes


def arp(first, second, order=(0, 1, 2, 3, 2, 1, 2, 3), wave=4, lift=0):
    """A sixteenth-note arpeggio through the chord's tones."""
    notes = []
    for name in (first, second):
        tones = CHORDS[name][1]
        notes += [(tones[step] + lift, wave, 2, 0) for step in order * (16 // len(order))]
    return notes


def lead(phrase, wave=1, lift=0):
    """A held lead: each (pitch, sixteenths) struck, then sung with vibrato, fading at its end."""
    notes = []
    for pitch, length in phrase:
        for step in range(length):
            effect = 0 if step == 0 else 5 if step == length - 1 and length > 2 else 2
            notes.append((pitch + lift, wave, 4, effect))
    assert len(notes) == 32, phrase
    return notes


UP = (0, 1, 2, 3)
LEADS = {
    "verse a": [(57, 6), (55, 2), (52, 4), (55, 2), (57, 2), (53, 8), (52, 4), (50, 2), (48, 2)],
    "verse b": [(52, 6), (55, 2), (60, 4), (59, 2), (55, 2), (55, 8), (50, 4), (52, 2), (55, 2)],
    "verse c": [(57, 4), (60, 4), (59, 2), (57, 2), (55, 4), (53, 6), (57, 2), (60, 8)],
    "verse d": [(64, 4), (62, 2), (60, 2), (59, 8), (55, 4), (57, 2), (59, 2), (55, 8)],
    "chorus a": [(52, 4), (50, 2), (48, 2), (45, 6), (48, 2), (53, 4), (52, 2), (50, 2), (48, 6), (45, 2)],
    "chorus b": [(55, 4), (53, 2), (52, 2), (48, 6), (52, 2), (50, 4), (52, 2), (55, 2), (50, 8)],
    "stab a": [(57, 2), (57, 2), (60, 2), (57, 2), (64, 4), (62, 2), (60, 2), (53, 2), (53, 2), (57, 2),
               (53, 2), (60, 4), (57, 4)],
    "stab b": [(55, 2), (55, 2), (60, 2), (55, 2), (64, 4), (62, 2), (60, 2), (59, 2), (59, 2), (62, 2),
               (59, 2), (62, 4), (55, 4)],
    "low a": [(62, 8), (60, 4), (57, 4), (57, 12), (55, 4)],
    "low b": [(60, 8), (57, 4), (53, 4), (56, 12), (59, 4)],
}


def top(name, **options):
    return lead(LEADS[name], **options)


# The song follows the run (the user: verse and chorus matching the game's
# sections, building towards the boss): a section per stage, each looping
# from its "loop" pattern for as long as the stage lasts; main.lua switches
# section on the next 8-beat pattern boundary. Swarms are verses, giants
# choruses, climbs builds; the last climb drops to a breakdown before the
# queen's chorus, everything up an octave. A pattern is (drums, bass, top
# line), 8 beats, 4 seconds; "loop" marks where a section's loop starts.
VERSE_ONE = [("intro", held("am", "f"), None),
             ("intro", held("c", "g"), arp("c", "g", UP)),
             "loop",
             ("verse", bass("am", "f"), top("verse a")),
             ("verse", bass("c", "g"), top("verse b")),
             ("verse", bass("am", "f"), top("verse c")),
             ("verse fill", bass("c", "g"), top("verse d"))]
BUILD = ["loop",
         ("half", bass("f", "g"), arp("f", "g", UP, lift=12)),
         ("break fill", bass("e", "e"), arp("e", "e", UP, lift=12))]
CHORUS_ONE = ["loop",
              ("break", bass("am", "f"), top("chorus a")),
              ("break", bass("c", "g"), top("chorus b")),
              ("break", bass("am", "f"), top("chorus a")),
              ("break fill", bass("c", "g"), top("chorus b")),
              ("break", bass("am", "f"), arp("am", "f", lift=12)),
              ("break", bass("c", "g"), arp("c", "g", lift=12)),
              ("amen", bass("f", "g"), top("stab b")),
              ("break fill", bass("am", "am"), top("stab a"))]
VERSE_TWO = ["loop",
             ("verse", bass("am", "f"), top("verse a", wave=3)),
             ("verse", bass("c", "g"), top("verse b", wave=3)),
             ("verse", bass("dm", "am"), arp("dm", "am")),
             ("verse fill", bass("f", "e"), arp("f", "e", UP)),
             ("verse", bass("f", "g"), arp("f", "g")),
             ("verse fill", bass("em", "am"), arp("em", "am", UP))]
CHORUS_TWO = ["loop",
              ("amen", bass("am", "f"), top("stab a")),
              ("amen", bass("c", "g"), top("stab b")),
              ("amen", bass("am", "f"), top("chorus a", lift=12)),
              ("break fill", bass("c", "g"), top("chorus b", lift=12))]
VERSE_THREE = ["loop",
               ("verse", bass("f", "c"), arp("f", "c", UP)),
               ("verse", bass("dm", "e"), arp("dm", "e", UP)),
               ("verse fill", bass("f", "c"), top("verse c")),
               ("amen", bass("dm", "e"), top("low b"))]
BREAKDOWN = ["loop",
             ("hats", held("dm", "am"), top("low a", wave=0)),
             ("break fill", held("f", "e"), arp("f", "e", UP, lift=12))]
LAST_CHORUS = ["loop",
               ("amen", bass("am", "f"), top("chorus a", lift=12)),
               ("amen", bass("c", "g"), top("chorus b", lift=12)),
               ("amen", bass("am", "f"), top("stab a", lift=12)),
               ("amen", bass("c", "g"), top("stab b", lift=12)),
               ("break", bass("f", "g"), arp("f", "g", lift=12)),
               ("break fill", bass("am", "am"), arp("am", "am", UP, lift=12))]
# a section per stage, in levels.py's order; a section used twice is one copy
STAGE_SECTIONS = [VERSE_ONE, BUILD, CHORUS_ONE, VERSE_TWO, BUILD, CHORUS_TWO, VERSE_THREE, BREAKDOWN,
                  LAST_CHORUS]
GAME_SOUND_IDS = set(range(0, 8)) | set(range(12, 16))


def song():
    """The music sfx (speed 15, deduplicated) as {id: notes}, the __music__
    lines, and each stage's first pattern (data.lua's stage_music)."""
    free = [n for n in range(64) if n not in GAME_SOUND_IDS]
    ids, sounds, lines, starts, placed = {}, {}, [], [], {}
    for section in STAGE_SECTIONS:
        if id(section) in placed:
            starts.append(placed[id(section)])
            continue
        placed[id(section)] = len(lines)
        starts.append(len(lines))
        patterns = [entry for entry in section if entry != "loop"]
        loop_at = section.index("loop")
        for index, (drums, low, high) in enumerate(patterns):
            channels = []
            for notes in (DRUMS[drums], low, high):
                if notes is None:
                    channels.append(0x40)
                    continue
                key = tuple(notes)
                if key not in ids:
                    assert free, "the song needs more than 64 sfx"
                    ids[key] = free.pop(0)
                    sounds[ids[key]] = notes
                channels.append(ids[key])
            flag = (1 if index == loop_at else 0) | (2 if index == len(patterns) - 1 else 0)
            lines.append("%02x %02x%02x%02x40" % ((flag,) + tuple(channels)))
    return sounds, lines, starts


MUSIC_SOUNDS, MUSIC, STAGE_MUSIC = song()


# (speed, notes); a note is (pitch 0..63, waveform, volume, effect)
SOUNDS = [
    (2, [(52, 3, 6, 0), (60, 4, 5, 0), (48, 3, 4, 3), (40, 3, 3, 3)]),        # 0 perfect shot
    (2, [(40, 3, 5, 0), (34, 3, 4, 3), (28, 3, 3, 3)]),                       # 1 good shot
    (3, [(12, 6, 3, 0), (10, 6, 2, 0)]),                                      # 2 miss
    (1, [(56, 6, 7, 0), (30, 3, 6, 0), REST, (52, 6, 6, 0), (24, 3, 5, 0), (18, 3, 3, 0)]),  # 3 knockdown clack
    (4, [(12, 2, 6, 0), (8, 2, 6, 0), (5, 2, 5, 0), (3, 2, 4, 0)]),           # 4 hurt
    (2, [(30, 0, 2, 0), (34, 0, 2, 0)]),                                      # 5 lane step
    (8, [(38, 1, 5, 0), (42, 1, 5, 0), (45, 1, 5, 0), (50, 1, 6, 0), (50, 1, 4, 5)]),  # 6 hill clear
    (10, [(26, 2, 5, 0), (25, 2, 5, 0), (24, 2, 5, 0), (20, 2, 5, 5)]),       # 7 fallen
    None, None, None, None,                                                   # 8-11 music
    (4, [(18, 6, 7, 0), (14, 6, 6, 0), (10, 6, 5, 0), (8, 6, 4, 0), (6, 6, 2, 0)]),  # 12 rocket
    (3, [(57, 0, 6, 0), (57, 0, 4, 0), (57, 0, 2, 0)]),                       # 13 bell lamp
    (6, [(62, 0, 7, 0), (57, 0, 6, 0), (62, 0, 6, 0), (57, 0, 5, 0), (62, 0, 4, 0),
         (57, 0, 3, 0), (62, 0, 2, 0)]),                                      # 14 bell rings
    (1, [(44, 6, 5, 0), (30, 3, 4, 0), (20, 3, 2, 0)]),                       # 15 ticket ka-chunk
]
SOUNDS += [None] * (max(MUSIC_SOUNDS) + 1 - len(SOUNDS))
for number, notes in MUSIC_SOUNDS.items():
    SOUNDS[number] = (15, notes)
SOUNDS = [sound or (1, []) for sound in SOUNDS]


def rows_of(text, width):
    rows = text.strip().split("\n")
    for row in rows:
        assert len(row) == width, "row %r is not %d wide" % (row, width)
    return rows


def mirrored(text, half_width):
    return [(row + row[::-1]).replace(".", "0") for row in rows_of(text, half_width)]


def bobbed(rows, dropped_row):
    """A second frame: everything above `dropped_row` sinks a pixel, the feet stay."""
    return ["0" * len(rows[0])] + rows[:dropped_row] + rows[dropped_row + 1:]


def stamp(sheet, rows, left, top):
    for y, row in enumerate(rows):
        sheet[top + y][left:left + len(row)] = row


def build_gfx():
    sheet = [["0"] * 128 for _ in range(128)]
    layout, _ = art.swarm_layout()
    for size, (left, top) in layout.items():
        for frame in (0, 1):
            stamp(sheet, art.render(art.tyranid(frame), size, size), left + frame * size, top)
    for size, (left, top) in art.CIVILIAN_SIZES.items():
        stamp(sheet, art.render(art.civilian(), size, size), left, top)
    stamp(sheet, art.outlined(art.render(art.kaiju_claw(), 8, 8, mirror=False)), 80, 72)
    stamp(sheet, art.outlined(art.render(art.kaiju_foot(), 16, 8, mirror=False)), 88, 72)
    stamp(sheet, art.outlined(art.render(art.kaiju_torso(), 40, 32)), 0, 96)
    stamp(sheet, art.outlined(art.render(art.kaiju_head(False), 24, 20)), 40, 96)
    stamp(sheet, art.outlined(art.render(art.kaiju_head(True), 24, 20)), 64, 96)
    stamp(sheet, art.outlined(art.render(art.queen_head(), 24, 24)), 88, 96)
    return ["".join(row) for row in sheet]


def build_sfx():
    lines = []
    for speed, notes in SOUNDS:
        assert len(notes) <= 32
        body = "".join("%02x%x%x%x" % note for note in notes)
        lines.append("00%02x0000" % speed + body.ljust(160, "0"))
    return lines


def write_cart(path, text):
    for attempt in range(3):
        try:
            with open(path, "w", encoding="utf-8", newline="\n") as handle:
                handle.write(text)
            return
        except OSError:
            if attempt == 2:
                raise
            time.sleep(0.5)


def build_map():
    """The map's top half (0x2000, 128x64 pixels at four bits, the layout of a
    sprite sheet), which the game has no map for: the robot, drawn at its
    full size. The game copies its rows into the sheet to draw it."""
    pixels = [["0"] * 128 for _ in range(64)]
    stamp(pixels, art.render(art.robot(), art.ROBOT_SIZE, art.ROBOT_SIZE), 0, 0)
    lines = []
    for k in range(32):
        line = ""
        for row in pixels[2 * k:2 * k + 2]:
            for x in range(0, 128, 2):
                line += row[x + 1] + row[x]
        lines.append(line)
    write_png(os.path.join(HERE, "map_sprites.png"), ["".join(r) for r in pixels])
    return lines


MODULES = ["data", "levels", "world", "aliens", "titan", "robot", "payout", "main"]
BUILDS = {
    "lite.lua": ["draw_title", "chrome", "tri", "sunset", "draw_sky", "draw_ground", "draw_buildings",
                 "draw_payout", "draw_hud"],
    "play.lua": ["draw_title"],
    "boot.lua": ["hit_spot", "ring_lamp", "lamps_lit", "update_titan", "spit", "land_spit", "open_spot",
                 "draw_hazards"],
    "capture.lua": ["draw_plan", "chevron", "sync_clock"],
}


def build_stubbed():
    """tests/lite.lua and tests/play.lua: the game's modules with some
    functions stubbed out (each becomes an empty function), so a test cart
    fits 8192 tokens beside its test. lite.lua drops the screens no logic test
    reads; play.lua drops only the title screen, for the carts that read the
    play screens; boot.lua drops the giant fight's rules, for test_boot,
    which never leaves stage 1 but films the title (its giant silhouette
    included: boot_title is the cart's label)."""
    for build, stubs in BUILDS.items():
        code = ""
        for module in MODULES:
            with open(os.path.join(HERE, module + ".lua"), encoding="utf-8") as handle:
                text = handle.read()
            for name in stubs:
                text = re.sub(r"^function %s\((.*?)\)\n.*?^end\n" % re.escape(name),
                              lambda m: "function %s(%s) end\n" % (name, m.group(1)), text, flags=re.M | re.S)
            code += text
        with open(os.path.join(HERE, "tests", build), "w", encoding="utf-8", newline="\n") as handle:
            handle.write(code)


def check_stage_music():
    """data.lua's stage_music must name each stage's first pattern in the song."""
    with open(os.path.join(HERE, "data.lua"), encoding="utf-8") as handle:
        found = re.search(r'stage_music=split"([0-9,]*)"', handle.read())
    wanted = ",".join(str(start) for start in STAGE_MUSIC)
    assert found and found.group(1) == wanted, 'data.lua needs stage_music=split"%s"' % wanted


def main():
    check_stage_music()
    build_stubbed()
    gfx = build_gfx()
    write_png(os.path.join(HERE, "sheet.png"), gfx)
    tail = "\n".join(["__gfx__"] + gfx + ["__map__"] + build_map() + ["__sfx__"] + build_sfx()
                     + ["__music__"] + MUSIC) + "\n"
    carts = [GAME] + sorted(glob.glob(os.path.join(HERE, "tests", "*.p8")))
    written = 0
    for cart in carts:
        path = os.path.join(HERE, cart)
        with open(path, encoding="utf-8", newline="") as handle:
            before = handle.read()
        after = before.split("__gfx__")[0].rstrip("\n") + "\n" + tail
        if after != before:
            write_cart(path, after)
            written += 1
    print("wrote art and sound into %d of %d carts" % (written, len(carts)))


if __name__ == "__main__":
    main()
