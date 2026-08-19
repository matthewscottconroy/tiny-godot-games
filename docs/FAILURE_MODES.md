# Failure modes

Every demo in this repo was written to work, reviewed, and shipped. Then each
one's test suite was rewritten to drive the demo's real code instead of a
reimplementation of its logic, and that turned up roughly twenty bugs — several
of them the demo's entire point.

This is the catalogue. Not "here are the bugs we fixed", which is what `git log`
is for, but **the shapes they came in**: how each one stayed invisible, and what
now catches it. The shapes are not specific to this repo. If you write Godot,
you have some of these.

Each entry names real instances. Follow a commit hash for the full story.

See also [TEST_INTEGRITY.md](TEST_INTEGRITY.md), which covers how the suites are
measured, and [MEMORY.md](MEMORY.md), for the leak-shaped failures.

---

## 1. The engine refused, and said so in a warning

**Shape.** You set a property, call a method, or reference a resource. The engine
declines — because something else owns that value, because the target does not
exist, because the API is deprecated. It does not raise. It prints a *warning*,
and warnings scroll past.

The line looks like it worked. The feature is missing.

**Instances.**

- `pixel-art-camera` set `_subviewport.size` directly, but a `SubViewportContainer`
  with stretch enabled owns its viewport's size. Refused, with a warning, on every
  toggle. Both "pixel" and "smooth" modes rendered identically — the demo's whole
  effect was absent. `stretch_shrink` is the supported control. (`f673cb0`)
- `audio-bus-effects` offered four buses and created three. Assigning a player to
  a bus that does not exist is *silently* ignored, so picking "Dry" left it on
  Master — which happens to sound right, since Master carries no effects, while
  the readout named a bus that was not there. (`94dae9f`)
- `parallax-scroll`, `raycasting` and `tilemap-room` carried stale `ext_resource`
  UIDs. Godot fell back to the text path and warned. Working today, broken the
  moment a file moves. (`e0793d5`)

**Why it hides.** A warning is not a failure to any test runner that only checks
the exit code, and Godot's console is chatty enough that nobody reads it all.

**What catches it now.** `run-tests.sh` fails on any `WARNING:` line. Exactly one
warning is allowed through — the engine-side audio-shutdown leak documented in
[MEMORY.md](MEMORY.md) — and it is matched by an explicit pattern, not by a
"probably fine" heuristic.

---

## 2. The function that quit early and told nobody

**Shape.** A GDScript runtime error abandons the enclosing function and returns
`null`. Execution continues in the caller. Everything after the error line in
that function simply never happens.

In a demo, half a handler goes missing. In a *test*, the assertions after the
error never run — so the suite prints a smaller `n/n passed`, the counts still
agree, and it is indistinguishable from success.

**Instances.**

- `event-bus` and `pause-menu` both called `event.is_action_just_pressed()`.
  `InputEvent` has no such method — the `just` variants live on the `Input`
  singleton. The error aborted the handler before anything else ran, so
  event-bus's damage and heal keys did nothing and pause-menu's Esc never opened
  the menu. (`dcff429`)
- `dash-ability`, `spread-shot`, `top-down-controller` and `ledge-grab` wrote to
  a HUD label without checking it exists, which abandoned the rest of the method
  whenever the script was driven outside its scene. (`08f418e`)
- Five suites written *during this work* did it too: four read from a scene a
  later `_make()` had freed, and `screen-flash` called an awaiting test without
  `await`, so the test resumed after two more tests had run and freed its scene
  out from under it. (`08f418e`)

**Why it hides.** The suite still exits zero, and its own pass count is
self-consistent. There is no output that says "and then it stopped".

**What catches it now.** `run-tests.sh` matches the abort-class errors —
`previously freed`, `Invalid access to property`, `Nonexistent function`,
`Invalid index`, `null instance`, and their relatives — and fails the suite.
`tools/check_docs.py` rejects `event.is_action_just_*` specifically, since that
one is an easy thing to type and always wrong.

---

## 3. The test that reimplemented the demo

**Shape.** The suite computes the expected answer with its own copy of the
formula, then checks the demo agrees. When the two disagree the test is the one
consulted, so the demo can be wrong indefinitely — and the more careful the test
looks, the more thoroughly it certifies the bug.

**Instances.**

- `wall-jump` launched the player **into** the wall. It negated
  `get_wall_normal()`, which already points away. The suite recomputed the launch
  inline with its own sign convention, so the demo and its test disagreed and only
  the test was consulted. The bug was original, from the demo's first commit.
  (`80e32ef`)
- `bezier-path` checked the curve against itself rather than against the cubic
  worked out by hand. (`3525f7b`)

**Why it hides.** This is the failure mode that a passing test suite is *worst*
at revealing, because the suite is the thing that is broken. It cannot be found
by running the tests. It can only be found by asking what the tests actually
touch.

