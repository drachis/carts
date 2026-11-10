"""itch_publish.py - push a game's builds and updates to itch.io with butler.

usage (run in the project, beside itch.json):
    py itch_publish.py                  check everything and show the plan; sends nothing
    py itch_publish.py --push           upload every channel
    py itch_publish.py --push --channel html5 --version 1.1
    py itch_publish.py --status         what butler's channels hold
    py itch_publish.py --verify URL     does the public page really embed this build?

itch.json:
    {"target": "yourname/your-game", "version": "1.0",
     "channels": {"html5": "release/game_web.zip", "pico8": "release/game.p8.png"}}

A build is a zip or a folder, or a single file (put in a folder of its own for
butler). Set BUTLER if butler is not on PATH. Log in once with: butler login
"""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
import re


def load_config(path):
    with open(path, encoding="utf-8") as handle:
        config = json.load(handle)
    target = config.get("target", "")
    problems = []
    if target.count("/") != 1 or "yourname" in target:
        problems.append('itch.json: "target" must be your itch name and the game\'s page, like "name/game"')
    if not config.get("channels"):
        problems.append('itch.json: "channels" is empty')
    return config, problems


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()


def verify(page, build):
    """Compare each file of the local zip with what the page's embed serves."""
    html = fetch(page).decode("utf-8", "replace").replace("&quot;", '"').replace("\\/", "/")
    found = re.search(r"https://html-classic\.itch\.zone/html/[\d-]+/[^\"'? ]*", html)
    if not found:
        print("FAIL: no embedded game on %s: is a file marked as played in the browser?" % page)
        return 1
    embed = found.group(0)
    folder = embed.rsplit("/", 1)[0] + "/"
    print("page embeds " + embed)
    bad = 0
    with zipfile.ZipFile(build) as zipped:
        for name in zipped.namelist():
            local, live = zipped.read(name), fetch(folder + name)
            if name.endswith(".html"):
                live = re.sub(rb'\s*<script[^>]*static\.itch\.io/htmlgame\.js[^>]*></script>\s*$', b"", live)
                local = local.rstrip()
                live = live.rstrip()
            same = hashlib.sha256(local).digest() == hashlib.sha256(live).digest()
            bad += not same
            print("%-12s local %d bytes, live %d bytes: %s" % (name, len(local), len(live), "same" if same else "DIFFERENT"))
    if bad:
        print("FAIL: the page is not playing this build. Butler's upload may not be the file")
        print("marked as played in the browser, or itch is still processing it.")
        return 1
    print("the page is serving this build; now play it once in a browser")
    return 0


def main():
    parser = argparse.ArgumentParser(description="push builds to itch.io with butler")
    parser.add_argument("--push", action="store_true", help="really upload; without it nothing is sent")
    parser.add_argument("--status", action="store_true", help="show what is live")
    parser.add_argument("--verify", metavar="URL", help="check the public page embeds this build")
    parser.add_argument("--channel", help="only this channel")
    parser.add_argument("--version", help="version shown on itch.io (default: itch.json's)")
    parser.add_argument("--config", default="itch.json")
    args = parser.parse_args()

    if not os.path.exists(args.config):
        print("no %s here: copy the template and fill it in" % args.config)
        return 2
    config, problems = load_config(args.config)
    base = os.path.dirname(os.path.abspath(args.config))
    version = args.version or config.get("version")
    channels = config.get("channels", {})
    if args.channel:
        if args.channel not in channels:
            problems.append("no channel %s in itch.json (it has: %s)" % (args.channel, ", ".join(channels)))
        channels = {k: v for k, v in channels.items() if k == args.channel}

    if args.verify:
        builds = [os.path.join(base, b) for b in channels.values() if b.lower().endswith(".zip")]
        return verify(args.verify, builds[0]) if builds else 2

    butler = os.environ.get("BUTLER") or shutil.which("butler")
    if not butler:
        problems.append("butler not found: install it from https://itchio.itch.io/butler, or set BUTLER")

    if args.status:
        if problems:
            print("\n".join("PROBLEM: " + p for p in problems))
            return 1
        code = 0
        for channel in channels:
            code |= subprocess.run([butler, "status", "%s:%s" % (config["target"], channel)]).returncode
        return code

    plan = []
    for channel, build in channels.items():
        path = os.path.join(base, build)
        if not os.path.exists(path):
            problems.append("%s: %s does not exist; build it first" % (channel, build))
            continue
        plan.append((channel, path))
        print("%-10s %s (%d KB) -> %s:%s, version %s" % (
            channel, build, os.path.getsize(path) // 1024, config.get("target"), channel, version or "(butler's number)"))
    if problems:
        print("\n".join("PROBLEM: " + p for p in problems))
        return 1
    if not args.push:
        print("nothing sent; add --push to upload")
        return 0

    for channel, path in plan:
        with tempfile.TemporaryDirectory() as folder:
            source = path
            if os.path.isfile(path) and not path.lower().endswith(".zip"):
                source = shutil.copy(path, folder) and folder
            command = [butler, "push", source, "%s:%s" % (config["target"], channel)]
            if version:
                command += ["--userversion", str(version)]
            print(" ".join(command))
            result = subprocess.run(command)
            if result.returncode != 0:
                print("FAIL: %s did not upload; is butler logged in? (butler login)" % channel)
                return result.returncode
    print("pushed; check with --status")
    return 0


if __name__ == "__main__":
    sys.exit(main())
