# Animated Walk

<!-- tags: physics -->

Demonstrates how to create character animations entirely in code using `AnimationPlayer` and `AnimationLibrary`, without relying on the Godot editor's animation timeline or sprite sheets.

## Purpose

Most tutorials create animations by hand-keyframing in the editor. This demo shows the programmatic equivalent — building `Animation` resources at runtime — which is essential for procedurally generated animations, data-driven animation systems, or simply understanding what the editor does under the hood.

## Controls

- **Arrow keys**: Move left and right
- **Up / W**: Jump

## How It Works

### Node Tree

```
Player (CharacterBody2D)  ← player.gd
├── Visual (Node2D)       ← visual.gd  (drawn body, head, eyes)
├── AnimationPlayer
└── CollisionShape2D
```

### `scripts/player.gd`

The `CharacterBody2D` root. Handles physics, animation switching, and sprite flipping.

- **`_setup_animations()`** — Called once in `_ready()`. Creates an `AnimationLibrary`, builds two `Animation` objects, and registers them under the default `""` namespace on the `AnimationPlayer`.
- **`_physics_process()`** — Applies gravity, reads horizontal input, calls `move_and_slide()`, then switches the active animation based on `abs(velocity.x) > 10`.
- **Sprite flip** — `visual.scale.x = -1` mirrors the `Visual` child when moving left. Flipping a child visual node leaves the physics body's orientation and collision shape untouched.

### `scripts/visual.gd`

A plain `Node2D` that draws the character visuals in `_draw()`. Separating the visual subtree from the physics body is a key pattern: you can safely scale, rotate, or flip the visual without affecting hitboxes or movement.

## Animation Theory

### AnimationPlayer + AnimationLibrary

`AnimationPlayer` plays named clips from `AnimationLibrary` objects. Libraries are registered under a namespace string; the empty string `""` is the default namespace, so clips inside it are referenced by name directly (e.g. `"idle"`, `"walk"`).

### Value Tracks

Each `Animation` contains tracks. A **value track** (`Animation.TYPE_VALUE`) interpolates a named property on a NodePath:

```gdscript
var it := idle.add_track(Animation.TYPE_VALUE)
idle.track_set_path(it, "Visual:scale")          # property on the Visual child node
idle.track_insert_key(it, 0.0, Vector2(1.0, 1.0))
idle.track_insert_key(it, 0.6, Vector2(1.04, 0.96))
idle.track_insert_key(it, 1.2, Vector2(1.0, 1.0))
```

Godot interpolates between keys automatically using the track's update mode. `LOOP_LINEAR` repeats the animation forever.

### Idle Animation — Squash & Stretch

A 1.2-second loop that scales `Visual` to 104% wide / 96% tall at the midpoint. This is **squash and stretch**, a foundational animation principle: living things compress and expand slightly even at rest, conveying weight and organic life.

### Walk Animation — Vertical Bob

A 0.32-second loop that shifts `Visual.position.y` between 0 and −6 pixels twice per cycle (two foot-falls per loop). At 160 px/s the character travels ~51 pixels per step, approximating a natural gait rhythm without full skeletal animation.

### State Switching Without Restart

```gdscript
if walking and anim.current_animation != "walk":
    anim.play("walk")
```

Checking `current_animation` before calling `play()` prevents restarting the animation every frame. Without this guard, `play()` would reset the playhead to zero each physics tick, producing a frozen-looking result.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AnimationLibrary.new()` | Container for named `Animation` resources |
| `Animation.add_track(TYPE_VALUE)` | Adds a property-interpolation track |
| `Animation.track_set_path(idx, "Node:prop")` | NodePath to the target property |
| `Animation.track_insert_key(idx, time, value)` | Inserts a keyframe at a given time |
| `Animation.loop_mode = LOOP_LINEAR` | Enables seamless looping |
| `AnimationPlayer.add_animation_library("", lib)` | Registers library under the default namespace |
| `AnimationPlayer.play("name")` | Starts playback of a named clip |
| `AnimationPlayer.current_animation` | Read-only name of the currently active clip |

## Files

| File | What it holds |
|------|---------------|
| `scripts/player.gd` | `player` behaviour |
| `scripts/visual.gd` | `visual` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/player.gd`, `scripts/visual.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [animated-sprite](../animated-sprite) — A sprite sheet generated entirely in code — no image files or imports.
- [area-trigger](../area-trigger) — `Area2D` invisible trigger zones firing signals on body enter/exit.
- [bouncing-ball](../bouncing-ball) — A ball bouncing via Godot's built-in rigid body physics — no manual velocity code.
- [camera-deadzone](../camera-deadzone) — Camera stays still until the player exits a rectangular dead zone, then catches up.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

