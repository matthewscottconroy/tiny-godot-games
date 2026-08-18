# Screen Shake

<!-- tags: none -->

Implements camera shake by animating the `Camera2D.offset` property through a series of random displacements using a Tween.

## Purpose

Screen shake is a fundamental game feel technique. It provides physical feedback for impacts, explosions, or high-intensity events. A well-timed shake makes attacks feel weighty, explosions feel powerful, and events feel significant. This demo shows a clean, Tween-based implementation that requires no per-frame code after triggering.

## Controls

- **Space / Enter** (`ui_accept`): Trigger a shake
- Watch the scene geometry visibly shake and settle

## How It Works

### Node Tree

```
Main (Node2D)            ← main.gd
└── Camera2D
```

The `Camera2D` is a direct child of `Main` (not the player), so it stays fixed in world space while its `offset` jitters.

### `scripts/main.gd`

```gdscript
func shake(duration: float = 0.4, strength: float = 12.0) -> void:
    var tween := create_tween()
    var steps := int(duration / 0.04)        # ~10 steps for 0.4s
    for i in steps:
        var offset := Vector2(
            randf_range(-strength, strength),
            randf_range(-strength, strength)
        )
        tween.tween_property(camera, "offset", offset, 0.04)
    tween.tween_property(camera, "offset", Vector2.ZERO, 0.06)
```

`tween_property` calls chain sequentially by default. Each step moves the camera offset to a new random position over 0.04 seconds (~24 fps worth of jitter). After all steps, the final `tween_property` smoothly returns the offset to `Vector2.ZERO` over 0.06 seconds — avoiding a jarring snap back.

```gdscript
func _draw() -> void:
    # Static geometry to make the shake visible
    draw_rect(Rect2(60, 180, 80, 100), Color.SLATE_GRAY)
    draw_rect(Rect2(260, 200, 120, 80), Color.SLATE_GRAY)
    draw_rect(Rect2(460, 160, 90, 120), Color.SLATE_GRAY)
    draw_rect(Rect2(0, 440, 640, 20), Color.DIM_GRAY)
```

Static background shapes confirm the camera is moving — without reference geometry, you cannot perceive a shake.

## Screen Shake Theory

### Camera Offset vs Camera Position

`Camera2D.offset` is added to the camera's tracking position **after** all position calculations. Modifying `offset` shakes the view while allowing the camera to continue following the player normally. If you modified `camera.position` directly, the camera would no longer track the player correctly.

For a fixed camera (as in this demo), either approach works. For a player-following camera, always use `offset`.

### Tween-Based vs Process-Based Shake

**Process-based** shake (common approach):
```gdscript
var shake_time := 0.0
func _process(delta):
    if shake_time > 0:
        camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s))
        shake_time -= delta
    else:
        camera.offset = Vector2.ZERO
```
Simple but produces **white noise** jitter — each frame is independent, giving a harsh strobing effect.

**Tween-based** shake (this demo):
Each step tweens smoothly to a new random position, creating **interpolated** jitter. The camera moves continuously between shake positions rather than snapping frame-to-frame. This is smoother and generally more pleasant.

For advanced shake, **Perlin noise** (using `randf()` with a slowly changing seed, or a FastNoiseLite node) produces even smoother, more organic motion.

### Decay

Real screen shake typically decays in strength over time (starts strong, fades out). This demo uses uniform strength throughout for simplicity. To add decay:
```gdscript
var t := float(i) / steps
var decayed_strength := strength * (1.0 - t)
var offset := Vector2(randf_range(-decayed_strength, decayed_strength), ...)
```

### Return to Zero

The final step `tween_property(camera, "offset", Vector2.ZERO, 0.06)` is essential. Without it, the camera's offset would be left at whatever random position the last step ended at, permanently shifting the view.

### Calling shake() Multiple Times

If `shake()` is called while a previous shake is running, `create_tween()` creates a new tween that runs in parallel. Both tweens modify `camera.offset`, which can cause interference. To handle this cleanly:
```gdscript
var _shake_tween: Tween

func shake(duration, strength) -> void:
    if _shake_tween:
        _shake_tween.kill()
    _shake_tween = create_tween()
    # ...
```

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Camera2D.offset` | Additional displacement on top of follow position |
| `create_tween()` | Create a new Tween |
| `Tween.tween_property(node, prop, value, time)` | Animate a property |
| `randf_range(min, max)` | Random float in range |
| `event.is_action_pressed(action)` | Edge-triggered input |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [camera-rooms](../camera-rooms) — Room-based camera transitions using `Area2D`, signals, and `Tween`.
- [camera-deadzone](../camera-deadzone) — Camera stays still until the player exits a rectangular dead zone, then catches up.
- [camera-zoom](../camera-zoom) — Smooth scroll-wheel `Camera2D` zoom with lerp targeting and min/max limits.
- [minimap](../minimap) — A real-time minimap drawn in code for a wide side-scrolling world.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

