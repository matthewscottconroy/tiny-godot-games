# Camera Follow

Demonstrates how to attach a `Camera2D` as a child of the player so the view follows movement automatically, with position smoothing and hard limits.

## Purpose

Most 2D games need a camera that follows the player while staying within the world bounds. Godot's `Camera2D` handles this natively when it is a child of the moving node. This demo shows the minimal setup required and explains the key properties: smoothing, limits, and the relationship between the node hierarchy and camera behavior.

## Controls

- **Arrow keys**: Move left and right
- **Up / W**: Jump
- The world is wider than the screen; scroll right to see the camera follow

## How It Works

### Node Tree

```
Main (Node2D)
├── Player (CharacterBody2D)  ← player.gd
│   ├── Camera2D              (child — follows player automatically)
│   └── CollisionShape2D
├── Ground (StaticBody2D)
└── (world decorations via _draw())
```

### `scripts/player.gd`

Standard platformer physics: gravity accumulates in `velocity.y` each frame, `ui_up` triggers a jump with a fixed upward velocity, and `move_and_slide()` handles collision. `queue_redraw()` is called every physics frame so the `_draw()` visuals stay aligned with the physics transform.

The camera itself requires **no code**. Its behavior is set entirely by properties on the `Camera2D` node:

```
Camera2D:
    position_smoothing_enabled = true
    position_smoothing_speed   = 5.0
    limit_left   = 0
    limit_right  = 1280
    limit_top    = 0
    limit_bottom = 480
```

## Camera2D Theory

### Child-of-Player Pattern

When `Camera2D` is a child of the player, its `position` in local space is `(0, 0)` — the camera's center is exactly the player's origin. Godot's scene transform system propagates the player's global position to the camera automatically. You never need to write `camera.position = player.position`.

Compare to the alternative: a separate camera node that you manually move in `_process()`. That approach works but requires extra code and can introduce one-frame lag.

### Position Smoothing

`position_smoothing_enabled = true` makes the camera **lag behind** the player's actual position rather than snapping instantly. The camera chases the target at `position_smoothing_speed` units per second. This reduces visual jitter and gives a more cinematic feel.

The smoothing uses an exponential decay formula internally:
```
camera_pos = lerp(camera_pos, target_pos, speed * delta)
```
This means the camera approaches but never exactly reaches the target each frame — the gap halves repeatedly, giving a smooth asymptotic approach.

### Limits

The four limit properties clamp the camera's view to a rectangle:
```
limit_left   = 0      # camera will not scroll left of x=0
limit_right  = 1280   # camera will not scroll right of x=1280
limit_top    = 0
limit_bottom = 480
```

When the player walks near the left edge, the camera stops moving left even if the player continues, preventing the view from showing the void beyond the world boundary.

### Drag Margin

`drag_horizontal_enabled` and `drag_vertical_enabled` (not used in this demo) create a "dead zone" — the camera only moves when the player exits a central rectangle, keeping the player in view without tracking every small movement.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Camera2D` as child of player | Automatic position tracking |
| `Camera2D.position_smoothing_enabled` | Lag-based smooth following |
| `Camera2D.position_smoothing_speed` | Chase speed in pixels/second |
| `Camera2D.limit_left/right/top/bottom` | Clamp the camera to world bounds |
| `CharacterBody2D.is_on_floor()` | True when resting on a surface |
| `move_and_slide()` | Move with full collision response |

## Files

| File | What it holds |
|------|---------------|
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/player.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

