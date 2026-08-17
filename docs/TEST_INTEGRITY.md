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

After converting fourteen suites and correcting the measurement, the floor was:

```
86/423 mutations caught (20.3%)
15 suites caught everything, 105 caught nothing
```

Another thirty conversions later it was 258/643 (40.1%), and thirty after that
the recorded floor is:

```
341/649 mutations caught (52.5%)
43 suites caught everything, 46 caught nothing
```

The sample is smaller because the sweep now uses three mutations per demo rather
than four; the ratio is what the ratchet compares. The measurement changed too:
`scripts/main.gd` used to be excluded unconditionally as "the demo driver",
which is right when it only wires the scene and wrong for the ~66 demos whose
logic lives there — the exclusion hid exactly the code a conversion had just
covered. It is now included whenever the suite references it.

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

## Scores that cannot reach 100%

Three kinds of surviving mutation are not worth chasing, and a score should be
read with them in mind:

- **Input-reading lines.** `if Input.is_action_just_pressed(...) and on_floor:`
  cannot be driven without simulating input. Extracting the *rule* moves the
  testable part out; what remains is the wiring.
- **Display code.** A `_draw()` colour or a HUD label string is not logic. Where
  it lives in a script the tool mutates, it will survive.
- **Equivalent mutations.** Some changes do not alter observable behaviour at
  all. `moving-platforms` offsets by `_origin + offset`; flipping it to `-` just
  mirrors a symmetric sine, which over time is indistinguishable. That one
  turned out to be killable after all — the *first* movement direction differs,
  because `sin` is positive just after zero — but the general case exists and a
  genuinely equivalent mutation can never be killed.

A demo scoring 50% with the other 50% in those three categories is done.

And a fourth case, where the score is not just capped but undefined:

- **Demos whose subject is the scene, not a script.** `bouncing-ball` is a
  `RigidBody2D` with a bouncy `PhysicsMaterial` between four static walls; its
  only script draws a circle. There is nothing in a `.gd` file to mutate, so the
  tool reports `no-mutations`. The suite is still worth writing — it just has to
  run the real scene and watch the ball, because the alternative is a suite that
  reimplements a bounce the demo does not contain.

## Deriving your inputs from the code under test

A suite that computes where to click by calling the demo's own layout function
moves with it. `config-file` scored 50% on its first conversion for exactly
this reason: every mutation that shifted a control also shifted the click that
was supposed to find it, so the suite passed and the survivor looked
unkillable.

The fix is one test that states the layout independently — controls inside the
panel, rows in order and not overlapping, the save button centred. Everything
else can keep deriving its clicks, which is what keeps the suite readable.

The same trap catches any suite whose expected value is computed the way the
code computes it. Comparing a shoelace area against a rectangle whose area you
know is a test; comparing it against a second shoelace implementation is not.

## Watching a scene play out

Suites run with `--quit-after 5` frames, which is enough for `_ready` and a
physics step but not for a body to fall and land. A demo that needs longer puts
a frame count in `tests/frames`:

```
$ cat bouncing-ball/tests/frames
200
```

The headless viewport is **64x64**, not the project's window size — the dummy
display driver opens a minimal window. A suite that hard-codes 640x480 while the
demo reads `get_viewport_rect()` is testing two different play areas. Either
derive positions from the live rect, or resize the window first — which works
even under the dummy driver:

```gdscript
get_window().size = Vector2i(640, 480)
```

`export-vars` needs the resize: its play area has a 40 px margin at the top and
30 at the bottom, which leaves no room at all inside a 64 px window.

`move_and_slide()` is the usual reason a suite needs this. It hands the
movement to the physics server, which applies it on the server's own step — so
calling `_physics_process` by hand sets the velocity and moves nothing. Assert
on `velocity` if that is what you mean, and await real `physics_frame`s if you
mean the body actually moved.

Both `run-tests.sh` and `tools/mutate.py` read it. It is per-demo on purpose:
the budget is paid on every run, and a mutation run pays it once per mutant, so
raising it for everyone would make the slow tool slower still. Note that
headless runs uncapped, so the count is *process* frames — roughly 0.4 physics
frames each. 200 buys about 80 physics steps, or 1.3 simulated seconds.

## Current state

The work is deliberately incremental. Converting every remaining zero-scoring
suite at once would be a rewrite of most of the collection's tests; the ratchet
exists so it can happen a few demos at a time without anything sliding backwards.

Sixty are done, and 46 suites still catch nothing — a good share of those
being shader and audio showcases where the smoke gate is the honest guard. Some needed only a rewritten suite because the component
already existed (`experience-leveling`, `drop-table`, `autoload-score`,
`boid-flocking`, `groups`); the rest needed their logic lifting into a method
first (`coyote-time`, `double-jump`, `variable-jump-height`, `wall-slide`,
`wall-jump`, `state-machine`, `top-down-controller`, `grid-movement`,
`spread-shot`, `camera-deadzone`). That refactor is worth doing for its own sake
— it is the same change that makes a demo reusable — so the two goals point the
same way.

**The conversions keep finding real bugs**, which is the argument for doing the
rest:

- `wall-jump` launched the player *into* the wall. `get_wall_normal()` already
  points away from it, so the demo's extra negation reversed the launch. Present
  since the first commit; it survived because the old suite recomputed the
  launch inline with its own sign convention, so demo and test disagreed and
  only the test was ever consulted.
- `variable-jump-height` and `wall-slide` both started life with their state
  flag set such that the mechanic could fire before it had been triggered.
- `quadtree` recursed infinitely on a one-character error, and its suite
  reported only a hang rather than a failure.
- `rope-physics` pinned a dragged point as a segment's right-hand end but not
  its left, so the rope could pull a held point a hundred pixels off the mouse.
- `tower-defense-base` compared an empty dictionary against `null`, so a tower
  with nothing in range still "fired" and reset its cooldown doing it; an enemy
  walking into range waited up to two thirds of a second for its first shot.
- `cellular-automata`'s own water test asserted the wrong row and passed about
  half the time, depending on which way a coin-flip sent the drop.

`docs/GAPS.md` lists demo-shaped gaps; this is the test-shaped one, and it is
the larger pile of work.
