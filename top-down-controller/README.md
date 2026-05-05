# Top-Down Controller

8-directional movement with no gravity: the player moves freely in any direction and the velocity direction drives a facing indicator. The entire collection is side-scrolling — this covers the other common movement mode.

## Purpose

Most 2D game movement falls into two families: side-scrolling (gravity, jump) and top-down (no gravity, free direction). This demo shows `MOTION_MODE_FLOATING`, which disables Godot's floor/ceiling/wall concepts so the character slides freely in any direction without needing to fight gravity.

## Controls

- **Arrow keys / WASD**: Move in any of 8 directions

## How It Works

### `scripts/player.gd`

```gdscript
func _ready() -> void:
    motion_mode = MOTION_MODE_FLOATING

func _physics_process(_delta: float) -> void:
    var raw := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var dir := raw.normalized() if raw.length() > 0.001 else Vector2.ZERO
    velocity = dir * SPEED
    if dir != Vector2.ZERO:
        _last_dir = dir
    move_and_slide()
```

`Input.get_vector` returns a joystick-style Vector2 already within a unit circle for gamepads, but not normalized for keyboard (diagonal = length √2). Normalizing prevents diagonal movement being faster.

`_last_dir` persists the facing direction when the player stops, so the indicator doesn't snap to a default.

### Direction indicator

Instead of rotating the node (which would rotate the child Label too), the `_draw()` function draws a line from the node center in `_last_dir`:

```gdscript
func _draw() -> void:
    draw_circle(Vector2.ZERO, 14, Color.DODGER_BLUE)
    draw_line(Vector2.ZERO, _last_dir * 20.0, Color.WHITE, 3.0)
```

### `scripts/main.gd` — room drawing

```gdscript
func _draw() -> void:
    draw_rect(Rect2(0, 0, 640, 20), wall_col)       # top
    draw_rect(Rect2(0, 460, 640, 20), wall_col)     # bottom
    draw_rect(Rect2(0, 20, 20, 440), wall_col)      # left
    draw_rect(Rect2(620, 20, 20, 440), wall_col)    # right
    draw_rect(Rect2(130, 170, 60, 60), obs_col)     # obstacle 1
    draw_rect(Rect2(420, 280, 80, 40), obs_col)     # obstacle 2
```

Visual rects match the StaticBody2D + RectangleShape2D collision nodes.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CharacterBody2D.MOTION_MODE_FLOATING` | Disables gravity/floor — free 2D movement |
| `Input.get_vector(left, right, up, down)` | Returns a 2D input axis, gamepad-ready |
| `Vector2.normalized()` | Ensures diagonal speed equals cardinal speed |
| `_draw() / queue_redraw()` | Immediate-mode drawing updated each frame |
