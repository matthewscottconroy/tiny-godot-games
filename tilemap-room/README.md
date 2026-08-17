# Tilemap Room

Demonstrates a scrollable room larger than the viewport, with `Camera2D` limits to prevent the view from going outside the room boundary, and a checkerboard floor drawn in code.

## Purpose

Most games are larger than the screen. This demo shows the minimum setup for a contained room: define the room dimensions, set Camera2D limits to those dimensions, and scroll freely within the space while the camera never shows outside the room. The floor pattern and obstacle placement are drawn entirely in code — no tile maps or assets required.

## Controls

- **Arrow keys**: Move the player
- The camera follows and scrolls to reveal the 1280×960 room

## How It Works

### Node Tree

```
Main (Node2D)                    ← main.gd  (floor + obstacles via _draw())
└── Player (CharacterBody2D)     ← player.gd
    └── Camera2D
```

### `scripts/main.gd`

```gdscript
const ROOM_W := 1280
const ROOM_H := 960

func _ready() -> void:
    var cam: Camera2D = $Player/Camera2D
    cam.limit_left   = 0
    cam.limit_top    = 0
    cam.limit_right  = ROOM_W
    cam.limit_bottom = ROOM_H
```

The limits are set in code rather than the editor so the constants and the Camera2D limits stay synchronized in one place.

**Floor pattern (`_draw()`):**
```gdscript
for row in range(0, ROOM_H, 80):
    for col in range(0, ROOM_W, 80):
        var shade := 0.18 if ((row + col) / 80) % 2 == 0 else 0.22
        draw_rect(Rect2(col, row, 80, 80), Color(shade, shade, shade))
```

A nested loop iterates all 80×80 cells. The checkerboard is produced by checking whether `(row/80 + col/80) % 2 == 0` — cells where the sum of their grid coordinates is even get one shade, odd cells get another.

**Obstacle rectangles** are drawn after the floor, appearing on top.

### `scripts/player.gd`

Standard `CharacterBody2D` with `Input.get_vector()` for 8-directional movement and `move_and_slide()`. The `Camera2D` is a child node, so it follows the player automatically.

## Room and Camera Theory

### Room Dimensions

The room is 1280×960 pixels — twice the default 640×480 viewport. At the viewport's center, you see a 640×480 view of the room. Moving to the corners reveals the room's edges. The camera never scrolls beyond the room because of the limits.

### Camera2D Limits

```gdscript
cam.limit_left   = 0       # camera left edge cannot go below x=0
cam.limit_right  = 1280    # camera right edge cannot exceed x=1280
cam.limit_top    = 0
cam.limit_bottom = 960
```

Limits constrain the camera's **viewport rectangle**, not its position. When the player walks near the left wall (x ≈ 320, the half-viewport-width), the camera stops scrolling left — the left edge of the viewport is clamped to x=0.

If the room is smaller than the viewport (unlikely but possible), limits also prevent the camera from being centered incorrectly.

### Checkerboard Math

Each 80×80 cell can be identified by its grid coordinate `(col/80, row/80)`. The checkerboard rule:
```
(grid_x + grid_y) % 2 == 0  → shade A
(grid_x + grid_y) % 2 == 1  → shade B
```

This is equivalent to `(row + col) / 80 % 2` since `(row/80 + col/80) = (row + col)/80` when both are multiples of 80. The result is a standard checkerboard where every cell has a neighbor of the opposite shade.

### _draw() for Large Scenes

Drawing the entire room floor in `_draw()` processes all 192 cells (16 × 12) every frame. For a 1280×960 room this is fine; for very large rooms (e.g. 10000×10000), only draw the cells within the visible viewport using `get_viewport_rect()` to cull off-screen draws.

### StaticBody2D Obstacles

Real obstacles would be `StaticBody2D` nodes with `CollisionShape2D` children. In this demo, `draw_rect()` only draws the visual — the player can walk through the grey rectangles because they have no collision. Adding `StaticBody2D` would make them solid.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Camera2D.limit_left/right/top/bottom` | Constrain the view to room bounds |
| `$Player/Camera2D` | Node path to a nested child |
| `range(start, stop, step)` | Loop with step (for grid iteration) |
| `draw_rect(Rect2(x, y, w, h), color)` | Filled rectangle |
| `Rect2(x, y, width, height)` | Rectangle primitive |
| `Input.get_vector(neg_x, pos_x, neg_y, pos_y)` | Normalized 2D directional input |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [subviewport](../subviewport) — Render one `World2D` through two cameras (main + minimap) via `SubViewport`.
- [visible-notifier](../visible-notifier) — `VisibleOnScreenNotifier2D` signals for zero-poll CPU culling.
- [camera-deadzone](../camera-deadzone) — Camera stays still until the player exits a rectangular dead zone, then catches up.
- [camera-rooms](../camera-rooms) — Room-based camera transitions using `Area2D`, signals, and `Tween`.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

