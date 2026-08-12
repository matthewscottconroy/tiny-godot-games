# Test integrity

## The problem this measures

Every demo ships a test suite. For most of them, that suite reimplements the
demo's mechanism inline — a `class FakePlayer` or a `_calc_state()` copied out of
the real script — and then tests the copy.

That is not a hypothetical weakness. It is how this collection once had **63
demos that did not run at all** while every suite reported 100% passing. The
smoke check in `run-tests.sh` closed the catastrophic case: a demo whose scripts
do not parse now fails immediately. It does not close the subtler one, where the
demo runs fine and is quietly wrong.

`tools/mutate.py` measures that. It makes a small deliberate change to a demo's
real scripts — flips a comparison, swaps `and` for `or`, negates a boolean — and
re-runs only the logic suite. If the suite still passes, that mutation
**survived**, and nothing in the suite depends on the mutated behaviour.

```bash
tools/mutate.py                     # every demo
tools/mutate.py coyote-time -v      # one demo, listing what survived
tools/mutate.py --json report.json  # machine-readable
```

`scripts/main.gd` is excluded by default: it is the demo driver — scene wiring,
HUD, `_draw()` — and is not unit-tested by design. `--include-driver` overrides
that.

## The baseline

First full run, four mutations per demo:

```
84/542 mutations caught (15%)
10 suites caught everything, 115 caught nothing, 23 partial
```

The split is exactly what the design predicts. Suites that drive the demo's real
type score well:

```
health-bar        4/4 caught     drives the real Health node
vision-cone       4/4 caught     drives the real VisionCone
wave-spawner      4/4 caught     drives the real WaveSpawner
```

Suites that simulate inline score zero, because the code they test is not the
code that shipped:

```
coyote-time       0/4 caught     survived: `_coyote_timer > 0.0 and _jump_buffer > 0.0`
                                 became `or` — jump fires with only one timer,
                                 which is the entire mechanism inverted
double-jump       0/2 caught     survived: `_jumps_left > 0` became `< 0`
```

That `coyote-time` example is worth sitting with. The demo exists to teach that
both timers must be active. Flipping the `and` to an `or` destroys the lesson,
the demo still runs, and its suite still reports 14/14.

## What it found in code written to be tested

The tool also earned its keep against suites written *deliberately* to drive real
code, which is the stronger signal — it is not only catching the obvious cases:

- `save-migration` — `needs_migration()` compared `<` where flipping to `>` went
  unnoticed, because the suite only asserted the false case.
- `health-bar` — the display's colour lerp could be inverted without any
  assertion failing.

Both were real coverage gaps in tests I would otherwise have called thorough.

## The ratchet

`tools/mutate.py --check` compares against `docs/mutation-baseline.json` and
fails if the score drops. CI runs it weekly and on demand rather than per push,
because a full sweep takes several minutes.

The number only moves one way. When you improve a suite, re-run with `--update`
to record the new floor.

## How to improve a score

The fix is almost always the same: **make the suite drive the demo's real
script instead of a copy of it.**

1. If the demo has a `class_name`, instantiate it. `Health`, `Inventory`,
   `WaveSpawner` and the other 34 componentised types are all directly testable.
2. If the logic lives in a method on a node, instantiate the node, `add_child()`
   it, and call the method.
3. If the logic is inline in `_physics_process`, extract it into a method that
   takes its inputs as parameters and returns the result. That refactor is the
   Tier A/B work described in `BUILDING_BLOCKS_ROLLOUT.md`, and it is what makes
   the demo reusable as well as testable — the two goals point the same way.
4. If the demo is a shader or engine-feature showcase with no logic of its own,
   a low score is expected and fine. The smoke check is the real guard there.

## Current state

The work is deliberately incremental. Converting all 115 zero-scoring suites at
once would be a rewrite of most of the collection's tests; the ratchet exists so
it can happen a few demos at a time without anything sliding backwards.
