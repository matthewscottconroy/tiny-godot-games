# Input Recording

Capturing input per frame and replaying it deterministically — for attract modes, ghosts, and reproducing the bug you just hit.

## Purpose

Recording *positions* gives you a video. Recording *input* gives you a cause you can re-run, and it is dramatically smaller: a few booleans per frame instead of a transform. Re-running it through the same simulation reproduces the original exactly.

That one property underpins several things games want. Attract-mode demos are a recording played back. Racing ghosts are a recording rendered alongside you. Most valuably, a bug report that includes an input recording is a bug you can reproduce on demand instead of one you try to guess at — and the same recording becomes a regression test.

The catch is that determinism is a property of your whole simulation, not of the recorder. Replay only reproduces the original run if the simulation is fed a fixed timestep and uses a seeded RNG. Anything reading wall-clock time or unseeded randomness will drift, and this demo shows where that discipline has to live.

## Controls

| Key | Action |
|-----|--------|
| Arrow keys | Move the square |
| R | Start recording (resets position and trail) |
| P | Replay the recording |
| S | Stop |

## How It Works

**Each frame is a set of held actions.** `record_frame(state)` stores one dictionary per frame containing only the tracked actions. Anything outside the tracked list is discarded, which keeps recordings small and stable across input-map changes.

**`poll()` is the single call site.** During replay it returns the recorded frame; while recording it stores the live state and passes it through; while idle it just passes through. The game reads input from one place and does not branch on mode.

**Replay is fixed-step.** The demo integrates with a `STEP` constant rather than `delta`. This is the part people miss — a replay fed variable frame timing accumulates a different result and drifts away from the original run.

**Recordings serialise.** `to_dict()` stores each frame as the list of actions held, which compresses well because most frames hold nothing, and drops straight into JSON.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.is_action_pressed()` | Sampling live input for a frame |
| `PackedStringArray` | The tracked action list |
| `Dictionary.duplicate()` | Handing back a frame the caller cannot mutate |
| `Array.pop_front()` / indexing | Walking the recording during replay |
| `signal replay_finished` | Knowing when playback ran out |
| Fixed `STEP` instead of `delta` | The determinism requirement |

## Files

| File | What it holds |
|------|---------------|
| `scripts/input_recorder.gd` | The `InputRecorder` component: capture, replay, serialisation |
| `scripts/main.gd` | Demo driver: a fixed-step square, live trail and recorded trail |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite, including that replaying twice produces an identical path |

## Use as a building block

**Copy:** `scripts/input_recorder.gd` — the `InputRecorder` type. `scripts/main.gd` is the demo driver and is not needed.

**Public API**
- `_init(tracked_actions: PackedStringArray)`
- `start_recording()` / `start_replay()` / `stop()`
- `poll(live_state) -> Dictionary` — the one call your game needs.
- `record_from_input()` — sample `Input` directly.
- `next_frame() -> Dictionary`, `frame_count()`, `current_frame()`
- `to_dict()` / `from_dict()`
- signal `replay_finished`

**Integrate**
1. Route all gameplay input through `poll()` — if any system reads `Input` directly, replay will not reproduce it.
2. Drive the simulation from a fixed step (`_physics_process` with a constant, not `delta`).
3. Seed every RNG you use and record the seed alongside the input, or replays will diverge the first time something random happens.
4. To turn a recording into a regression test, save the dictionary as a fixture and assert on the final state.

**Notes**
- `class_name InputRecorder` is global to the project — rename it if you already define that type.
- Recording only captures the actions you list. Adding an action later invalidates older recordings, so version them the way [save-migration](../save-migration) versions saves.
- Analogue input (sticks, triggers) needs float values rather than booleans; the frame dictionary already holds Variants, so widening it is a small change.
- No project settings are required; the demo uses the built-in `ui_*` actions.
