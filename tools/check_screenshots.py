#!/usr/bin/env python3
"""Find demos whose opening frame shows almost nothing.

A demo that opens onto an empty field and waits for a click teaches less than
one that opens with the mechanism already running: the reader has to imagine
what it looks like before they can see it. And a demo whose world is built out
of bare collision shapes shows nothing at all, since collision shapes are drawn
by the editor, not by the game.

The screenshots make both visible for the first time. This measures how much of
each frame has anything in it: the image is cut into a grid and a cell counts if
it holds any pixel that is not the background colour. A HUD line across the top
lights up a row; a demo actually doing something lights up the middle.

    tools/screenshots.sh                 # capture docs/img/<demo>.png
    tools/check_screenshots.py           # report the empty ones
    tools/check_screenshots.py --check   # non-zero if a new one appears

It is a signal, not a verdict — a demo can be legitimately sparse, and EXEMPT
records the ones that are, with the reason.

Needs Pillow, which nothing else here does; this is a local reporting tool
rather than part of run-tests.sh.
"""

import os
import sys

try:
    from PIL import Image
except ImportError:
    print("needs Pillow: pip install --user Pillow", file=sys.stderr)
    sys.exit(2)

IMG_DIR = "docs/img"

GRID_X, GRID_Y = 16, 12

# Below this share of occupied cells, the frame is mostly nothing. Calibrated
# against the collection: a demo drawing a HUD line and one sprite lands near
# 8%, and one whose scene is actually populated clears 13%.
EMPTY = 0.10

# Demos whose opening frame is legitimately near-empty, with the reason.
EXEMPT = {
    "arrow-sprite": "one sprite on a plain field is the whole demo",
}


def occupancy(path):
    """Share of grid cells holding anything other than the background colour."""
    with Image.open(path) as img:
        img = img.convert("RGB")
        width, height = img.size
        counted = img.getcolors(maxcolors=1 << 18)
        pixels = img.load()
        background = max(counted)[1] if counted else None
        cells = set()
        # Every second pixel: the smallest thing worth seeing is a glyph stroke,
        # which is wider than that, and it makes the sweep four times cheaper.
        for y in range(0, height, 2):
            row = y * GRID_Y // height
            for x in range(0, width, 2):
                if pixels[x, y] != background:
                    cells.add((x * GRID_X // width, row))
    return float(len(cells)) / (GRID_X * GRID_Y)


def main():
    check = "--check" in sys.argv
    if not os.path.isdir(IMG_DIR):
        print("no %s — run tools/screenshots.sh first" % IMG_DIR, file=sys.stderr)
        return 2

    shots = sorted(f for f in os.listdir(IMG_DIR) if f.endswith(".png"))
    if not shots:
        print("no screenshots in %s" % IMG_DIR, file=sys.stderr)
        return 2

    flagged = []
    for name in shots:
        demo = name[:-4]
        share = occupancy(os.path.join(IMG_DIR, name))
        if share < EMPTY and demo not in EXEMPT:
            flagged.append((share, demo))

    flagged.sort()

    if not flagged:
        print("checked %d screenshot(s) — every demo shows something" % len(shots))
        return 0

    print("%d of %d screenshot(s) are nearly empty:\n" % (len(flagged), len(shots)))
    for share, demo in flagged:
        print("  %5.1f%% of the frame has anything in it   %s" % (share * 100, demo))
    print("\nGive the demo something to show when it opens — seed the simulation,")
    print("draw the walls the physics already has — or add it to EXEMPT here with")
    print("the reason.")
    return 1 if check else 0


if __name__ == "__main__":
    sys.exit(main())
