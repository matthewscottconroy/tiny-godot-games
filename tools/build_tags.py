#!/usr/bin/env python3
"""Give every demo a set of concept tags, derived from its own source.

The README index sorts demos into one category each, which is the right shape
for browsing but a poor fit for the question people actually arrive with: "show
me the ones that use a shader", "which of these need a gamepad", "what can I
read without knowing about physics". Those cut across the categories.

Every tag here is a fact about the code, worked out by reading it:

    tools/build_tags.py            # write docs/TAGS.md and each README's line
    tools/build_tags.py --check    # fail if either is out of date

The one exception is `good-first-demo`, which is a judgement and so is listed
by hand below. Everything else is derived, so a demo that stops using audio
stops being tagged audio without anyone remembering to edit a list.
"""

import glob
import io
import os
import re
import sys

DOC = "docs/TAGS.md"
MARKER = "<!-- tags:"

# Hand-picked: the demos to send someone who has not written Godot before.
# Short, one idea each, and nothing that needs a concept from another demo.
GOOD_FIRST = {
    "arrow-sprite",
    "autoload-score",
    "coin-collector",
    "export-vars",
    "signal-relay",
    "scene-instancing",
    "area-trigger",
}

# Tag -> (description, predicate over the demo's source and files).
# Each predicate takes the joined GDScript source and the demo's file list.
TAGS = [
    ("physics", "Bodies, areas and collision — the engine moving things for you.",
     lambda src, files: re.search(r"\b(CharacterBody2D|RigidBody2D|StaticBody2D|Area2D|"
                                  r"PhysicsServer2D|move_and_slide|PinJoint2D|"
                                  r"DampedSpringJoint2D)\b", src) is not None),
    ("shader", "Carries a shader, whether written in a file or built in code.",
     lambda src, files: any(f.endswith(".gdshader") for f in files)
                        or "ShaderMaterial" in src or "shader_type" in src),
    ("audio", "Makes a sound, or routes one.",
     lambda src, files: re.search(r"\bAudio(Stream|Server|Effect)", src) is not None),
    ("ui", "Built out of Control nodes rather than drawing.",
     lambda src, files: re.search(r"\b(Button|Label|HSlider|SpinBox|CheckButton|"
                                  r"VBoxContainer|HBoxContainer|GridContainer|"
                                  r"RichTextLabel|ProgressBar|TextureRect)\b", src) is not None),
    ("procedural", "Generates its own content rather than loading it.",
     lambda src, files: re.search(r"\b(FastNoiseLite|randf|randi|RandomNumberGenerator|"
                                  r"Image\.create)\b", src) is not None),
    ("persistence", "Reads or writes something that outlives the run.",
     lambda src, files: re.search(r"\b(FileAccess|ConfigFile|ResourceSaver|DirAccess)\b",
                                  src) is not None),
    ("signals", "Declares a signal of its own — the loose-coupling lesson.",
     lambda src, files: re.search(r"^\s*signal\s+\w+", src, re.M) is not None),
    ("component", "Ships a class_name you can lift into another project.",
     lambda src, files: re.search(r"^class_name\s+\w+", src, re.M) is not None),
    ("tool-script", "Runs inside the editor as well as the game.",
     lambda src, files: re.search(r"^@tool\b", src, re.M) is not None),
    ("shows-its-working", "Draws the state it is explaining, not just the result.",
     lambda src, files: src.count("draw_string") >= 2),
    ("needs-gamepad", "Wants a controller plugged in to show its subject.",
     lambda src, files: "get_joy_axis" in src or "is_joy_button_pressed" in src),
    ("needs-network", "Talks to something outside the machine.",
     lambda src, files: re.search(r"\b(HTTPRequest|ENetMultiplayerPeer|"
                                  r"MultiplayerAPI)\b", src) is not None),
]

TAG_NAMES = [name for name, _, _ in TAGS] + ["good-first-demo"]


# Directories that hold a project.godot but are not demos. The browser is a
# tool that reads the collection; tagging it would put it in the index and the
# count on the front page.
NOT_A_DEMO = {"browser"}


def demo_dirs():
    return sorted(d for d in os.listdir(".")
                  if os.path.isdir(d) and d not in NOT_A_DEMO
                  and os.path.exists(os.path.join(d, "project.godot")))


def read(path):
    with io.open(path, encoding="utf-8", errors="replace") as handle:
        return handle.read()