**What catches it now.** Every suite drives the demo's real code — that was the
point of the whole conversion — and `tools/mutate.py` measures it: break a line
of the demo, and if no test notices, that line is untested regardless of how many
assertions surround it. The floor is ratcheted in `docs/mutation-baseline.json`.

---

## 4. Wiring that connected nothing

**Shape.** A signal connection, a group lookup, a parent reference. Each resolves
to *something* — an empty list, the wrong node, no node — so nothing errors. The
mechanic is simply absent.

**Instances.**

- `camera-rooms`, `checkpoint-system` and `screen-flash` declared group membership
  as a `groups = PackedStringArray("...")` property line. Godot reads groups from
  the **node header** — `[node ... groups=["room"]]` — so the property was ignored
  and the nodes joined no group at all. camera-rooms was the worst of it: `main.gd`
  connects to every node in the `room` group, found none, and the camera never
  moved between rooms. The demo's whole mechanic was dead. (`99fab2f`)
- `drag-drop`'s `drop_zone.gd` called `get_parent().on_drop()`, but a zone's parent
  is the `Zones` grouping node, not the scene root. Dropping an item raised an
  error and the "Filled: n / 3" readout never moved. `owner.on_drop()` is what it
  meant. (`3525f7b`)

**Why it hides.** `get_nodes_in_group()` returning `[]` is a legitimate state, not
an error. A demo with a dead mechanic still opens, still draws, and still responds
to everything else.

**What catches it now.** `tools/check_docs.py` rejects group membership written as
a scene property. The rest is caught by suites that drive the real scene: if the
camera is supposed to move between rooms, a test moves the player and asserts the
camera moved.

---

## 5. The feature that was never built

**Shape.** The demo is named after a thing it does not do. The README explains the
concept correctly. The scene contains everything except the concept.

**Instances.**

- `light-shadow` cast no shadows. Neither light had `shadow_enabled`, and there
  was not a single `LightOccluder2D` in the scene. The walls were drawn straight
  onto the floor and lit as if they were paint. Its README was titled "Light and
  Shadow" and its body never mentioned either half of what makes one. (`7c035cf`)

**Why it hides.** Nothing is broken. The demo runs, looks plausible, and the
missing thing is missing — there is no error for an absence. A reviewer reading
the README and glancing at the window sees a lit scene and moves on.

**What catches it now.** The suite asserts the mechanism, not the appearance:
both halves must be present (`shadow_enabled` *and* an occluder — either alone
casts nothing), and each occluder must cover the wall it stands for, so a shadow
cannot disagree with what is drawn.

---

## 6. Rounding that goes the wrong way at zero

**Shape.** `int()` truncates *towards zero*, so it rounds down above zero and up
below it. Every grid, tile lookup and cell index built with it has a seam at the
origin that is one cell wide and behaves differently from every other seam.

**Instances.**

- `music-sequencer` found the cell under the cursor with `int()`. A click up to a
  cell's width *left* of the grid gave column 0, and one above it gave the top
  row. Clicking beside the pattern toggled the edge of it. `floori()` rounds the
  way the grid is laid out. (`179149e`)

**Why it hides.** It is correct everywhere except one strip at each axis, and the
strip is off-screen or ignored in casual use.

**What catches it now.** Suites drive grid lookups with negative coordinates
specifically, because that is the only place the two functions differ.

---

## 7. Recalled instead of measured

**Shape.** You write the code from what you remember the API doing. The memory is
plausible, adjacent to true, and wrong in one detail. This is the most common
mode on this list and the least visible, because plausible code reviews well.

**Instances.**

- The `wall-jump` sign, above — `get_wall_normal()` points away from the wall, not
  into it. The sibling `ledge-grab` demo got it right, using `normal.x` directly.
  Verified empirically before fixing: a body pressed against a wall on its right
  reports normal `(-1, 0)`. (`80e32ef`)
- Replacing the deprecated `make_polygons_from_outlines()` in `navigation-agent`,
  every outline was handed to the baker as **traversable** — including the
  obstacle holes. That baked one big walkable rectangle, the agent's path became a
  straight line through the blocks, and the demo's point was gone. Obstacles are
  *obstruction* outlines. (`0d01cc8`)

The second one is worth dwelling on: the suite shipped alongside that change and
did not catch it, because a straight two-point path has no point inside a block.
A test derived from the same wrong assumption as the code confirms the
assumption. It now checks the baked mesh corner by corner rather than one route.

**Why it hides.** Nothing about wrong-but-plausible looks wrong. It compiles, it
runs, it produces output of the right shape.

