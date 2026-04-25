# Arrow Sprite

Moves a sprite around the screen using arrow keys, demonstrating basic 2D movement, normalized direction vectors, and frame-rate-independent motion.

## Purpose

This is often the very first script a Godot learner writes. It introduces `_process()`, `Input`, `Vector2`, and `delta` — the four concepts behind almost every moving object in a game. The demo deliberately avoids `look_at()` to keep the focus on directional movement rather than rotation.

## Controls

- **Arrow keys / WASD**: Move the sprite in any direction (8-directional)

## How It Works

### Node Tree

```
Player (Sprite2D)   ← player.gd
```

The node is a `Sprite2D` extended directly. The script uses Godot's built-in arrow SVG as the texture.

### `scripts/player.gd`

```gdscript
extends Sprite2D

@export var speed: float = 200.0

func _process(delta: float) -> void:
    var direction := Vector2.ZERO
    if Input.is_action_pressed("ui_right"): direction.x += 1
    if Input.is_action_pressed("ui_left"):  direction.x -= 1
    if Input.is_action_pressed("ui_down"):  direction.y += 1
    if Input.is_action_pressed("ui_up"):    direction.y -= 1

    if direction.length_squared() > 0:
        position += direction.normalized() * speed * delta
```

## Core Concepts

### `_process(delta)` vs `_physics_process(delta)`

`_process(delta)` runs every rendered frame, which can vary (60 fps, 144 fps, etc). `_physics_process(delta)` runs at a fixed rate (default 60 Hz) and is required when using `move_and_slide()` or interacting with the physics engine. This demo uses `_process()` because the sprite is not a physics body — it moves by direct position assignment.

### Delta Time

`delta` is the number of seconds since the last frame. Multiplying movement by `delta` makes speed **frame-rate independent**:

```
position += direction * speed * delta
```

At 60 fps: `delta ≈ 0.0167` → moves `200 × 0.0167 = 3.33 px/frame`
At 30 fps: `delta ≈ 0.0333` → moves `200 × 0.0333 = 6.67 px/frame`

Both cases cover 200 pixels per second. Without `delta`, fast machines would move the sprite faster than slow machines.

### Normalized Direction

When two axes are pressed simultaneously (e.g. right + down), the raw direction vector is `(1, 1)`, which has length `√2 ≈ 1.414`. Moving at full speed in a diagonal would be 41% faster than moving straight. `.normalized()` scales the vector to length 1, keeping diagonal speed equal to cardinal speed.

`length_squared() > 0` is used instead of `length() > 0` because it avoids a square root — a small optimization that matters in hot loops.

### `@export`

`@export var speed: float = 200.0` makes `speed` visible and editable in the Godot Inspector without changing the script. This is the standard way to expose tunable values to designers while keeping the default defined in code.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.is_action_pressed(action)` | True while the action key is held |
| `Vector2.ZERO` | Shorthand for `Vector2(0, 0)` |
| `direction.normalized()` | Scale vector to length 1 |
| `direction.length_squared()` | Squared magnitude (faster than `length()`) |
| `@export` | Exposes a variable to the Inspector |
| `_process(delta)` | Called every rendered frame |
