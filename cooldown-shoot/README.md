# Cooldown Shoot

Demonstrates projectile instantiation, `@export` scene references, cooldown timers, and a visual cooldown indicator using a `ProgressBar`.

## Purpose

Shooting mechanics require managing rate of fire (cooldown), knowing which direction to shoot, spawning projectiles into the scene, and giving the player visual feedback on when they can shoot again. This demo covers all four without any external Timer nodes — cooldown is tracked with a plain float decremented in `_physics_process`.

## Controls

- **Arrow keys**: Move and aim (facing direction follows movement)
- **Space / Enter** (`ui_accept`): Shoot
- The grey bar at the player shows cooldown; "READY" appears when able to fire

## How It Works

### Node Tree

```
Main (Node2D)
├── Player (CharacterBody2D)  ← player.gd
│   ├── CooldownBar (ProgressBar)
│   ├── ReadyLabel (Label)
│   └── CollisionShape2D
└── (bullets are added directly to Main at runtime)
```

Bullets are spawned as children of `Main` (via `get_parent().add_child(b)`) rather than children of `Player`, so they continue moving after the player moves.

### `scripts/player.gd`

- **`@export var bullet_scene: PackedScene`** — The bullet scene is assigned in the Inspector. This decouples the player from the bullet's implementation: changing bullet behavior only requires a new scene.
- **`facing: Vector2`** — Updated each frame to the normalized movement direction. When the player stops moving, `facing` retains its last value, so bullets fire in the last direction moved.
- **`cooldown`** — Decrements each physics frame: `cooldown = max(0.0, cooldown - delta)`. When it reaches 0, firing is allowed again. On firing, it resets to `FIRE_COOLDOWN = 0.35`.
- **`cooldown_bar.value = 1.0 - (cooldown / FIRE_COOLDOWN)`** — Maps remaining cooldown (0 to FIRE_COOLDOWN) to a 0–1 ProgressBar value. The bar fills as the cooldown expires.
- **`_draw()`** — Draws the player body and a barrel line from the player origin in the `facing` direction using `draw_line()`.

### `scripts/bullet.gd`

```gdscript
extends Area2D

var direction := Vector2.RIGHT
const SPEED := 500.0
var _lifetime := 1.6

func _process(delta: float) -> void:
    position += direction * SPEED * delta
    _lifetime -= delta
    if _lifetime <= 0.0:
        queue_free()
```

Bullets move in a straight line using direct position assignment (no physics body needed — they don't need to push anything). Lifetime prevents them from living forever off-screen.

## Design Theory

### Float Timer vs Timer Node

Using `cooldown -= delta` in `_physics_process` is simpler than creating a `Timer` node and connecting its `timeout` signal. Timer nodes add to the scene tree, require signal management, and need their `wait_time` set before starting. For single-property rate limiting, a float variable is cleaner.

### @export PackedScene

```gdscript
@export var bullet_scene: PackedScene
```

`PackedScene` is a resource that stores a complete scene tree as a template. `bullet_scene.instantiate()` creates a new independent copy of that scene. Assigning it via `@export` means:
- The bullet scene file can be swapped without changing code
- Designers can create new bullet types as new scenes and assign them in the Inspector

### spawn into get_parent()

```gdscript
get_parent().add_child(b)
```

If bullets were children of `Player`, they would be positioned relative to the player and move with it. Spawning into the parent (Main) gives bullets independent global positions. Their `global_position` is set before `add_child()` to place them correctly in world space.

### ProgressBar as Cooldown UI

```gdscript
cooldown_bar.value = 1.0 - (cooldown / FIRE_COOLDOWN)
```

`ProgressBar.value` goes from `min_value` (0.0) to `max_value` (1.0 after setting `max_value = 1.0`). When `cooldown = FIRE_COOLDOWN`, the expression equals 0 (bar empty). When `cooldown = 0`, it equals 1 (bar full). This converts remaining cooldown time to fill percentage.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `@export var bullet_scene: PackedScene` | Assignable scene template |
| `bullet_scene.instantiate()` | Create a new copy of the scene |
| `get_parent().add_child(node)` | Spawn into the parent scene |
| `node.global_position` | World-space position |
| `ProgressBar.value` | Normalized bar fill (0 to max_value) |
| `draw_line(from, to, color, width)` | Line primitive in _draw() |

## Files

| File | What it holds |
|------|---------------|
| `scripts/bullet.gd` | `bullet` behaviour |
| `scripts/player.gd` | `player` behaviour |
| `scenes/bullet.tscn` | Scene |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/bullet.gd`, `scripts/player.gd`.

**`scripts/player.gd`**
- `@export bullet_scene: PackedScene`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

