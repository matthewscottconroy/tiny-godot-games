# Tool Script

`@tool`: a layout helper that arranges its children in the editor, before the game ever runs.

## Purpose

Most of the time you spend on a game is spent in the editor, and most of that is arranging things. A `@tool` script runs inside the editor as well as at runtime, which turns "drag twenty objects into a circle" into "type 20 and see it".

The reason people avoid `@tool` is that it is easy to get wrong in ways that are loud and confusing: editor runs have no game state, so a script that assumes one fills the Inspector with errors, and a script with side effects can corrupt a scene you have not saved. Two habits make it safe. Guard anything with side effects behind `Engine.is_editor_hint()`, and keep the actual work a pure function of the exported values, so re-running it is always harmless.

That second habit has a useful side effect: the pure function is testable without an editor at all, which is how this demo's layout maths is covered by the headless suite.

## Controls

The real point of this demo is the **editor**: open `scenes/main.tscn`, select the `Ring` node, and drag `count` or `radius` in the Inspector — the children rearrange with the game not running.

At runtime the same values are driven from the keyboard:

| Key | Action |
|-----|--------|
| 1 / 2 | Fewer / more children |
| 3 / 4 | Smaller / larger radius |
| 5 / 6 | Narrower / wider arc |
| R | Rotate the ring |
| F | Toggle facing outward |

## How It Works

**`@tool` on line 1.** That single annotation is what makes the script run in the editor. Without it, everything below happens only when you press play.

**Exported setters re-apply.** Each `@export` uses a setter that calls `_apply()`, so changing a value in the Inspector immediately repositions the children. This is what makes it feel like a tool rather than a script.

**The maths is static and pure.** `positions_for(count, radius, start_angle, arc)` takes no node references and touches nothing. It handles the detail that catches people out: a full ring wraps, so the last slot must not land on the first, while a partial arc does not wrap and should occupy both ends.

**Editor-only drawing is guarded.** `_draw()` returns early unless `Engine.is_editor_hint()`, so the guide ring is a design aid that never appears in the game.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `@tool` | Run this script in the editor as well as at runtime |
| `Engine.is_editor_hint()` | Distinguish an editor run from a game run |
| `@export var x: set(value):` | Inspector values that re-run the layout when changed |
| `@export_range(min, max)` | A slider instead of a free-text field |
| `Vector2.from_angle()` | Placing a point at an angle |
| `is_inside_tree()` | Guard against running before the node is ready |

## Key Constants

| Property | Default | Meaning |
|----------|---------|---------|
| `radius` | 120 | Distance from the centre |
| `count` | 8 | Slots around the ring |
| `arc` | 1.0 | Fraction of a full turn to spread across |

## Files

| File | What it holds |
|------|---------------|
| `scripts/ring_layout.gd` | The `RingLayout` `@tool` node: exports, `_apply()`, and the pure layout maths |
| `scripts/main.gd` | Demo driver: runtime keyboard control and child spawning |
| `scripts/marker.gd` | A trivial child so the facing rotation is visible |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite for the static layout functions |

## Use as a building block

**Copy:** `scripts/ring_layout.gd` — the `RingLayout` type. `scripts/main.gd` and `scripts/marker.gd` are the demo driver and are not needed.

**Public API**
- `@export radius: float`, `count: int`, `start_angle: float`, `arc: float`, `face_outward: bool`
- `static positions_for(count, radius, start_angle_deg, arc_fraction) -> PackedVector2Array`
- `static rotations_for(count, start_angle_deg, arc_fraction) -> PackedFloat32Array`
- `_apply()` — reposition the children; safe to call repeatedly.

**Integrate**
1. Add a `RingLayout` node, drop children under it, and set the exports. Spawn points, pickups, and radial UI are the obvious uses.
2. For your own tool scripts, copy the structure rather than the maths: `@tool` at the top, setters that re-apply, the real work in a static pure function, side effects behind `Engine.is_editor_hint()`.

**Notes**
- `class_name RingLayout` is global to the project — rename it if you already define that type.
- A `@tool` script's `_ready()` runs in the editor too. Anything that assumes a running game — autoloads, save files, input — must be guarded.
- Editing a `@tool` script re-runs it immediately. If it can corrupt your scene, it will do so before you have saved; keeping the work idempotent is the protection.
- See [editor-plugin](../editor-plugin) for the next step: docks, custom node types, and tools that act on the scene you have open.
- No project settings, autoloads, or input actions are required.

## Related demos

- [editor-plugin](../editor-plugin) — An `EditorPlugin` adding a dock and a custom node type, with symmetric teardown.
- [procedural-animation](../procedural-animation) — FABRIK inverse kinematics on an 8-joint chain following the mouse.
- [boid-flocking](../boid-flocking) — 35 agents flock via separation, alignment, and cohesion — emergent behavior.
- [homing-projectile](../homing-projectile) — A missile that steers toward a moving target with `lerp_angle`.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

