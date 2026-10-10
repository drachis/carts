"""feel_map.py - a pacing map of wyrmdeep beside one of wyrmfire.

usage: py feel_map.py

Each game has a cart, tests/test_feel.p8, in which a scripted dragon plays
for two minutes at a player's speed (healed, so the map covers the whole
time) and prints one line a second: enemies on screen, kills so far, tiles
burning, shots in the air, health lost that second, position. This runs
both in a window, writes feel.csv, and prints the two side by side: the
averages, and a strip per measure with one character for each five seconds.

It is not a measure of fun. It is a measure of how much is happening, and
of whether it rises and falls.
"""
import os
import subprocess
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
GAMES = {"wyrmfire": os.path.join(HERE, "..", "wyrmfire"), "wyrmdeep": HERE}
COLUMNS = ["second", "enemies", "kills", "burning", "shots", "hurt", "x", "y"]
BLOCKS = " .:-=+*#%@"
STEP = 5  # seconds per character in a strip


def record(folder):
    """Run a game's feel cart; a list of dicts, one per second."""
    process = subprocess.Popen([PICO8, "-run", os.path.join("tests", "test_feel.p8")],
                               cwd=folder, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT)
    watchdog = threading.Timer(240, process.kill)
    watchdog.start()
    rows = []
    for line in process.stdout:
        if line.startswith("INFO: feel "):
            values = [float(value) for value in line[len("INFO: feel "):].split(",")]
            rows.append(dict(zip(COLUMNS, values)))
        if line.startswith("INFO: ok feel"):
            break
    watchdog.cancel()
    process.kill()
    process.wait()
    return rows


def per_second(rows, column):
    """A running total (kills) as a rate; everything else as it is."""
    values = [row[column] for row in rows]
    if column != "kills":
        return values
    return [max(0, now - before) for before, now in zip([0] + values, values)]


def strip(values, top):
    """One character per STEP seconds, darker for more."""
    chars = []
    for start in range(0, len(values), STEP):
        chunk = values[start:start + STEP]
        level = sum(chunk) / len(chunk) / top if top else 0
        chars.append(BLOCKS[min(len(BLOCKS) - 1, int(level * (len(BLOCKS) - 1) + 0.5))])
    return "".join(chars)


def main():
    runs = {name: record(folder) for name, folder in GAMES.items()}
    with open(os.path.join(HERE, "feel.csv"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write("game," + ",".join(COLUMNS) + "\n")
        for name, rows in runs.items():
            for row in rows:
                handle.write(name + "," + ",".join("%g" % row[column] for column in COLUMNS) + "\n")
    for column in ("enemies", "kills", "burning", "shots", "hurt"):
        series = {name: per_second(rows, column) for name, rows in runs.items()}
        top = max(max(values, default=0) for values in series.values())
        print("\n%s (a character is %d seconds; ' ' is none, '@' is %g)" % (column, STEP, top))
        for name, values in series.items():
            if not values:
                print("  %-9s no data" % name)
                continue
            print("  %-9s |%s|  mean %.1f  peak %g" % (
                name, strip(values, top), sum(values) / len(values), max(values)))
    for name, rows in runs.items():
        if rows:
            distance = sum(abs(now["x"] - before["x"]) + abs(now["y"] - before["y"])
                           for before, now in zip(rows, rows[1:]))
            print("\n%s: %d seconds recorded, %.0f px travelled a second" % (
                name, len(rows), distance / max(1, len(rows) - 1)))
    print("\nwrote feel.csv")


if __name__ == "__main__":
    main()
