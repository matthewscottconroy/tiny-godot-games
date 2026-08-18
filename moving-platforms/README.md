# Moving Platforms

<!-- tags: physics -->

Sinusoidally-oscillating platforms that correctly carry the player, implemented with `StaticBody2D.constant_linear_velocity` to communicate platform motion to Godot's physics engine.

## Purpose

Moving platforms are one of the earliest platform-game mechanics — they appear in *Donkey Kong* (1981) and have been a staple ever since. Beyond nostalgia, they serve a concrete design function: they create time pressure and force the player to predict motion, turning a static floor into an active obstacle. Games like *Celeste* and *Hollow Knight* use moving platforms to add rhythm and coordination challenges without introducing enemies.

The implementation has a subtle requirement that trips up many beginners: simply changing a `StaticBody2D`'s position each frame is not enough. `CharacterBody2D.move_and_slide()` needs to know how fast the floor is moving to carry the player correctly. Without `constant_linear_velocity`, the player stands on the platform but the platform slides out from under them — they slide off as if on ice. Setting `constant_linear_velocity` to the platform's actual velocity per frame tells `move_and_slide()` to add that velocity to the character when floor contact is detected.

The sinusoidal formula produces smooth, continuous oscillation with zero velocity at the endpoints and maximum velocity at the midpoint — the same profile as a physical pendulum, which makes the motion feel natural.

## How It Works

### Node Tree

```
Main (Node2D)                     ← main.gd (floor only)
├── Player (CharacterBody2D)      ← player.gd
├── PlatformVertical (StaticBody2D) ← moving_platform.gd
├── PlatformHorizontal (StaticBody2D)
└── PlatformDiagonal (StaticBody2D)
```

All three platforms share one script. The `@export` variables make each instance unique.

### Platform Script (`scripts/moving_platform.gd`)

```gdscript
@export var amplitude:  float   = 80.0
@export var period:     float   = 2.5
@export var axis:       Vector2 = Vector2(0.0, 1.0)
@export var draw_size:  Vector2 = Vector2(120.0, 14.0)

var _origin:  Vector2
var _elapsed: float = 0.0

func _ready() -> void:
    _origin = position

func _physics_process(delta: float) -> void:
    _elapsed += delta
    var prev   := position
    var offset := axis.normalized() * sin(_elapsed * TAU / period) * amplitude
    position                 = _origin + offset
    constant_linear_velocity = (position - prev) / delta
```

`_origin` is the rest position set in the editor. Each frame, position is computed from scratch using `sin`, then `constant_linear_velocity` is derived as the actual position delta divided by delta time — the numerical velocity.

### Why Numerical Velocity Instead of Analytical Derivative

The analytical derivative of `sin(t * TAU / period) * amplitude` with respect to time is `cos(t * TAU / period) * amplitude * TAU / period`. That formula is also correct, but the numerical approach `(position - prev) / delta` has two advantages:

1. It stays correct automatically if `amplitude`, `period`, or `axis` change at runtime (for dynamic platforms).
2. It matches exactly what the physics engine will see, avoiding any floating-point discrepancy between the declared velocity and the actual displacement.

### Platform Configurations

| Instance | `axis` | `amplitude` | `period` |
|----------|--------|-------------|----------|
| Vertical | `(0, 1)` | 80 px | 2.2 s |
| Horizontal | `(1, 0)` | 100 px | 3.0 s |
| Diagonal | `(1, −1)` | 55 px | 2.8 s |

`axis.normalized()` ensures the diagonal platform travels at the same amplitude as the others regardless of its vector length.

## The `constant_linear_velocity` Mechanism

When `move_and_slide()` detects that the character is on the floor, it reads `floor_body.constant_linear_velocity` and adds it to the character's effective velocity for that frame. This is not a force — it is a direct velocity addition that makes the character co-move with the platform.

For a horizontal platform moving at 150 px/s to the right:
- Without `constant_linear_velocity`: player stands still while platform moves right → player slides off the left edge within one second.
- With `constant_linear_velocity = Vector2(150, 0)`: `move_and_slide()` adds 150 px/s rightward to the character → player rides the platform.

This same mechanism works for conveyor belts, ice blocks, and any floor that should impart velocity to the player.

## How to Adapt This in Your Project

**Waypoint-based platforms:** Replace the `sin` formula with a `Tween` or a path along a `Path2D`. The key requirement stays the same — compute `constant_linear_velocity` from `(new_pos - old_pos) / delta` each frame.

**Triggered motion:** Store a `_moving: bool` flag and only advance `_elapsed` when it is `true`. Connect an `Area2D` trigger to `set(_moving, true)` for platforms that activate when the player approaches.

**Pause mid-travel:** Add a `_pause_timer` that resets `_elapsed` advancement for N seconds when the platform reaches an endpoint (when `sin` crosses zero going upward).

**Multiple axes:** Set `axis = Vector2(1, 0.5).normalized()` in the inspector for a figure-eight or lissajous path by using different periods per axis:
```gdscript
position = _origin + Vector2(sin(_elapsed * TAU / period_x), sin(_elapsed * TAU / period_y)) * amplitude
```

**Carry rotational velocity:** For rotating platforms, use `constant_angular_velocity` in addition to `constant_linear_velocity`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `StaticBody2D.constant_linear_velocity` | Declares floor velocity to `move_and_slide()` riders |
| `sin(t * TAU / period)` | Oscillates between −1 and +1 over `period` seconds |
| `Vector2.normalized()` | Ensures diagonal axis vectors produce correct amplitude |
| `@export var axis: Vector2` | Per-instance direction, editable in the Inspector |
| `_physics_process(delta)` | Runs in sync with the physics engine (use for all physics bodies) |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys | Move |
| Up | Jump |

## Key Constants

```gdscript
# Per-platform @export vars (set in Inspector):
@export var amplitude := 80.0          # half-travel in pixels
@export var period    := 2.5           # seconds for one full oscillation
@export var axis      := Vector2(0, 1) # direction of travel (normalized internally)
@export var draw_size := Vector2(120, 14) # visual size of the platform rectangle

# Player constants (player.gd):
const SPEED    := 200.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0
```

## Files

| File | Purpose |
|------|---------|
| `scripts/moving_platform.gd` | Sinusoidal oscillation, `constant_linear_velocity` update, visual drawing |
| `scripts/player.gd` | Standard platformer movement using `move_and_slide()` |
| `scripts/main.gd` | Static floor geometry |

## Use as a building block

**Copy:** `scripts/moving_platform.gd`, `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/moving_platform.gd`**
- `@export amplitude:  float`
- `@export period:     float`
- `@export axis:       Vector2`
- `@export draw_size:  Vector2`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [camera-follow](../camera-follow) — Attach a `Camera2D` to the player with position smoothing and hard limits.
- [dash-ability](../dash-ability) — Horizontal dash with cooldown, i-frames, and a ghost-image afterimage trail.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

