#!/usr/bin/env python3
"""Measure whether a demo's test suite actually catches bugs in the demo.

A suite that reimplements the mechanism inline stays green no matter what
happens to the code it claims to test. That is not hypothetical here: this
collection once had 63 demos that did not run at all while every suite reported
100% passing. The smoke check in run-tests.sh catches "does not run"; nothing
catches "runs, but is wrong".

This does. For each demo it makes a small, deliberate change to the demo's real
scripts — flip a comparison, negate a constant, swap and/or — and re-runs only
the logic suite. If the suite still passes, that mutation SURVIVED: nothing in
the suite depends on the mutated behaviour.

    tools/mutate.py                    # every demo
    tools/mutate.py state-machine      # one or more
    tools/mutate.py --limit 3          # mutations per demo (default 5)
    tools/mutate.py --json report.json # machine-readable output

A score of 0% killed means the suite is testing a copy of the logic rather than
the logic. 100% means every change it tried was noticed.

Scripts are restored after every run, including on Ctrl-C.
"""

import argparse
import glob
import json
import os
import random
import re
import shutil
import subprocess
import sys
import tempfile

GODOT = os.environ.get("GODOT", "godot")

# Ordered by how likely each is to be a behaviour change rather than a crash.
# Each entry is (name, pattern, replacement).
MUTATIONS = [
    ("comparison", re.compile(r"(?<![<>=!])>=(?!=)"), "<="),
    ("comparison", re.compile(r"(?<![<>=!])<=(?!=)"), ">="),
    ("comparison", re.compile(r"(?<![<>=!+\-*/])>(?![=>])"), "<"),
    ("comparison", re.compile(r"(?<![<>=!+\-*/])<(?![=<])"), ">"),
    ("equality", re.compile(r"(?<![<>=!])==(?!=)"), "!="),
    ("equality", re.compile(r"!=(?!=)"), "=="),
    ("boolean", re.compile(r"\band\b"), "or"),
    ("boolean", re.compile(r"\bor\b"), "and"),
    ("literal", re.compile(r"\btrue\b"), "false"),
    ("literal", re.compile(r"\bfalse\b"), "true"),
    ("arithmetic", re.compile(r"(?<=[\w\)\]]) \+ (?=[\w\(])"), " - "),
    ("arithmetic", re.compile(r"(?<=[\w\)\]]) - (?=[\w\(])"), " + "),
]

# Lines we must not touch: comments, annotations, class/extends declarations,
# and anything inside a string (approximated by skipping lines that are mostly
# string, which is good enough to avoid rewriting printed labels).
SKIP_LINE = re.compile(r"^\s*(#|##|@|class_name|extends|signal)")


# main.gd is the demo driver — it builds the scene, wires the HUD, and draws the
# visualisation. None of that is unit-tested by design, so mutating it would
# score every demo badly for a legitimate reason. Excluded unless asked for.
DRIVER = "main.gd"


def demo_scripts(demo, include_driver=False):
    paths = sorted(glob.glob(os.path.join(demo, "scripts", "*.gd")))
    if include_driver:
        return paths
    logic = [p for p in paths if os.path.basename(p) != DRIVER]
    # A demo whose only script IS main.gd has its logic there; measure it.
    return logic or paths


def strip_strings(line):
    """Blank out string contents so mutations never land inside a literal."""
    return re.sub(r'"[^"]*"', lambda m: '"' + " " * (len(m.group(0)) - 2) + '"', line)


def candidates(demo, include_driver=False):
    """Every (path, line_no, name, new_line) mutation available in this demo."""
    out = []
    for path in demo_scripts(demo, include_driver):
        with open(path, encoding="utf-8") as handle:
            lines = handle.read().split("\n")
        for i, line in enumerate(lines):
            if SKIP_LINE.match(line) or not line.strip():
                continue
            masked = strip_strings(line)
            for name, pattern, replacement in MUTATIONS:
                match = pattern.search(masked)
                if not match:
                    continue
                mutated = line[:match.start()] + replacement + line[match.end():]
                if mutated == line:
                    continue
                out.append((path, i, name, mutated))
    return out


