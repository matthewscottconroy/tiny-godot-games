# Knockback

Velocity-based recoil on hit: a separate `_knockback` vector is applied on contact and decays over time, layered on top of normal control velocity. Enemies patrol and trigger hits via Area2D overlap.

## Purpose

Knockback looks like a simple feature but has a subtle design decision: should the knockback replace player velocity or add to it? This demo uses addition — the player retains partial control during knockback — which feels more responsive. Iframes prevent stun-locking from rapid successive hits.

## Controls

- **Arrow keys / WASD**: Move and maintain partial control during knockback
- **Up**: Jump

## How It Works

### Separation of knockback and control (`scripts/player.gd`)

```gdscript
var _knockback := Vector2.ZERO

func _physics_process(delta: float) -> void:
    _knockback = _knockback.lerp(Vector2.ZERO, KB_DECAY * delta)
    var ctrl_x := Input.get_axis("ui_left", "ui_right") * SPEED
    velocity.x  = ctrl_x + _knockback.x
    if _knockback.y != 0.0:
        velocity.y   = _knockback.y
        _knockback.y = 0.0  # apply once, then gravity takes over
```

`_knockback.y` is applied to `velocity.y` and immediately zeroed. This lets the player arc upward naturally under gravity rather than being locked into an upward velocity each frame.

### Hit detection (`scripts/enemy.gd`)

```gdscript
_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.has_method("take_hit"):
        body.take_hit(global_position)
```

The enemy is a plain Node2D (not a physics body) that doesn't block the player. A child Area2D handles overlap detection. `has_method("take_hit")` is a duck-typed check — no class dependency.

### Iframes

```gdscript
func take_hit(from: Vector2) -> void:
    if _iframes > 0.0:
        return
    _iframes = 0.8
```

The invincibility window prevents stun-locking: once hit, the player can't take another hit for 0.8 seconds.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.lerp(target, weight)` | Exponential decay toward zero each frame |
| `Area2D.body_entered` | Signals when CharacterBody2D enters overlap zone |
| `has_method("take_hit")` | Duck-typed signal dispatch without class coupling |
| `(player_pos - from).normalized()` | Direction vector from hit source away from source |
