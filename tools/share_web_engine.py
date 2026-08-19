#!/usr/bin/env python3
"""Make the exported demos share one copy of the engine.

Godot's web export writes a complete build per demo: the WebAssembly engine,
the loader, and the demo's own data. The engine is 39 MB and byte-identical
every time, so 161 demos is 6.2 GB of the same file — more than GitHub Pages
will host, and an absurd download for a gallery whose demos are a few kilobytes
each.

The loader already supports this. `executable` is the base path it appends
`.wasm` to, and `mainPack` is the data file, so pointing the first at a shared
copy and the second at the demo's own pack gives one engine and 161 small packs.

Everything the engine fetches for itself resolves from that same base path — its
locateFile() builds `${executable}.audio.worklet.js` and friends — so the
worklets have to move beside it under the shared name, or audio is broken in
every demo. That is not visible from the loading screen; it fails later, in a
demo that plays a sound.

    tools/export_web.sh
    tools/share_web_engine.py       # 6.2 GB -> about 40 MB
    tools/share_web_engine.py --check

Run it after every export; a fresh export writes its own copy again.
"""

import glob
import io
import json
import os
import re
import shutil
import sys

OUT_DIR = os.environ.get("OUT", "build/web")
ENGINE_DIR = "engine"
SHARED_NAME = "godot"

# Files the export writes per demo that are byte-identical across all of them.
# Each maps its per-demo name onto the name it takes beside the shared engine.
#
# The two worklets MUST keep the `godot.` prefix: the engine derives their URLs
# from `executable`, so any other name is a 404 the first time a demo plays a
# sound. The splash is referenced by the page rather than by the engine, so its
# name is ours to choose and the HTML is rewritten to match.
SHARED_FILES = {
    "index.audio.worklet.js": SHARED_NAME + ".audio.worklet.js",
    "index.audio.position.worklet.js": SHARED_NAME + ".audio.position.worklet.js",
    "index.png": SHARED_NAME + ".splash.png",
}

CONFIG_LINE = re.compile(r"^const GODOT_CONFIG = (\{.*\});\s*$", re.M)
SPLASH_SRC = re.compile(r'id="status-splash"[^>]*src="([^"]+)"')

# What the engine fetches for itself, appended to `executable`. Everything here
# is a 404 waiting to happen if the shared copy is named or placed wrongly, and
# only two of them fail early enough to notice by opening the page.
ENGINE_SUFFIXES = [".wasm", ".js", ".audio.worklet.js", ".audio.position.worklet.js"]


def demo_builds(root):
    """Every exported demo directory — the ones with a loader beside a pack."""
    found = []
    for path in sorted(glob.glob(os.path.join(root, "*", "index.html"))):
        found.append(os.path.dirname(path))
    return found


def read(path):
    with io.open(path, encoding="utf-8") as handle:
        return handle.read()


def missing_assets(build, page, config):
    """Every file this page will ask for that is not on disk.

    The loader resolves each URL relative to the page, so this walks the same
    paths a browser would. Worth checking rather than eyeballing: the audio
    worklets are requested the first time a demo plays a sound, long after the
    loading screen has come and gone, so a wrong path there looks like a demo
    that simply has no audio.
    """
    wanted = []
    executable = config.get("executable", "index")
    for suffix in ENGINE_SUFFIXES:
        wanted.append(executable + suffix)
    wanted.append(config.get("mainPack", "index.pck"))
    splash = SPLASH_SRC.search(page)
    if splash:
        wanted.append(splash.group(1))

    absent = []
    for rel in wanted:
        if rel.startswith(("http://", "https://", "data:")):
            continue
        if not os.path.exists(os.path.normpath(os.path.join(build, rel))):
            absent.append(rel)
    return absent


