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

It rose to 258/643 (40.1%), then 341/649 (52.5%), then 420/653 (64.3%). With
every suite converted, the recorded floor is:

```
518/664 mutations caught (78.0%)
70 suites caught everything, 3 caught nothing
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

  `gamepad-input` has two, and they are worth reading as the pattern. It guards
  its reads with `return 0.0 if id == NO_PAD else Input.get_joy_axis(id, ax)`,
  and flipping that `==` to `!=` changes nothing on a machine with no gamepad:
  measured rather than assumed, `Input.get_joy_axis(-1, ...)` returns `0.0` and
  `is_joy_button_pressed(-1, ...)` returns `false`, so both sides of the branch
  agree. The guard still earns its place — it states the intent instead of
  relying on that accident — but no test without hardware can hold it.

  When a mutation survives because a line's *value* is never read, that is not
  an equivalent mutation so much as a line worth deleting. `browser` kept a
  `seen[tag] = true` set whose value nothing looked at; replacing the dictionary
  with a linear `has` on thirteen tags removed the unheld line and took the demo
  to 100%.

A demo scoring 50% with the other 50% in those three categories is done.

And a fourth case, where the score is not just capped but undefined:

- **Demos whose subject is the scene, not a script.** A demo can be a scene with
  a bouncy `PhysicsMaterial` and four static walls, its only script drawing a
  circle. There is nothing in a `.gd` file to mutate, so the tool reports
  `no-mutations`. The suite is still worth writing — it just has to run the real
  scene and watch the ball, because the alternative is a suite that reimplements
  a bounce the demo does not contain.

  `bouncing-ball` was the example here until the screenshots showed its walls
  were invisible; drawing them put logic back in a script, and it now scores.

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

## Warnings are failures too

Godot reports a *refused* operation as a warning, not an error. That makes the
warning stream the place where "this line silently did nothing" shows up:

```
WARNING: Can't change the size of a `SubViewport` with a `SubViewportContainer`
parent that has `stretch` enabled.
```

`pixel-art-camera` printed that on every toggle. Both of its modes rendered at
full resolution, so the demo never showed the effect it exists to show, and it
passed the smoke gate, its suite, and the doc checks for as long as it existed.

The smoke gate now fails on any warning, with one allowance for the audio
shutdown leaks in `docs/MEMORY.md` that cannot be fixed from here. Stale
`ext_resource` UIDs and deprecated engine calls surfaced the same way.

## A test that aborts still reports a pass

A runtime error inside a GDScript function — an index off the end of an array,
a call on a null — prints an error, abandons that function, and lets the caller
carry on. If it happens partway through a test, the assertions after it simply
never run: the suite prints a smaller `n/n passed` and the harness, which only
compares the two numbers, sees nothing wrong.

The usual way to walk into this is a typed local:

```gdscript
var sky: Color = m._lerp_keyframes(t, 0)   # returns null on error -> aborts here
var sky: Variant = m._lerp_keyframes(t, 0) # returns null -> `sky is Color` fails
```

Where a test exists to check that a function copes with bad input, hold the
result as `Variant` and assert its type. Otherwise the test proves only that
the call did not crash the engine.

`run-tests.sh` now fails a suite whose output contains an abort-class error —
a freed instance, a missing property, an assignment to null, an index out of
bounds. It deliberately tolerates the `Node not found` an `@onready` logs when
a script is driven outside its scene, which is noise rather than a failure.

Two ways to walk into it that the check caught straight away:

- **Reading from a scene a later `_make()` has freed.** Copy the value out
  before building the next one.
- **Calling an awaiting test without `await`.** The caller carries on, the next
  test frees the scene, and the first test then resumes into the wreckage.

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

All 165 are done: every suite drives the demo's own code rather than a copy of
its logic, and **no suite catches nothing**. The floor stands at 582/676
(86.1%), with 88 of 166 suites catching every mutation sampled.

The last three suites that caught nothing were
`animated-sprite`, `camera-follow` and `line-of-sight`, and each hid something
beyond its score. `line-of-sight` tested the ray-casting helper thoroughly and
never drove the enemy that decides whether it is alerted. `camera-follow`'s
suite added a fresh copy of the world per test and left it there, which is
invisible while every test only reads configuration and shoves the player off
the level the moment one lets the physics run. `animated-sprite` restated the
animation rules inline and checked its own copy against itself, in the repo that
documents that as a failure mode.

The three weakest after them — `object-pool`, `knockback` and
`checkpoint-system`, all at 20% — shared one shape: each drove its demo's
*reusable component* thoroughly and never touched the scripts around it, which
is where every survivor lived. `knockback`'s is the one to remember: its suite
only ever hit from the origin, where `target - source` and `target + source`
give the same direction, so it could not tell a subtraction from an addition and
the mutation that reverses every recoil in the demo survived it. A test fixture
sitting at (0, 0) hides sign errors.

`homing-projectile`, `status-effects` and `multiplayer-prediction` were the
next three, all in the same shape, and `multiplayer-prediction` is the one to
read: its component was covered exhaustively while the demo around it — the
shared simulate step, the two queues carrying inputs to the server and states
back, and the keys that make it demonstrate anything — had nothing at all.

Two test smells worth naming, because both look like thorough tests:

- **A fixture at the origin hides sign errors.** `target - source` and
  `target + source` are the same vector when one of them is `(0, 0)`.
  `knockback` only ever hit from the origin, `homing-projectile` only ever
  launched from it, and `quadtree` rooted every tree there — in all three the
  mutation that reverses a direction survived. `quadtree` is the clearest: a
  tree at the origin cannot tell `x + hw` from `x - hw` in any way its tests
  were looking at, because the node still reports four children, the count is
  still right, and objects that should have landed in a misplaced quadrant
  simply vanish. Put the fixture somewhere arbitrary. `combo-system` had the
  same trap in *time* — its window is `now - then`, and a suite running inside
  the first second of engine uptime cannot tell that from `now + then`.
- **A bound with no floor is half a test.** `homing-projectile` asserted its
  trail was capped at 12, which a trail trimmed to a single dot every frame
  satisfies equally well.

- **A cap tested by reimplementing the trimming is a cap tested against
  itself.** `dash-ability`'s trail assertion did the capping arithmetic in the
  suite rather than driving the demo's loop.
- **"It did not happen" needs the right window.** `dash-ability`'s "the player
  does not dash on its own" checked the dash flag sixty frames later, by which
  time a dash that had started and finished was invisible. Its cooldown was
  still set, and that is what the assertion reads now.
- **A generated buffer can be well-formed and still wrong.**
  `footstep-audio` checked its tone was the right length and mix rate, which
  silence satisfies. Peak, envelope and smoothness all survive the two bytes of
  a sample being written to the wrong indices, because a smooth wave hides a
  displaced high byte everywhere except at a transition. A 20Hz tone moves less
  than one high byte between neighbouring samples, so there the displacement is
  a jump the wave cannot make.
- **One scene at a time.** `camera-follow` and `footstep-audio` both added a
  fresh copy of the world per test and left it in the tree. Invisible while
  every test only reads configuration; the moment one lets the physics run, the
  stacked players depenetrate off each other and the one being watched is shoved
  off the level.

And one trap in writing the test itself: `multiplayer-prediction`'s deep-copy
test passed while both mutants survived, because the step function it supplied
copied defensively and hid the sharing the test existed to expose. A test's own
fixtures can be careful enough to make the bug unreachable.

Six more followed — `scene-transition`, `combo-system`, `dialogue-box`,
`cooldown-shoot` and `dash-ability` — and `combo-system` is the one that
mattered. It advertised seven combos and could perform four: pressing L, L fires
Double Cut on the second press and cleared the history, so the third L started
from nothing and Triple Slash, Spin Attack and Ground Slam were unreachable. Its
suite could not have found that, because `_check_sequence()` was a copy of the
demo's `_check()` that matched against a list handed to it and never cleared
anything — it agreed about which combos existed and disagreed about which could
be performed.

One survivor recurred across four demos and looks unreachable:
`Input.is_action_just_pressed("ui_up") and is_on_floor()`. The input cannot be
pressed headless — but the other half of the condition can be held from the
outside, because loosening the `and` to an `or` launches the player on every
grounded frame. "With nothing pressed, a player on the floor stays on it" killed
it in all four.

The smoke gate carries the demos whose output is genuinely pixels or sound. It
now fails on engine warnings, which is how a refused operation — a shader
parameter that never took effect, a viewport size the container owns —
announces itself. Some needed only a rewritten suite because the component
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

## The measurement has to be taken the same way twice

`--limit` decides how many mutations each demo contributes. A demo with forty
candidates and one with two are weighted differently at 4 than at 5, so two runs
at different limits are measurements of different populations — not the same
thing twice.

CI checked at `--limit 4` against a floor recorded at the default 5 and reported
a 2.2-point fall that no suite had caused. The ceiling gives it away: at the
commit where the floor was recorded, the most a `--limit 5` run could attempt
was 664 mutations, which is exactly the `tried` in the baseline, and the most a
`--limit 4` run could attempt was 552.

The baseline records its `limit` and `seed` now, and `--check` refuses to
compare across different ones rather than reporting a fall.

`docs/GAPS.md` lists demo-shaped gaps; this is the test-shaped one, and it is
the larger pile of work.
