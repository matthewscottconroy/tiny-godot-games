# Export Vars

<!-- tags: good-first-demo -->

Demonstrates `@export` variables — how to expose script properties to the Godot Inspector and make them editable without touching code.

## Purpose

`@export` is one of the first GDScript features a Godot developer needs. It bridges the gap between programmer and designer: the programmer defines what properties exist and how they are used; the designer tunes them in the Inspector without opening a script. This demo uses a single bouncing ball with four exported properties that each visibly affect behavior.

## Controls

- No player controls — the ball bounces automatically
- Edit `color`, `radius`, `velocity`, and `label_text` in the Godot Inspector to see instant changes

## How It Works

### Node Tree

```
Ball (Node2D)   ← ball.gd  (the only node in the scene)
```

### `scripts/ball.gd`

```gdscript
extends Node2D

@export var color: Color     = Color.WHITE
@export var radius: float    = 20.0
@export var velocity: Vector2 = Vector2(120, 90)
@export var label_text: String = "Ball"

var _vel: Vector2  # runtime copy of velocity

func _ready() -> void:
    _vel = velocity   # copy the exported value as the live velocity
    queue_redraw()

func _process(delta: float) -> void:
    position += _vel * delta
    # Bounce off viewport edges
    var vp := get_viewport_rect()
    if position.x - radius < 0 or position.x + radius > vp.size.x:
        _vel.x *= -1
        position.x = clampf(position.x, radius, vp.size.x - radius)
    if position.y - radius < 40 or position.y + radius > vp.size.y - 30:
        _vel.y *= -1
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, radius, color)
    draw_arc(Vector2.ZERO, radius, 0, TAU, 48, color.darkened(0.3), 2.0)
    draw_string(ThemeDB.fallback_font, ..., label_text, ...)
```

**Why `_vel` instead of using `velocity` directly?**

`velocity` is the exported value — it is what appears in the Inspector. If the ball modified `velocity.x *= -1` during a bounce, the Inspector value would change permanently. Instead, `_vel` is a runtime copy initialized from `velocity` in `_ready()`. The exported variable stays as the designer set it; the live variable does the runtime bouncing.

## @export Theory

### What @export Does

`@export` marks a variable for serialization and Inspector display. Godot:
1. Displays the variable in the Inspector with an appropriate editor widget (Color picker, float slider, Vector2 fields, etc.)
2. Serializes the value into the scene file (`.tscn`) so it persists
3. Makes the value available in `_ready()` (exported values are set before `_ready()` runs)

Without `@export`, the variable only exists at runtime with its default value.

### Supported Export Types

Godot automatically creates appropriate Inspector widgets for:
- `bool` → checkbox
- `int`, `float` → number field (add `@export_range(min, max)` for a slider)
- `String` → text field
- `Vector2`, `Vector3` → multi-field editors
- `Color` → color picker with alpha
- `PackedScene` → drag-and-drop scene reference
- `Resource` subtypes → resource pickers

### Inspector vs Default Value

The default value in code (`= Color.WHITE`) is a fallback. Once you change the property in the Inspector, the `.tscn` file stores your overridden value and uses it instead of the code default. This is how Godot enables per-instance customization from a shared script.

### @export_range and Hints

```gdscript
@export_range(1.0, 100.0, 0.5) var radius: float = 20.0
```

Export hints constrain the Inspector widget. `@export_range` shows a slider from 1 to 100 with 0.5 steps. Other hints: `@export_file`, `@export_enum`, `@export_flags`, `@export_group`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `@export var x: T = default` | Expose variable to Inspector |
| `@export_range(min, max, step)` | Slider hint |
| `get_viewport_rect()` | Current viewport rectangle |
| `clampf(value, min, max)` | Float clamp |
| `color.darkened(amount)` | Darken a color by a fraction |
| `ThemeDB.fallback_font` | Default font resource for draw_string |
| `draw_string(font, pos, text, ...)` | Draw text in _draw() |

## Files

| File | What it holds |
|------|---------------|
| `scripts/ball.gd` | `ball` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/ball.gd`.

**`scripts/ball.gd`**
- `@export color: Color`
- `@export radius: float`
- `@export velocity: Vector2`
- `@export label_text: String`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

## Related demos

- [area-trigger](../area-trigger) — `Area2D` invisible trigger zones firing signals on body enter/exit.
- [arrow-sprite](../arrow-sprite) — Basic 2D movement with arrow keys, normalized direction, frame-rate-independent motion.
- [autoload-score](../autoload-score) — The Autoload/Singleton pattern: global state that emits change signals.
- [coin-collector](../coin-collector) — Scene instancing, custom signals, and `Area2D` pickups for a collect-all goal.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

