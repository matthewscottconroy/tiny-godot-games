# Homing Projectile

A missile that steers toward a moving target using `lerp_angle` on its velocity direction. Speed stays constant — only the heading changes. Press Space to fire.

## Purpose

Homing projectiles are a common pattern in shmups and action games. The key insight is that homing is just angle interpolation applied to velocity every frame: compute the angle toward the target, `lerp_angle` toward it, rebuild the velocity vector at the same speed.

## Controls

- **Space**: Fire a homing projectile at the target

## How It Works

### `scripts/projectile.gd` — steering

```gdscript
func _process(delta: float) -> void:
    if is_instance_valid(_target):
        var to_target := (_target.global_position - global_position).angle()
        var cur_angle := _vel.angle()
        var new_angle := lerp_angle(cur_angle, to_target, TURN_SPEED * delta)
        _vel           = Vector2.from_angle(new_angle) * SPEED
    position += _vel * delta
```

Three steps every frame:
1. Compute the angle from projectile to target
2. Lerp the current heading toward that angle
3. Rebuild velocity as a unit vector at that angle, scaled to `SPEED`

`lerp_angle` handles the wraparound at ±180° correctly — unlike `lerpf`, it takes the shortest arc.

### Why `is_instance_valid`?

```gdscript
if is_instance_valid(_target):
```

The target might be destroyed mid-flight. Without this check, accessing `_target.global_position` on a freed node crashes. With it, the projectile continues straight after the target disappears.

### Turn speed tuning

`TURN_SPEED = 3.5` means the projectile rotates ~3.5 radians per second at full weight. Higher values give tighter tracking; lower values give a lazy arc that misses fast targets.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `lerp_angle(from, to, weight)` | Interpolates angles taking the shortest arc |
| `Vector2.from_angle(angle)` | Unit vector from an angle in radians |
| `Vector2.angle()` | Angle of a vector in radians |
| `is_instance_valid(node)` | Safe check before accessing potentially-freed node |
| `node.set_script(script)` | Attach a script to a dynamically-created node |
