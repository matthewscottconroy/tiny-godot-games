# Tween Juice

<!-- tags: ui -->

Demonstrates "game feel" through Tween animations: a button that squishes on press using `TRANS_BACK` easing and spawns a floating score label that drifts upward and fades out.

## Purpose

"Juice" is the game-feel term for small visual flourishes that make interactions satisfying: squishes, bounces, particles, floating text, and screen flashes. These effects do not change gameplay, but they make the game feel alive and responsive. This demo shows two classic juice techniques implemented with Godot's Tween system.

## Controls

- **Click the button**: Triggers the squish animation and spawns a "+10" pop-up label

## How It Works

### Node Tree

```
Main (Control)
└── JuiceButton (Button)    ← juice_button.gd
```

The button is the only node. Labels are spawned at runtime as siblings.

### `scripts/juice_button.gd`

```gdscript
func _ready() -> void:
    pressed.connect(_on_pressed)
    pivot_offset = size / 2   # scale from center, not top-left

func _on_resized() -> void:
    pivot_offset = size / 2   # recalculate when button size changes
```

`pivot_offset` sets the anchor point for scale and rotation. The default is `(0, 0)` (top-left). Setting it to `size / 2` makes scale transforms originate from the button's center.

**Squish animation:**
```gdscript
func _squish() -> void:
    var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2(1.25, 0.7), 0.07)
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
```

**Step 1** (0.07s): Scale instantly to 1.25×0.7 — wider and shorter (squash).
**Step 2** (0.3s): Return to 1.0×1.0 — normal size (stretch back).

`TRANS_BACK` adds **overshoot** on step 2: the scale momentarily exceeds 1.0 before settling, giving a springy, elastic feel. `EASE_OUT` means the motion starts fast and slows at the end.

**Floating pop-up:**
```gdscript
func _spawn_pop(at: Vector2) -> void:
    var label := Label.new()
    label.text = "+10"
    label.position = at + Vector2(randf_range(-20, 20), -20)
    label.add_theme_font_size_override("font_size", 28)
    label.add_theme_color_override("font_color", Color.GOLD)
    get_parent().add_child(label)

    var tween := label.create_tween().set_parallel()
    tween.tween_property(label, "position:y", label.position.y - 70, 0.7)
    tween.tween_property(label, "modulate:a", 0.0, 0.7)
    tween.chain().tween_callback(label.queue_free)
```

`set_parallel()` makes all subsequent `tween_property` calls run simultaneously instead of sequentially. Both the position drift and the alpha fade happen over the same 0.7 seconds.

`tween.chain()` exits parallel mode and returns to sequential. The final `tween_callback(label.queue_free)` runs after the parallel tweens finish, cleaning up the label.

`"position:y"` targets the Y component of the `position` Vector2 directly — Godot supports property paths with `:` for sub-properties.

## Game Feel Theory

### Squash and Stretch

A foundational animation principle: objects compress along the axis of motion (squash) and stretch when released (stretch). When the button is pressed, it squashes: wider and shorter. When released, it springs back and briefly overshoots (stretch) before settling. This mimics the behavior of physical elastic objects.

```
Normal:  1.0 × 1.0
Squash:  1.25 × 0.70
Stretch: (briefly) 1.05 × 1.05 (from TRANS_BACK overshoot)
Settled: 1.0 × 1.0
```

### Easing Functions

The easing function controls how a value changes over time:
- **Linear**: Constant rate — mechanical, unnatural
- **EASE_OUT**: Fast start, slow end — like a ball thrown upward
- **EASE_IN**: Slow start, fast end — like a ball falling
- **EASE_IN_OUT**: Slow-fast-slow — smooth acceleration and deceleration

**Transition** (`TRANS_`) controls the shape of the curve:
- `TRANS_LINEAR`: Straight line
- `TRANS_QUAD`, `TRANS_CUBIC`: Polynomial curves
- `TRANS_BACK`: Overshoot — exceeds the target value before returning
- `TRANS_ELASTIC`: Spring-like oscillation
- `TRANS_BOUNCE`: Bounces at the end

`TRANS_BACK` with `EASE_OUT` is the canonical choice for UI button presses — it feels satisfyingly "clicky."

### Floating Text Pattern

Floating score numbers (+10, +50, CRITICAL HIT) are ubiquitous in games because they:
1. Give immediate, local feedback (appears where the action happened)
2. Convey precise information (exact amount)
3. Fade naturally without requiring the player to look at a score display

The combination of upward drift + alpha fade is a visual shorthand for "temporary information that doesn't need attention after a moment."

### Parallel Tweens

`set_parallel()` is the key to multi-property animations that run simultaneously. Without it, position would animate first (0.7s), then alpha (0.7s), for 1.4 total seconds. With `set_parallel()`, both animate concurrently over 0.7 seconds.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `create_tween()` | Create a new Tween |
| `Tween.set_trans(TRANS_BACK)` | Set transition curve |
| `Tween.set_ease(EASE_OUT)` | Set easing direction |
| `Tween.set_parallel()` | Run subsequent steps simultaneously |
| `Tween.chain()` | Resume sequential mode |
| `Tween.tween_callback(callable)` | Run code after tweens finish |
| `tween_property(node, "prop:sub", value, time)` | Target a sub-property |
| `Control.pivot_offset` | Anchor for scale/rotation |
| `add_theme_font_size_override(property, value)` | Override theme for one node |

## Files

| File | What it holds |
|------|---------------|
| `scripts/juice_button.gd` | `juice button` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/juice_button.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

## Related demos

- [camera-rooms](../camera-rooms) — Room-based camera transitions using `Area2D`, signals, and `Tween`.
- [drag-drop](../drag-drop) — Mouse drag-and-drop with snap-back when dropped outside a valid target.
- [screen-flash](../screen-flash) — Full-screen color flash feedback via a `ColorRect` + Tween.
- [drop-table](../drop-table) — Weighted random loot; watch observed rates converge on expected probabilities.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