def source_of(demo):
    """Every line of GDScript the demo ships, tests excluded.

    The tests are excluded deliberately: a suite that drives a shader does not
    make the demo a shader demo, and tagging from the tests would describe how
    the demo is checked rather than what it teaches.
    """
    parts = []
    for path in sorted(glob.glob(os.path.join(demo, "**", "*.gd"), recursive=True)):
        if os.sep + "tests" + os.sep in path:
            continue
        parts.append(read(path))
    return "\n".join(parts)


def files_of(demo):
    return [p for p in glob.glob(os.path.join(demo, "**", "*"), recursive=True)]


def tags_for(demo):
    src = source_of(demo)
    files = files_of(demo)
    found = [name for name, _, predicate in TAGS if predicate(src, files)]
    if demo in GOOD_FIRST:
        found.append("good-first-demo")
    return found


def readme_line(tags):
    return "%s %s -->" % (MARKER, ", ".join(tags) if tags else "none")


def update_readme(demo, tags, check):
    """Put the demo's tags in its own README, so the folder stays standalone."""
    path = os.path.join(demo, "README.md")
    if not os.path.exists(path):
        return ["%s: no README.md" % demo] if check else []
    text = read(path)
    wanted = readme_line(tags)
    if MARKER in text:
        updated = re.sub(re.escape(MARKER) + r"[^\n]*-->", wanted, text, count=1)
    else:
        # Directly under the title, where a reader meets it before the prose,
        # with one blank line either side.
        lines = text.split("\n")
        insert_at = 1
        while insert_at < len(lines) and lines[insert_at].strip() == "":
            insert_at += 1
        lines[insert_at:insert_at] = [wanted, ""]
        updated = "\n".join(lines)
    if updated == text:
        return []
    if check:
        return ["%s: README tag line is out of date (want: %s)" % (demo, wanted)]
    with io.open(path, "w", encoding="utf-8") as handle:
        handle.write(updated)
    return []


def build_doc(by_tag, demo_tags):
    out = ["# Concept tags", "",
           "Which demos share a property, cut across the categories in the root",
           "[README](../README.md). Generated by `tools/build_tags.py` from the demos'",
           "own source, so a demo that stops using audio stops being tagged `audio`",
           "without anyone remembering.", "",
           "The one hand-picked tag is `good-first-demo`: what to read first is a",
           "judgement, not something the code can answer.", ""]

    out.append("## The tags")
    out.append("")
    out.append("| Tag | Demos | What it means |")
    out.append("|-----|-------|---------------|")
    for name, description, _ in TAGS:
        out.append("| `%s` | %d | %s |" % (name, len(by_tag.get(name, [])), description))
    out.append("| `good-first-demo` | %d | Short, self-contained, and assumes nothing. |"
               % len(by_tag.get("good-first-demo", [])))
    out.append("")

    for name in TAG_NAMES:
        demos = by_tag.get(name, [])
        if not demos:
            continue
        out.append("## %s" % name)
        out.append("")
        out.append(", ".join("[%s](../%s)" % (d, d) for d in demos))
        out.append("")

    untagged = sorted(d for d, tags in demo_tags.items() if not tags)
    if untagged:
        out.append("## Untagged")
        out.append("")
        out.append("Demos none of the tags apply to — usually the smallest ones, which is")
        out.append("worth knowing when you are looking for something to read first.")
        out.append("")
        out.append(", ".join("[%s](../%s)" % (d, d) for d in untagged))
        out.append("")
    return "\n".join(out)


def main():
    check = "--check" in sys.argv
    demos = demo_dirs()

    demo_tags = {}
    by_tag = {}
    problems = []
    for demo in demos:
        tags = tags_for(demo)
        demo_tags[demo] = tags
        for tag in tags:
            by_tag.setdefault(tag, []).append(demo)
        problems.extend(update_readme(demo, tags, check))

    for name in GOOD_FIRST:
        if name not in demo_tags:
            problems.append("good-first-demo names %s, which is not a demo" % name)

    doc = build_doc(by_tag, demo_tags)
    if check:
        current = read(DOC) if os.path.exists(DOC) else ""
        if current != doc:
            problems.append("%s is out of date — run tools/build_tags.py" % DOC)
    else:
        with io.open(DOC, "w", encoding="utf-8") as handle:
            handle.write(doc)

    if problems:
        print("%d problem(s):\n" % len(problems))
        for problem in problems:
            print("  " + problem)
        return 1

    tagged = sum(1 for tags in demo_tags.values() if tags)
    print("%s %d demos, %d tagged, %d tags"
          % ("checked" if check else "wrote", len(demos), tagged, len(by_tag)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
