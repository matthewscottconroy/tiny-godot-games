# Spread Shot

Fires a burst of N bullets distributed evenly across an angle. Press Space to fire. Demonstrates rotating a direction vector by a linearly-distributed offset.

## Purpose

Spread shot (shotgun pattern) is common in action games. The implementation is a single loop: lerp a parameter `t` from 0 to 1 across the bullet count, map it to an angle range via `lerpf`, rotate the base direction by that angle. This keeps the math simple regardless of bullet count or spread angle.

## Controls

- **Arrow keys / WASD**: Move and face a direction
- **Up**: Jump
- **Space**: Fire spread shot in the facing direction

## How It Works

### `scripts/player.gd` — spread calculation

```gdscript
func _fire() -> void:
    var half := deg_to_rad(SPREAD_DEG * 0.5)
    var base := Vector2(_facing, 0.0)
    for i in BULLET_COUNT:
        var t     := float(i) / (BULLET_COUNT - 1)
        var angle := lerpf(-half, half, t)
        var dir   := base.rotated(angle)
        # spawn bullet in dir
```

| i | t | angle |
|---|---|-------|
| 0 | 0.0 | −half (top of spread) |
| 2 | 0.5 | 0° (straight) |
| 4 | 1.0 | +half (bottom of spread) |

The middle bullet always goes straight regardless of BULLET_COUNT.

### Dynamic bullet spawning

```gdscript
var b := Node2D.new()
b.set_script(BulletScript)
get_parent().add_child(b)
b.init(global_position + base * 22.0, base.rotated(angle))
```

Bullets are created at runtime without a scene file. `preload` in the player script loads `bullet.gd` at parse time so there's no runtime disk access on each shot.

### `scripts/bullet.gd`

Moves in `_process` (not physics) — no physics engine involvement, just position arithmetic. Cleaned up after `LIFETIME` seconds or when out of bounds.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.rotated(angle)` | Rotate a direction vector by radians |
| `lerpf(-half, half, t)` | Evenly distribute bullets across spread |
| `deg_to_rad(degrees)` | Convert degrees to radians for trig |
| `preload("res://scripts/bullet.gd")` | Load script resource at parse time |
| `node.set_script(script)` | Attach script to dynamically-created node |
