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

Two of the tools here cannot run on a machine with only the editor installed:

| Pipeline | Needs | Why it is not in CI yet |
|----------|-------|-------------------------|
| `tools/screenshots.sh` | a display (`xvfb-run`) | Godot's headless mode uses a dummy renderer, so a capture returns null |
| `tools/export_web.sh` | web export templates (~1GB) | a separate download from the editor |

`tools/preflight.sh` reports which pipelines can run here and what each missing
one needs, so the answer arrives before a capture starts rather than partway
through it. Both scripts still refuse to run and say why, so a machine without
the prerequisites produces a message rather than blank images or failed exports.

Neither has been validated end to end. That is recorded here rather than left
to be discovered, and it is the honest state: the scripts are a starting point.