def run_suite(demo, timeout=90):
    """Run only the logic suite. True if it passed."""
    if not os.path.exists(os.path.join(demo, "tests", "test.tscn")):
        return None
    try:
        proc = subprocess.run(
            [GODOT, "--headless", "--path", demo, "res://tests/test.tscn", "--quit-after", "5"],
            capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return False
    summary = re.findall(r"(\d+)/(\d+) passed", proc.stdout)
    if not summary:
        return False          # no summary at all: the suite did not complete
    passed, total = summary[-1]
    return passed == total


def check_demo(demo, limit, rng, include_driver=False):
    """Return a per-demo result dict."""
    available = candidates(demo, include_driver)
    if not available:
        return {"demo": demo, "status": "no-mutations", "killed": 0, "survived": 0, "detail": []}

    baseline = run_suite(demo)
    if baseline is None:
        return {"demo": demo, "status": "no-suite", "killed": 0, "survived": 0, "detail": []}
    if baseline is False:
        # A suite that is already failing tells us nothing about mutations.
        return {"demo": demo, "status": "already-failing", "killed": 0, "survived": 0, "detail": []}

    chosen = rng.sample(available, min(limit, len(available)))
    killed, survived, detail = 0, 0, []

    backups = {}
    try:
        for path, line_no, name, mutated in chosen:
            if path not in backups:
                backups[path] = open(path, encoding="utf-8").read()
            lines = backups[path].split("\n")
            original = lines[line_no]
            lines[line_no] = mutated
            with open(path, "w", encoding="utf-8") as handle:
                handle.write("\n".join(lines))

            caught = not run_suite(demo)
            # Restore before the next mutation so they never compound.
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(backups[path])

            detail.append({
                "file": os.path.relpath(path, demo),
                "line": line_no + 1,
                "kind": name,
                "was": original.strip()[:90],
                "became": mutated.strip()[:90],
                "caught": caught,
            })
            if caught:
                killed += 1
            else:
                survived += 1
    finally:
        for path, content in backups.items():
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(content)

    return {"demo": demo, "status": "ok", "killed": killed, "survived": survived, "detail": detail}


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("demos", nargs="*", help="demos to check (default: all)")
    parser.add_argument("--limit", type=int, default=5, help="mutations per demo")
    parser.add_argument("--seed", type=int, default=1, help="RNG seed, for reproducible runs")
    parser.add_argument("--json", help="write a machine-readable report here")
    parser.add_argument("--verbose", action="store_true", help="list surviving mutations")
    parser.add_argument("--include-driver", action="store_true",
                        help="also mutate scripts/main.gd (the demo driver, normally untested)")
    parser.add_argument("--check", action="store_true",
                        help="fail if the score dropped below the recorded baseline")
    parser.add_argument("--update", action="store_true",
                        help="record the current score as the new baseline")
    args = parser.parse_args()

    demos = args.demos or sorted(os.path.dirname(p) for p in glob.glob("*/project.godot"))
    rng = random.Random(args.seed)

    results = []
    total_killed = total_survived = 0
    for demo in demos:
        result = check_demo(demo, args.limit, rng, args.include_driver)
        results.append(result)
        total_killed += result["killed"]
        total_survived += result["survived"]

        tried = result["killed"] + result["survived"]
        if result["status"] != "ok":
            print("  --   %-28s %s" % (result["demo"], result["status"]))
        else:
            score = 100.0 * result["killed"] / tried if tried else 0.0
            flag = "WEAK" if score == 0.0 else ("    " if score == 100.0 else "part")
            print("%s   %-28s %d/%d caught  (%3.0f%%)"
                  % (flag, result["demo"], result["killed"], tried, score))
            if args.verbose:
                for entry in result["detail"]:
                    if not entry["caught"]:
                        print("         survived %s:%d  %s  %s -> %s"
                              % (entry["file"], entry["line"], entry["kind"],
                                 entry["was"], entry["became"]))

    tried = total_killed + total_survived
    print()
    print("======================================")
    if tried:
        print("  %d/%d mutations caught (%.0f%%)" % (total_killed, tried, 100.0 * total_killed / tried))
    weak = [r["demo"] for r in results if r["status"] == "ok" and r["killed"] == 0 and r["survived"]]
    strong = [r["demo"] for r in results if r["status"] == "ok" and r["survived"] == 0 and r["killed"]]
    print("  %d suites caught everything, %d caught nothing" % (len(strong), len(weak)))
    print("======================================")

    if args.json:
        with open(args.json, "w", encoding="utf-8") as handle:
            json.dump({"results": results, "killed": total_killed, "survived": total_survived},
                      handle, indent=1)
        print("wrote %s" % args.json)

    # The ratchet. The score may only go up; improving a suite means recording a
    # new floor with --update. Compared as a ratio so the baseline survives new
    # demos being added.
    if args.update:
        _write_baseline(total_killed, tried, len(demos))
        return 0
    if args.check:
        return _check_baseline(total_killed, tried)

    return 0


BASELINE = "docs/mutation-baseline.json"


def _write_baseline(killed, tried, demo_count):
    data = {
        "killed": killed,
        "tried": tried,
        "demos": demo_count,
        "ratio": round(killed / tried, 4) if tried else 0.0,
        "note": "Mutation score floor. Raise it by improving suites; never lower it. "
                "See docs/TEST_INTEGRITY.md.",
    }
    with open(BASELINE, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=1)
        handle.write("\n")
    print("recorded baseline: %d/%d (%.1f%%)" % (killed, tried, 100.0 * data["ratio"]))


def _check_baseline(killed, tried):
    if not os.path.exists(BASELINE):
        print("no baseline recorded — run with --update first", file=sys.stderr)
        return 2
    with open(BASELINE, encoding="utf-8") as handle:
        recorded = json.load(handle)
    current = killed / tried if tried else 0.0
    floor = float(recorded.get("ratio", 0.0))
    # A small tolerance: the sample is random, so an identical suite can vary a
    # little between runs with different seeds.
    if current + 0.02 < floor:
        print("FAIL: mutation score fell from %.1f%% to %.1f%%" % (100 * floor, 100 * current),
              file=sys.stderr)
        print("      A suite got weaker, or a demo's logic moved out from under its tests.",
              file=sys.stderr)
        return 1
    print("OK: %.1f%% against a floor of %.1f%%" % (100 * current, 100 * floor))
    return 0


if __name__ == "__main__":
    sys.exit(main())
