# Camera Deadzone

A side-scrolling camera that stays still while the player is near the center of the screen, then smoothly catches up once the player exits a rectangular dead zone.

## Purpose

A camera that follows the player's every pixel of movement is distracting — small corrections and turning animations cause constant camera drift that fatigues the eye. A dead zone gives the player a region of freedom where the camera ignores movement entirely. The camera only catches up when the player commits to a direction, which reads as intentional travel rather than fidgeting. Nearly every commercial 2D platformer uses this pattern: *Celeste*, *Hollow Knight*, *Shovel Knight*, and the classic *Super Mario World* all implement a horizontal dead zone.

The vertical component is equally important. Jumping straight up should not rocket the camera upward, but walking off a ledge should eventually show the ground. Setting a smaller vertical half-height than horizontal gives a natural "loosen" feel in both axes independently.

The yellow rectangle drawn on screen is not decoration — it is the single most useful debugging tool for camera feel. During development, keeping it visible lets you tune `DEAD_W` and `DEAD_H` against actual player movement before hiding it in the final build.

## How It Works

### Node Tree

```
Main (Node2D)                   ← main.gd
├── Player (CharacterBody2D)    ← player.gd
├── Camera2D
└── CanvasLayer
    └── StatusLabel (Label)
```

The camera is a sibling of the player, not a child. Making it a child of the player would cause it to follow instantly with no dead zone logic at all.

### Dead Zone Tracking (`scripts/main.gd`)

```gdscript
const DEAD_W       := 80.0    # half-width of dead zone in world pixels
const DEAD_H       := 40.0    # half-height
const FOLLOW_SPEED := 4.5     # lerp rate (world units/s convergence)

func _process(delta: float) -> void:
    var offset := _player.global_position - _cam.global_position
    var target := _cam.global_position   # default: don't move

    if offset.x > DEAD_W:
        target.x = _player.global_position.x - DEAD_W
    elif offset.x < -DEAD_W:
        target.x = _player.global_position.x + DEAD_W

    if offset.y > DEAD_H:
        target.y = _player.global_position.y - DEAD_H
    elif offset.y < -DEAD_H:
        target.y = _player.global_position.y + DEAD_H

    _cam.global_position = _cam.global_position.lerp(target, FOLLOW_SPEED * delta)
```

`offset` is the player's position relative to the camera center. When the player is inside the dead zone, all four conditions are false and `target` equals the current camera position — the `lerp` moves zero distance. When the player exits an edge, `target` is set to the camera position that would put the player exactly at that edge, and the camera lerps toward it.

### Visualization (`_draw`)

```gdscript
var center := get_viewport_rect().size * 0.5
draw_rect(Rect2(center.x - DEAD_W, center.y - DEAD_H, DEAD_W * 2, DEAD_H * 2),
    Color(1.0, 1.0, 0.3, 0.15))   # filled, translucent
draw_rect(Rect2(center.x - DEAD_W, center.y - DEAD_H, DEAD_W * 2, DEAD_H * 2),
    Color(1.0, 1.0, 0.3, 0.6), false, 1.5)  # outlined
```

Drawing in `_draw()` using viewport coordinates keeps the rectangle fixed on screen while the world scrolls. `DEAD_W` and `DEAD_H` appear in both the logic and the visualization from the same constants, so tuning one constant updates both.

## Deadzone Math

### Why `target` Defaults to Current Position

Setting `target := _cam.global_position` at the top means the camera has no desired movement unless the player is outside the zone. This avoids any "drift" when the player is idle: the lerp multiplies a zero-length vector and the camera is perfectly still.

### Lerp as Exponential Approach

`lerp(a, b, FOLLOW_SPEED * delta)` closes a fraction of the remaining gap each frame. With `FOLLOW_SPEED = 4.5` at 60 fps, each frame closes about 7% of the gap:

```
weight = 4.5 * 0.0167 ≈ 0.075
```

This means the camera catches up quickly (within ~0.3 seconds for most distances) but never snaps. It is frame-rate-independent as long as delta is real elapsed time.

### Manual Camera vs Built-in Smoothing

Godot's `Camera2D` has `position_smoothing_enabled` built in, but it cannot implement a dead zone on its own. By disabling built-in smoothing and controlling `global_position` manually, you retain full design control: asymmetric dead zone sizes, velocity-dependent lead distance, or cinematic camera locks during cutscenes all become trivial to add.

## How to Adapt This in Your Project

**Asymmetric horizontal dead zone:** Use separate `DEAD_LEFT` and `DEAD_RIGHT` constants so the player can see further in the direction they're facing.

**Look-ahead:** Multiply `_player.velocity.x * LOOK_AHEAD_FACTOR` to shift `target.x` forward when the player is moving, giving them more room to react to what's ahead.

**Vertical lock:** For pure side-scrollers (no vertical scrolling), remove the Y axis checks entirely and hard-code `_cam.global_position.y` to a fixed value.

**Clamp to world bounds:** After computing `target`, clamp it: `target.x = clampf(target.x, world_left, world_right)` to prevent the camera from showing empty space at level edges.

**Snap on teleport:** After a teleport or room transition, set `_cam.global_position = _player.global_position` directly to skip the lerp catch-up.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Camera2D.global_position` | Move camera by setting its world-space position directly |
| `Vector2.lerp(target, weight)` | Smooth exponential approach to a target position |
| `get_viewport_rect().size` | Current viewport dimensions in pixels |
| `CanvasLayer` | UI elements that stay fixed in screen space regardless of camera |
| `CharacterBody2D.move_and_slide()` | Physics movement that interacts with `StaticBody2D` floors |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys | Move (world extends ~3000 px wide) |
| Up | Jump |

## Key Constants

```gdscript
const DEAD_W       := 80.0   # half-width of dead zone in world pixels
const DEAD_H       := 40.0   # half-height of dead zone in world pixels
const FOLLOW_SPEED := 4.5    # lerp convergence rate (higher = snappier)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Dead zone logic, camera lerp, dead zone visualization overlay |
| `scripts/player.gd` | Standard platformer movement (walk, jump, gravity) |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [camera-follow](../camera-follow) — Attach a `Camera2D` to the player with position smoothing and hard limits.
- [checkpoint-system](../checkpoint-system) — One-way checkpoints that update respawn position; press R to die and respawn.
- [camera-rooms](../camera-rooms) — Room-based camera transitions using `Area2D`, signals, and `Tween`.
- [camera-zoom](../camera-zoom) — Smooth scroll-wheel `Camera2D` zoom with lerp targeting and min/max limits.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

