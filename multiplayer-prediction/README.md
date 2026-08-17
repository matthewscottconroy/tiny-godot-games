# Multiplayer Prediction

Applying input locally the moment it happens, then correcting when the authoritative server disagrees.

## Purpose

A client that waits for the server to confirm every input feels broken at any real latency — 100ms round trip means every keypress lands a tenth of a second late, and no amount of art disguises it. But letting the client decide its own position means trusting it, which is how you get speedhacks.

Prediction is how both problems get solved at once. The client applies input immediately *and* remembers it, tagged with a sequence number. The server, which remains authoritative, periodically reports "after input #N you were here." The client snaps to that and re-applies every input it has sent since. When the prediction was right — which is almost always — the correction is invisible. When it was wrong, it is a single snap instead of permanent divergence.

The subtle failure is throwing away unconfirmed input during reconciliation. Do that and the player's most recent movement gets rubber-banded away every time a packet arrives, which feels far worse than no prediction at all. That case has a test here.

## Controls

| Key | Action |
|-----|--------|
| Arrow keys | Move |
| [ / ] | Decrease / increase simulated latency |
| W | Toggle a wind force only the server knows about (forces corrections) |
| P | Toggle prediction off, to feel the difference |
| R | Reset |

## How It Works

**One simulation step, shared.** `simulate(state, input, delta)` is a static function used by the client to predict, by the client again to re-simulate, and by the "server". If those three ever diverge, prediction stops working — so there is exactly one of them.

**`predict()` applies and remembers.** It assigns a sequence number, appends the input to a pending list, and advances the state immediately.

**`reconcile(server_state, acked)` is the correction.** It drops every pending input the server has accounted for, takes the server's state as the new base, and re-applies whatever is still in flight. If the result differs from what the client already had by more than `tolerance`, that is a real correction and `reconciled` fires.

**Tolerance exists to avoid churn.** Floating-point noise is not worth a snap, and re-simulating on every packet is wasted work.

**The demo fakes the network in-process.** Inputs go into a delay queue, the server applies them with a wind force the client cannot predict, and its state comes back late. Turning the wind on is what makes corrections visible.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Callable` | The shared simulation step, injected so client and server run identical code |
| `Array.filter()` | Dropping acknowledged inputs from the pending list |
| `Dictionary.duplicate(true)` | Snapshotting state without aliasing |
| `Vector2.distance_to()` | Measuring prediction error |
| `signal reconciled(sequence, error)` | Reporting corrections for a debug overlay |

## Key Constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `tolerance` | 0.01 | Error below this is noise, not a correction |
| `STEP` | 1/60 | Fixed timestep — prediction requires it |

## Files

| File | What it holds |
|------|---------------|
| `scripts/prediction.gd` | The `PredictedState` component: predict, pending inputs, reconcile |
| `scripts/main.gd` | Demo driver: the shared step, a simulated laggy server, adjustable latency |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite, driving the demo's own `simulate()` |

## Use as a building block

**Copy:** `scripts/prediction.gd` — the `PredictedState` type. `scripts/main.gd` is the demo driver and is not needed.

**Public API**
- `_init(simulate: Callable, initial: Dictionary)`
- `predict(input, delta) -> int` — apply now, return the sequence number.
- `reconcile(server_state, acked_sequence) -> bool` — true if a correction was needed.
- `state: Dictionary`, `sequence: int`, `tolerance: float`
- `pending_count() -> int`, `pending_sequences() -> Array`
- signal `reconciled(sequence, error)`

**Integrate**
1. Build on [multiplayer-rpc](../multiplayer-rpc) for the transport. Send each input with its sequence number; have the server reply with its state and the last sequence it applied.
2. Run the simulation from a fixed step and keep it deterministic — same rules as [input-recording](../input-recording).
3. Predict only what the local player controls. Remote players are better interpolated between received states than predicted.
4. Keep the server authoritative over anything that matters. Prediction is a presentation technique; it must never be the source of truth.

**Notes**
- `class_name PredictedState` is global to the project — rename it if you already define that type.
- `_distance()` compares a `pos` field. Widen it if your state has more than position — the error metric decides what counts as a correction.
- Large or frequent corrections mean the client and server simulations disagree, not that the tolerance is wrong. Fix the divergence rather than raising the threshold.
- No project settings are required; the demo uses the built-in `ui_*` actions.

## Related demos

- [multiplayer-rpc](../multiplayer-rpc) — High-level multiplayer over ENet: host/join, a server-authoritative roster, and `@rpc`.
- [arrow-sprite](../arrow-sprite) — Basic 2D movement with arrow keys, normalized direction, frame-rate-independent motion.
- [grapple-hook](../grapple-hook) — Fire a grapple and swing like a pendulum with a custom AABB-vs-circle collision system.
- [input-recording](../input-recording) — Capturing input per frame and replaying it deterministically.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

