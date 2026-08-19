# Distribution: why there is no addon

The collection now contains 34 components with a `class_name` — `Health`,
`Inventory`, `ObjectPool`, `WaveSpawner`, `SaveMigrator`, `AccessibilitySettings`
and the rest. They have documented APIs, signals, and test suites. The obvious
next step looks like bundling them into `addons/tiny-godot-blocks/` and
publishing one entry to the Godot Asset Library.

This document records the decision not to, and the conditions under which that
should be revisited.

## The tension

The repository's founding constraint is that **every folder is standalone**. No
shared library, no cross-demo imports; you copy one directory into your project
and it works. That constraint is what makes the demos readable — each one can be
understood without tracing into anything else — and it is why the collection
works as a teaching resource rather than a framework.

An addon inverts that. Once `Health` lives in a shared `addons/` folder it stops
being a file you read and starts being a dependency you install. The demo folder
becomes a usage example for a library rather than the thing itself, and the
lesson moves from "here is how hit points work" to "here is how to call our
hit-point class".

The duplication this costs is real and worth naming: the test harness
(`expect` / `_report` / the pass-fail counters) is repeated across every suite,
roughly 700 lines of it. That is the price of the design, not an oversight.

## The decision

**Keep the demos copy-and-go. Do not ship a combined addon.**

Reasons, in order of weight:

1. **The two goals want opposite things.** A good teaching demo is complete and
   self-contained. A good library is factored, general, and versioned. Trying to
   be both produces a mediocre version of each — files with abstraction the
   lesson does not need, and a library whose pieces are shaped by what made a
   nice demo.

2. **Copying is the honest interface for this size of code.** These components
   are 30 to 120 lines. Adding a dependency, a version constraint, and an update
   path to acquire 60 lines of hit-point logic is worse for the adopter than
   copying it and owning it. Godot's `class_name` being globally scoped makes it
   worse still: an addon that defines `Health` collides with every project that
   already has one, which is why every reuse section says to rename.

3. **A library implies a support contract the repo cannot honour.** Published
   addons acquire issues, version-compatibility expectations, and semver
   pressure. A demo collection can freely rewrite a component when a better way
   to teach it appears; a library cannot.

## What is done instead

- Every demo carries a **Use as a building block** section: what to copy, the
  public API, and any autoloads, input actions, or project settings the adopter
  needs. That is the packaging.
- Components that are genuinely separable already live in their own file with a
  `class_name`, so copying one file is usually enough.
- The reuse notes warn about `class_name` collisions explicitly, because that is
  the failure mode copying actually has.

## When to revisit

Ship an addon if **all** of these become true:

- Several components need to reference each other to be useful, so copying one
  stops being sufficient.
- The same component is being copied into enough projects that fixes are not
  reaching them, and that is causing real problems.
- Someone is prepared to maintain a versioned release with a compatibility
  policy, separately from the demos.

Until then the honest position is: this is a collection of examples, and the
best way to use one is to read it and take it.

## Asset Library, narrowly

Publishing individual entries — one component, not a bundle — sidesteps most of
the objections above and is worth considering for the few components that are
both self-contained and widely wanted (`ObjectPool`, `SaveMigrator`,
`AccessibilitySettings` are the obvious candidates). Each would need its own
`class_name` prefix to avoid collisions, and its own README. That is a per-
component decision rather than a repo-wide one, and nothing here forecloses it.

## Pipelines that need more than Godot

Two of the tools here need something the editor alone does not provide:

| Pipeline | Needs | Why |
|----------|-------|-----|
| `tools/screenshots.sh` | a display — `xvfb-run`, or an existing session | Godot's headless mode uses a dummy renderer, so a capture returns null |
| `tools/export_web.sh` | web export templates (~1GB) | a separate download from the editor |

`tools/preflight.sh` reports which pipelines can run here and what each missing
one needs, so the answer arrives before a capture starts rather than partway
through it.

Screenshots prefer `xvfb-run` and fall back to whatever display session is
already running, which works but opens and closes a window per demo for the
duration of the sweep. With neither, the script refuses and says so rather than
writing blank images.

The web export has one non-obvious cost. Every export writes its own copy of the
WebAssembly engine — 39MB, byte-identical every time — so the full set is 6.2GB,
past what GitHub Pages will host and an absurd download for demos that are a few
kilobytes each. Godot's loader can share it: `executable` is the base path it
appends `.wasm` to, and `mainPack` is the data file, so one shared engine plus
161 small packs is the same gallery at **44MB**. `tools/share_web_engine.py` does
that rewrite, and `export_web.sh` calls it at the end of every run because a
fresh export writes its own copy again.

The catch is that `executable` is the base path for everything the engine fetches
for itself, not just the wasm — its `locateFile()` builds
`${executable}.audio.worklet.js` the same way. Moving the engine without moving
the worklets leaves every demo looking for them beside it, which does not fail
at load: it fails the first time a demo plays a sound, and reads as a demo with
no audio. They move too, under the names the engine derives. The boot splash is
identical across demos as well (3.8MB of one PNG) and is referenced by the page
rather than the engine, so it moves under a name of our choosing.

`share_web_engine.py --check` walks every URL each page will request and checks
it against the disk, which is the guard worth having — most of those requests
happen long after the loading screen.

Neither pipeline runs in CI. Both need a large download or a display that a
runner would have to set up per job, for output that changes only when a demo's
appearance does — so they are run locally and their results committed.
