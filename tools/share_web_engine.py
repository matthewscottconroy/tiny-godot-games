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

CONFIG_LINE = re.compile(r"^const GODOT_CONFIG = (\{.*\});\s*$", re.M)


def demo_builds(root):
    """Every exported demo directory — the ones with a loader beside a pack."""
    found = []
    for path in sorted(glob.glob(os.path.join(root, "*", "index.html"))):
        found.append(os.path.dirname(path))
    return found


def read(path):
    with io.open(path, encoding="utf-8") as handle:
        return handle.read()


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

        if already and not os.path.exists(own_wasm):
            continue                      # this build is already sharing

        if check:
            problems.append("%s still carries its own engine" % build)
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
        with io.open(html_path, "w", encoding="utf-8") as handle:
            handle.write(page)
        changed += 1

    if problems:
        print("%d problem(s):\n" % len(problems))
        for problem in problems[:10]:
            print("  " + problem)
        if len(problems) > 10:
            print("  ... and %d more" % (len(problems) - 10))
        return 1

    if check:
        print("every build shares the engine")
        return 0

    print("%d build(s) now share one engine — %.0f MB reclaimed"
          % (changed, reclaimed / (1024.0 * 1024.0)))
    return 0


def main():
    return share(OUT_DIR, "--check" in sys.argv)


if __name__ == "__main__":
    sys.exit(main())
