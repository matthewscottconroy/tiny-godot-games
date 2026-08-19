# Contributing

Thanks for wanting to add to this. The collection has a narrow shape on purpose,
and most of it is enforced by tooling so you get told immediately rather than in
review.

## The shape of a demo

**One demo teaches one thing, completely.** The average demo is about 100 lines
of GDScript. If yours needs three files and a diagram to follow, it is probably
two demos.

**Readability beats reusability.** If turning the mechanism into a generic
component would make the file harder to read as a lesson, don't. Package it
instead (`class_name`, `@export`, a signal) and say so in the reuse section.

**Every folder is standalone.** No shared library, no cross-demo imports. Someone
should be able to copy one directory into their project and have it work. That
means some duplication between demos, and that is the intended trade.

**Zero setup to run.** Demos use Godot's built-in `ui_*` actions rather than
defining an `[input]` map. Note that `ui_left`/`ui_right`/`ui_up`/`ui_down` are
bound to the **arrow keys only** — they do not include the letter keys — and
`ui_accept` is Enter/Space. If your demo wants the letter keys, bind
`KEY_A`/`KEY_D` explicitly in the script.

## Starting a demo

```bash
tools/new-demo.sh my-demo "One-line description for the index"
```

That scaffolds the project, a runnable scene, a script, a test suite, and a
README with the six required sections. It passes `./run-tests.sh` and
`tools/check_docs.py` from the start, so you edit down from green rather than up
from broken.

Then add a row to the index in the root `README.md` under the right category,
and bump the two demo counts (the intro and the footer). `tools/check_docs.py`
will tell you if you forget.

## Tests

Every demo has a headless suite in `tests/`, and `./run-tests.sh` runs two checks
per demo:

1. **Smoke** — boots the real `scenes/main.tscn` and fails on any script or
   scene error.
2. **Logic** — runs `tests/test_logic.gd`.

**Your suite must drive the demo's real scripts.** This is the one rule worth
belabouring: the collection once had 63 demos that did not run at all while
their tests reported 100% green, because every suite reimplemented the mechanism
inline instead of loading the code it was supposedly testing. If your demo
exposes a `class_name`, instantiate it. If the component needs scene children,
instantiate `res://scenes/main.tscn` and drive the real nodes.

A suite that needs a physics step should do its work in `_physics_process` —
`direct_space_state` is only valid there. The runner allows a few frames for it,
and a demo that needs more can ask for them in `tests/frames`.

Two documents are worth reading before writing a suite.
[docs/TEST_INTEGRITY.md](docs/TEST_INTEGRITY.md) covers how much of a demo its
tests actually reach and how that is held from slipping.
[docs/FAILURE_MODES.md](docs/FAILURE_MODES.md) catalogues the bugs the conversion
found, grouped by how each one stayed hidden — it is the shortest route to
knowing what to assert.

```bash
./run-tests.sh my-demo        # one demo
./run-tests.sh                # all of them, in parallel
./run-tests.sh --smoke-only   # just boot everything
JOBS=4 ./run-tests.sh         # cap concurrency if memory is tight
```

Each parallel job is a Godot process holding a rendering server and an imported
project. The default concurrency is bounded by available memory as well as core
count for that reason; `JOBS=` overrides it.

## Checks that run in CI

| Check | What it catches |
|-------|-----------------|
| `./run-tests.sh` | Demos that fail to load, failing assertions, engine warnings, and tests that abort partway |
| `tools/check_docs.py` | Missing README sections, controls the code never binds, index drift, demo-count drift, demos that link to nothing, suites too thin to be checking much |
| `tools/build_index.py --check` | A stale API index or stale related-demo links |
| `tools/build_tags.py --check` | Concept tags that no longer match the source they are derived from |
| `gdlint` | Dead arguments, mixed tabs/spaces, tautological comparisons, naming |

`tools/preflight.sh` reports which of the repository's pipelines can run on your
machine. The tests and doc checks run anywhere Godot does; screenshots need a
display and the web export needs Godot's export templates, and preflight says so
before you start rather than partway through.

The test job runs against several Godot versions. Only the current release gates
the branch; the others are advisory early warning, because this collection has
been broken by engine API drift before and nobody noticed for a long time.

`gdformat` is deliberately **not** run. It would reformat almost every file in
the repo, collapsing the aligned constant tables that make the demos readable.
Indentation consistency is covered by gdlint's `mixed-tabs-and-spaces` instead.

## README sections

All six are required, and `tools/check_docs.py` enforces their presence:

- **Purpose** — why this matters in a real game. Not a restatement of the title.
- **Controls** — every input. Say "none" if the demo is passive.
- **How It Works** — the mechanism, in the order it happens.
- **Key Godot APIs** — a table of what to look up in the docs.
- **Files** — what each file holds.
- **Use as a building block** — what to copy, the public API, and any autoloads,
  input actions, or project settings an adopter needs.

## Concept tags

Every demo carries a line under its title:

```markdown
<!-- tags: physics, ui, signals -->
```

Do not edit it by hand. `tools/build_tags.py` derives every tag from the demo's
own source — a demo that stops using audio stops being tagged `audio` — and CI
fails if the line disagrees with the code. Run the tool after changing what a
demo uses, and it writes both the line and [docs/TAGS.md](docs/TAGS.md).

The one exception is `good-first-demo`, which is a judgement rather than
something the code can answer, so it is a hand-kept list at the top of
`tools/build_tags.py`. A demo belongs on it when it is short, teaches one idea,
and needs no concept from another demo first.

**The GitHub label mirrors that list.** If you maintain the repository, create a
`good first demo` label and apply it to issues about the demos tagged
`good-first-demo` in [docs/TAGS.md](docs/TAGS.md). The tag is the source of
truth because it lives with the code and is checked; the label is a view of it
for people arriving through the issue tracker.

## Style

- Tabs for indentation, including continuation lines.
- Type the things that matter. `var x := 5` is fine; `var x := some_dictionary[k]`
  will not compile, because Godot refuses to infer from a Variant.
- Comments explain *why*, not *what*. The code already says what.
- Prefer showing the mechanism over hiding it behind a helper.
