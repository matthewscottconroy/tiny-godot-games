# Path Follow

Demonstrates `PathFollow2D` for smooth curve-following movement: an object that travels along a predefined `Path2D` curve at a constant speed.

## Purpose

Many game patterns require objects to follow a fixed path: patrol routes, tower defense enemy waves, cutscene camera movement, conveyor belts, and fairground attractions. `PathFollow2D` provides this out of the box — you define the curve in the editor, attach a `PathFollow2D` child, and the node's position and rotation track the curve automatically as you update `progress`.

## Controls

- **Arrow keys / WASD**: Move the player (background reference)
- The red patrol object follows its looping curve automatically
- Watch the white line showing the direction of travel

## How It Works

### Node Tree

```
Main (Node2D)
├── PatrolPath (Path2D)           (curve defined in editor)
│   └── PatrolBody (PathFollow2D)  ← patrol.gd
├── Player (CharacterBody2D)      ← player.gd
└── (background geometry via _draw())
```

### `scripts/patrol.gd`

```gdscript
extends PathFollow2D

@export var speed: float = 120.0

func _process(delta: float) -> void:
    progress += speed * delta
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, 16, Color.TOMATO)
    draw_arc(Vector2.ZERO, 16, 0, TAU, 32, Color(0.7, 0.1, 0.1), 2.0)
    draw_line(Vector2.ZERO, Vector2(16, 0), Color.WHITE, 2.0)
```

That is essentially the entire script. `progress += speed * delta` is the key line: `progress` is the distance along the curve in pixels. Adding `speed * delta` moves the follower forward at the given rate. When `progress` exceeds the curve's total length, `PathFollow2D` wraps it back to 0 if `loop = true` (the default).

The white line at `Vector2(16, 0)` (local +X direction) shows which way the node is facing. Because `PathFollow2D.rotation_mode = ROTATE` by default, the node rotates to align with the curve tangent, so local +X always points "forward" along the path.

## PathFollow2D Theory

### Path2D and Curves

`Path2D` stores a `Curve2D` — a Bézier curve defined by control points. Each point has an in and out handle that controls the tangent. Straight segments use collinear handles; smooth curves use angled handles.

The curve's total length is `path.curve.get_baked_length()`. PathFollow2D uses a baked (sampled) version of the curve for efficient position lookup.

### progress vs progress_ratio

- `progress` — distance along the curve in world units (pixels)
- `progress_ratio` — normalized 0.0 to 1.0 (0 = start, 1 = end)

Both can be set. Using `progress_ratio` is easier for timing (e.g. move from 0 to 1 over exactly 5 seconds). Using `progress` with `speed` in pixels/second gives more intuitive speed control.

### rotation_mode

`PathFollow2D.rotation_mode` controls how the node's rotation relates to the curve:
- `ROTATE` (default) — node rotates to match the curve tangent
- `NONE` — node does not rotate (position only)
- `Y` — only Y-axis rotation (for 3D equivalents)

`ROTATE` is ideal for vehicles, enemies, cameras — anything that should face its direction of travel.

### Looping

`PathFollow2D.loop = true` (default) wraps `progress` back to 0 after the curve end. `loop = false` clamps at the end. For patrol patterns, looping is usually correct. For one-time paths (a cutscene camera move), `loop = false` combined with a check for `progress_ratio >= 1.0` allows triggering an event at the path's end.

### Multiple Followers

Multiple `PathFollow2D` nodes can be children of the same `Path2D`. They all follow the same curve independently. This is useful for enemies in a convoy, cars on a track, or pearls on a string — place them at different initial `progress` offsets.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Path2D` | Holds a `Curve2D` defining the path |
| `PathFollow2D` | Child of Path2D that follows the curve |
| `PathFollow2D.progress` | Distance along the curve in pixels |
| `PathFollow2D.progress_ratio` | Normalized 0–1 position along curve |
| `PathFollow2D.loop` | Whether to wrap at the end |
| `PathFollow2D.rotation_mode` | How to rotate relative to the curve |
| `Curve2D.get_baked_length()` | Total curve length in pixels |