def share(root, check):
    builds = demo_builds(root)
    if not builds:
        print("no exported demos under %r — run tools/export_web.sh first" % root,
              file=sys.stderr)
        return 2

    engine_dir = os.path.join(root, ENGINE_DIR)
    wasm = os.path.join(engine_dir, SHARED_NAME + ".wasm")
    loader = os.path.join(engine_dir, SHARED_NAME + ".js")

    problems = []
    reclaimed = 0
    changed = 0

    for build in builds:
        html_path = os.path.join(build, "index.html")
        page = read(html_path)
        match = CONFIG_LINE.search(page)
        if not match:
            problems.append("%s: no GODOT_CONFIG to rewrite" % html_path)
            continue

        config = json.loads(match.group(1))
        own_wasm = os.path.join(build, "index.wasm")
        own_js = os.path.join(build, "index.js")
        already = config.get("executable", "").startswith("../")

        # Anything from the shared set still sitting in the build directory means
        # this one is not done, whatever its config already says — a run that
        # learned about a new shared file has to revisit the builds it wrote.
        leftovers = [name for name in ["index.wasm"] + list(SHARED_FILES)
                     if os.path.exists(os.path.join(build, name))]

        if already and not leftovers:
            if check:
                for rel in missing_assets(build, page, config):
                    problems.append("%s asks for %s, which is not there" % (build, rel))
            continue                      # this build is already sharing

        if check:
            problems.append("%s still carries its own %s"
                            % (build, ", ".join(leftovers) if leftovers else "engine"))
            continue

        # The first build to get here donates its engine; the rest match it
        # byte for byte, which is the whole reason this is possible.
        if os.path.exists(own_wasm):
            if not os.path.exists(wasm):
                os.makedirs(engine_dir, exist_ok=True)
                shutil.move(own_wasm, wasm)
                shutil.move(own_js, loader)
            else:
                reclaimed += os.path.getsize(own_wasm)
                os.remove(own_wasm)
                if os.path.exists(own_js):
                    reclaimed += os.path.getsize(own_js)
                    os.remove(own_js)

        # The rest of the shared set: first build donates, the others are dropped.
        for own_name, shared_name in SHARED_FILES.items():
            own_path = os.path.join(build, own_name)
            if not os.path.exists(own_path):
                continue
            shared_path = os.path.join(engine_dir, shared_name)
            if os.path.exists(shared_path):
                reclaimed += os.path.getsize(own_path)
                os.remove(own_path)
            else:
                os.makedirs(engine_dir, exist_ok=True)
                shutil.move(own_path, shared_path)

        config["executable"] = "../%s/%s" % (ENGINE_DIR, SHARED_NAME)
        config["mainPack"] = "index.pck"
        # fileSizes drives the loading bar; the engine now lives elsewhere and
        # a stale entry makes the bar stall at a number it never reaches.
        sizes = config.get("fileSizes", {})
        config["fileSizes"] = {k: v for k, v in sizes.items() if not k.endswith(".wasm")}

        page = CONFIG_LINE.sub("const GODOT_CONFIG = %s;" % json.dumps(config, sort_keys=True),
                               page, count=1)
        page = page.replace('<script src="index.js"></script>',
                            '<script src="../%s/%s.js"></script>' % (ENGINE_DIR, SHARED_NAME))
        # The splash is the page's own reference, not the engine's.
        page = page.replace('src="index.png"',
                            'src="../%s/%s"' % (ENGINE_DIR, SHARED_FILES["index.png"]))
        with io.open(html_path, "w", encoding="utf-8") as handle:
            handle.write(page)
        changed += 1

        for rel in missing_assets(build, page, json.loads(CONFIG_LINE.search(page).group(1))):
            problems.append("%s now asks for %s, which is not there" % (build, rel))

    if problems:
        print("%d problem(s):\n" % len(problems))
        for problem in problems[:10]:
            print("  " + problem)
        if len(problems) > 10:
            print("  ... and %d more" % (len(problems) - 10))
        return 1

    if check:
        print("every build shares the engine, and asks only for files that exist")
        return 0

    print("%d build(s) now share one engine — %.0f MB reclaimed"
          % (changed, reclaimed / (1024.0 * 1024.0)))
    return 0


def main():
    return share(OUT_DIR, "--check" in sys.argv)


if __name__ == "__main__":
    sys.exit(main())
