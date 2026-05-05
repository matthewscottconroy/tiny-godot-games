# Pushable Blocks

Two CharacterBody2D objects — player and blocks — where the player can shove blocks by walking into them. Demonstrates reading collision data after `move_and_slide()` to drive interactions between physics bodies.

## Purpose

Godot's CharacterBody2D doesn't push other CharacterBody2D objects automatically — they just stop against each other. The solution: after `move_and_slide()`, inspect each slide collision; if the collider is a pushable block, apply a velocity impulse to it directly. This is cleaner than RigidBody2D for gameplay-controlled objects.

## Controls

- **Arrow keys / WASD**: Move
- **Up**: Jump

## How It Works

### `scripts/player.gd` — detecting and pushing

```gdscript
move_and_slide()

for i in get_slide_collision_count():
    var col  := get_slide_collision(i)
    var body := col.get_collider()
    if body is CharacterBody2D and body.is_in_group("pushable"):
        body.push(-col.get_normal().x * PUSH_STR)
```

`get_normal()` returns the surface normal pointing **from the block toward the player**. Negating it gives the push direction (into the block). Only the X component is used — no launching blocks upward.

### `scripts/pushable.gd` — velocity with friction

```gdscript
func push(horizontal_strength: float) -> void:
    _push_vel = horizontal_strength

func _physics_process(delta: float) -> void:
    velocity.x = _push_vel
    _push_vel  = lerpf(_push_vel, 0.0, FRICTION * delta)
    if absf(_push_vel) < 1.0:
        _push_vel = 0.0
    move_and_slide()
```

`_push_vel` is separate from `velocity` to allow stacking a push impulse on top of normal physics. `lerpf` with a constant gives exponential decay — feels more natural than linear.

### Why not RigidBody2D?

RigidBody2D responds to forces automatically but is harder to control predictably. CharacterBody2D gives exact, gameplay-tunable behavior. The tradeoff: you handle the push math yourself.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `get_slide_collision_count()` | Number of surfaces the character touched this frame |
| `get_slide_collision(i)` | KinematicCollision2D for the i-th contact |
| `col.get_collider()` | The physics body that was hit |
| `col.get_normal()` | Surface normal at the contact point |
| `is_in_group("pushable")` | Group membership check for type filtering |