**What catches it now.** Nothing automatic — this one is a working habit. When a
sign, an axis direction, a units convention or an attenuation curve matters,
print it from the running engine before relying on it.
[TEST_INTEGRITY.md § Deriving your inputs from the code under test](TEST_INTEGRITY.md#deriving-your-inputs-from-the-code-under-test)
is the longer version.

---

## 8. The harness is not the demo's world

**Shape.** The test environment differs from the running game in a way that makes
a correct test fail, or — worse — makes an incorrect test pass.

**Instances and rules.**

- **Headless renders at 64×64**, not the project's window size. Anything that
  derives from viewport size has no room to work. `get_window().size = Vector2i(640, 480)`
  is honoured even headless, and `pixel-art-camera`'s suite has to do it before
  the container can size its viewport — at 64×64 there is no resolution to divide.
- **Nothing moves without a physics step.** `move_and_slide()` and
  `apply_central_impulse()` hand work to the physics server; the body's position
  is unchanged until the server runs. A test that sets velocity and reads position
  on the next line reads the old position.
- **`travel()` is a request, not a transition.** `AnimationNodeStateMachinePlayback`
  processes it on the tree's own frame.
- **Physics keeps re-announcing overlaps.** `camera-rooms`' rooms are `Area2D`s,
  and the engine re-emits for whichever one the player is actually standing in —
  so a test has to *move the player* as well as emit the signal, or the engine
  overrules it a frame later.

**What catches it now.** These are written down in
[TEST_INTEGRITY.md § Watching a scene play out](TEST_INTEGRITY.md#watching-a-scene-play-out),
and `tests/frames` lets a demo that needs more settling time ask for it — both
`run-tests.sh` and `tools/mutate.py` read it.

---

## 9. State that survived the test that set it

**Shape.** A suite-level variable outlives the test that touched it, so one
failure or one leftover object contaminates everything after.

**Instances.**

- Nine suites shared a `_quiet_failures` counter that was never reset between
  tests. The first per-item failure made every later summary assertion fail too,
  which buries the real cause under a wall of consequences. They now zero it at
  the start of each test via `begin_quiet()`. (`f00fef6`)
- Four suites held a reference into a scene that a later `_make()` had freed — the
  abort in mode 2, with a lifetime bug as its cause. (`08f418e`)

**Why it hides.** The suite fails loudly, so nobody calls it hidden — but it
fails in the wrong place, and the time goes into the wrong test.

---

## 10. The measurement had a blind spot

**Shape.** The tool that tells you how well you are doing is itself wrong, in the
direction that flatters you.

`tools/mutate.py` breaks one line of a demo at a time and checks whether the
suite notices. Five separate things made its number mean less than it looked:

- It counted mutations inside `_draw()` bodies, which no headless test can see —
  free "survivors" that no suite could ever kill.
- It mutated prose inside triple-quoted blocks and trailing `#` comments, scoring
  a suite for not noticing that a comment changed.
- A mutant that made the demo **hang** was scored as a survivor, because the
  harness blocked reading its output forever. A hang is a mutant *caught*: there
  is now a watchdog, and a killed process counts as a kill.
- It missed suites that drive the demo by loading its main scene, so those demos
  were excluded from the count entirely.

**What catches it now.** All five are fixed, and the effect was large enough to
matter: the floor moved from 20.3% to 78.0% across the conversion work, and part
of that was the measurement finally measuring the right lines.

---

## 11. The tool left its own damage behind

**Shape.** A tool that edits your working tree, interrupted.

**Instance.** `quadtree`'s `subdivide()` gave its first child `depth - 1` instead
of `depth + 1`, so that quadrant's depth decreased on every subdivision,
`depth < MAX_DEPTH` stayed true forever, and `insert()` recursed without bound.

It was not an original bug. It was a mutation that `tools/mutate.py` applied, that
an interrupted run never restored, and that a blanket `git add -A` swept up.

It was also the root cause of a run of out-of-memory crashes: infinite recursion
emits a stack trace per frame, bash buffered that unbounded output in a command
substitution, and the shell reached 40GB. Every full-suite run after that commit
was hitting it. (`c932716`)

**What catches it now.** `mutate.py` journals every mutation before applying it,
so an interrupted run is repaired rather than silently left on disk, and
`mem_capture` bounds the output side so runaway output cannot eat the machine.
Commits during a mutation run are staged file by file, never `-A`.

---

## The pattern behind the patterns

Ten of the eleven modes share one property: **nothing reports an error.**

A refused assignment warns. An aborted function returns `null`. An empty group is
a valid group. A missing occluder is an absence. A wrong sign is a number. The
only signal available is the difference between what the code *should* do and
what it *does*, and the only way to get at that difference is to run the real
code and check the real result.

That is the whole argument for the conversion this repo went through, and it is
why the gates added along the way — the warning gate, the abort gate, the mutation
ratchet, the doc checks — are all shaped the same way: they turn a silence into a
failure.
