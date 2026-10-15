"""run_balatro_ref.py - screenshots of the user's own Balatro, for reference.

usage: py balatro_ref/run_balatro_ref.py [path to the Balatro install folder]

Balatro.exe is a LOVE runtime with the game's source zipped onto its end.
This script builds a copy in a scratch folder: the same runtime and DLLs, the
same source plus harness.lua (required at the end of main.lua), written as
bal8tro_ref.exe so LOVE gives it its own save folder (%APPDATA%/bal8tro_ref)
and the user's saves are never read or written. The install is only read.

Steam must be running: the game checks it at boot, and the harness leaves
that check alone. The window opens on top of whatever is on screen for about
a minute. Screenshots land in bal8tro's reference/ folder (gitignored: they
are Balatro's pictures, for looking at, not for the repository).
"""
import io
import os
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(HERE)
INSTALL = sys.argv[1] if len(sys.argv) > 1 else r"O:\Games\SteamLibrary\steamapps\common\Balatro"
NAME = "bal8tro_ref"
SAVE = os.path.join(os.environ["APPDATA"], NAME)
OUT = os.path.join(PROJECT, "reference")
RUN_SECONDS = 90


def build(folder):
    with open(os.path.join(INSTALL, "Balatro.exe"), "rb") as handle:
        exe = handle.read()
    archive = zipfile.ZipFile(io.BytesIO(exe))
    stub = exe[:min(info.header_offset for info in archive.infolist())]
    packed = io.BytesIO()
    with zipfile.ZipFile(packed, "w", zipfile.ZIP_DEFLATED) as out:
        for info in archive.infolist():
            data = archive.read(info)
            if info.filename == "main.lua":
                data += b'\nrequire "harness"\n'
            out.writestr(info.filename, data)
        with open(os.path.join(HERE, "harness.lua"), "rb") as handle:
            out.writestr("harness.lua", handle.read())
    with open(os.path.join(folder, NAME + ".exe"), "wb") as handle:
        handle.write(stub + packed.getvalue())
    for name in os.listdir(INSTALL):
        if name.lower().endswith((".dll", ".txt")):
            shutil.copy(os.path.join(INSTALL, name), folder)


def main():
    if os.path.isdir(SAVE):
        for name in os.listdir(SAVE):
            if name.endswith(".png") or name in ("harness.log", "motion.log"):
                os.remove(os.path.join(SAVE, name))
    folder = tempfile.mkdtemp(prefix=NAME)
    build(folder)
    process = subprocess.Popen([os.path.join(folder, NAME + ".exe")], cwd=folder)
    try:
        process.wait(timeout=RUN_SECONDS)
    except subprocess.TimeoutExpired:
        process.kill()
        print("stopped after %d seconds" % RUN_SECONDS)
    time.sleep(1)
    os.makedirs(OUT, exist_ok=True)
    if not os.path.isdir(SAVE):
        print("no save folder at %s: the copy never started (is Steam running?)" % SAVE)
        return 1
    for name in sorted(os.listdir(SAVE)):
        if name.endswith(".png") or name == "motion.log":
            shutil.copy(os.path.join(SAVE, name), OUT)
            print("reference/" + name)
    log = os.path.join(SAVE, "harness.log")
    if os.path.exists(log):
        print(open(log).read())
    shutil.rmtree(folder, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
