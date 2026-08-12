# Top-Down Controller

8-directional free movement with no gravity — the canonical setup for top-down action games. The player moves in any direction; a facing indicator follows the last movement direction even when standing still.

## Purpose

Most 2D game movement falls into two families: side-scrolling (gravity, floor detection, jumping) and top-down (no gravity, free direction). Godot's `CharacterBody2D` defaults to gravity-based platformer physics. This demo shows `MOTION_MODE_FLOATING`, which disables Godot's floor/ceiling/wall concepts entirely, making the character slide freely in all directions like a top-down RPG or twin-stick shooter character.

Top-down movement appears in games like The Legend of Zelda, Hotline Miami, Nuclear Throne, and Enter the Gungeon. The key challenge is diagonal movement: reading four separate key axes and constructing a normalized direction vector. If you skip normalization, diagonal movement is √2 ≈ 1.41× faster than cardinal movement — a common beginner bug that breaks gameplay balance.

A second concern is the facing indicator: it should persist when the player stops moving. Resetting to `Vector2.RIGHT` on stop looks jarring. Storing `_last_dir` and only updating it when `dir != Vector2.ZERO` solves this naturally.

## How It Works

### Node Tree

```
Main (Node2D)                     ← main.gd
└── Player (CharacterBody2D)      ← player.gd
    ├── CollisionShape2D
    └── InfoLabel
```

### `scripts/player.gd`

```gdscript
const SPEED := 200.0

var _last_dir := Vector2.RIGHT

func _ready() -> void:
    motion_mode = MOTION_MODE_FLOATING

func _physics_process(_delta: float) -> void:
    var raw := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var dir := raw.normalized() if raw.length() > 0.001 else Vector2.ZERO
    velocity = dir * SPEED
    if dir != Vector2.ZERO:
        _last_dir = dir
    move_and_slide()
    queue_redraw()
    _label.text = "IDLE" if dir == Vector2.ZERO else "%.0f°" % rad_to_deg(_last_dir.angle())
```

`Input.get_vector` returns a `Vector2` that describes the combined directional input. On keyboard, it returns the difference of the two axes: holding Right = `(1,0)`, holding Down-Right = `(1,1)`. The `(1,1)` case has length `√2`, so `normalized()` brings it back to length 1. The `0.001` threshold guards against near-zero floating-point noise from analog sticks.

### MOTION_MODE_FLOATING

```gdscript
motion_mode = MOTION_MODE_FLOATING
```

This single line changes how `move_and_slide()` works. In the default `MOTION_MODE_GROUNDED` mode, `move_and_slide()` tracks floor, ceiling, and walls — appropriate for platformers. In `FLOATING` mode, no such concepts exist: the character slides along any collision surface without snapping to a floor. This is the correct mode for top-down movement, boat physics, zero-gravity environments, and any 2D game where "up" is not a meaningful concept.

### Facing Indicator (Custom Draw)

The direction line is drawn in `_draw()` rather than by rotating a child sprite. This avoids the rotation affecting the InfoLabel's orientation:

```gdscript
func _draw() -> void:
    draw_circle(Vector2.ZERO, 14, Color.DODGER_BLUE)
    draw_line(Vector2.ZERO, _last_dir * 20.0, Color.WHITE, 3.0)
```

`_last_dir` is a normalized `Vector2`, so `_last_dir * 20.0` places the line tip at a distance of 20 pixels from the center, regardless of direction. `queue_redraw()` is called every physics frame to keep the line current.

### `scripts/main.gd` — Room Layout

The room walls and obstacles are drawn in immediate-mode and matched by invisible `StaticBody2D` collision nodes:

```gdscript
func _draw() -> void:
    var wall_col := Color(0.35, 0.35, 0.4)
    var obs_col  := Color(0.45, 0.28, 0.15)
    draw_rect(Rect2(0,   0,   640, 20),  wall_col)   # top wall
    draw_rect(Rect2(0,   460, 640, 20),  wall_col)   # bottom wall
    draw_rect(Rect2(0,   20,  20,  440), wall_col)   # left wall
    draw_rect(Rect2(620, 20,  20,  440), wall_col)   # right wall
    draw_rect(Rect2(130, 170, 60,  60),  obs_col)    # obstacle 1
    draw_rect(Rect2(420, 280, 80,  40),  obs_col)    # obstacle 2
```

The visual rectangles precisely match the `RectangleShape2D` extents on the `StaticBody2D` collision nodes in the scene — visual and physical geometry must be kept in sync manually when using this approach.

## get_vector vs get_axis

`Input.get_vector(neg_x, pos_x, neg_y, pos_y)` is the idiomatic top-down movement call. It:
- Works with keyboard (discrete 0/1 values) and gamepads (analog -1..1 values)
- Clamps the result to a unit circle on gamepads (preventing diagonal magnitude > 1)
- Handles deadzone logic for analog sticks automatically

The equivalent using `get_axis` would require separate calls and manual normalization:

```gdscript
# Equivalent but more verbose:
var h := Input.get_axis("ui_left", "ui_right")
var v := Input.get_axis("ui_up",   "ui_down")
var raw := Vector2(h, v)
var dir := raw.normalized() if raw.length() > 0.001 else Vector2.ZERO
```

Prefer `get_vector` for 2D directional input.

## How to Adapt This in Your Project

- **8-direction animation**: use `_last_dir.angle()` to select an animation. Divide the 360° circle into 8 sectors of 45° each and map to animation names ("walk_right", "walk_up_right", etc.).
- **Acceleration/deceleration**: replace `velocity = dir * SPEED` with `velocity = velocity.move_toward(dir * SPEED, ACCEL * delta)` for smooth speed ramp-up and friction.
- **Rotation-based aiming**: set `rotation = _last_dir.angle()` to rotate the player sprite toward the last movement direction (or toward the cursor with `global_position.direction_to(get_global_mouse_position())`).
- **Sprinting**: multiply `SPEED` by a sprint factor when a second key is held, or use a stamina system to cap sprint duration.
- **Camera**: add a `Camera2D` child to the player node. Set `Camera2D.limit_*` to the room bounds to prevent the view from going outside the level.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CharacterBody2D.MOTION_MODE_FLOATING` | Disables gravity and floor detection — free 2D movement |
| `CharacterBody2D.motion_mode` | Set to `MOTION_MODE_FLOATING` or `MOTION_MODE_GROUNDED` |
| `Input.get_vector(left, right, up, down)` | Normalized 2D directional input, gamepad-ready |
| `Vector2.normalized()` | Returns unit-length vector; use when diagonal speed must equal cardinal speed |
| `Vector2.length()` | Magnitude of the vector; test `> 0.001` before normalizing |
| `Vector2.angle()` | Angle in radians (-π to π); convert with `rad_to_deg()` |
| `CharacterBody2D.move_and_slide()` | Apply velocity with collision response |
| `CanvasItem._draw()` | Immediate-mode drawing for the player body and direction line |
| `CanvasItem.queue_redraw()` | Schedule `_draw()` update |

## Controls

| Input | Action |
|-------|--------|
| **Arrow keys** | Move in 8 directions |

## Key Constants

```gdscript
const SPEED := 200.0  # pixels per second

# Room bounds:
# walls at x=0, x=620, y=0, y=460 (20px thick)
# obstacles at (130,170) 60×60 and (420,280) 80×40
```

## Files

| File | Purpose |
|------|---------|
| `scripts/player.gd` | Input, `MOTION_MODE_FLOATING`, facing direction, custom draw |
| `scripts/main.gd` | Room walls and obstacles via `_draw()` |
| `scenes/main.tscn` | Room with StaticBody2D walls and Player |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

