# Bouncing Ball

A ball that bounces around the screen using Godot's built-in rigid body physics engine — no manual velocity or collision code required.

## Purpose

Most player characters use `CharacterBody2D` where you control velocity directly and write collision responses yourself. But for objects that obey physical laws — balls, crates, debris, coins — writing that simulation manually is unnecessary work. `RigidBody2D` hands off velocity integration, gravity, and collision response entirely to the physics engine.

This distinction matters architecturally. In platformers, destructible environments scatter debris (RigidBody2D) while the player navigates (CharacterBody2D). In puzzle games, objects the player pushes are rigid bodies. In pinball games, the entire scene except the flippers is rigid body physics. Understanding when to use each body type is a fundamental Godot design decision.

This demo shows the minimum viable RigidBody2D: a ball with a collision shape, a `PhysicsMaterial` with `bounce = 1.0`, and four static wall barriers. The script contains almost no code — the engine does the work.

## Controls

None — the simulation runs on its own. Adjust the physics material and gravity
in the scene to change how the ball behaves.

## How It Works

### Node Tree

```
Main (Node2D)
├── Ball (RigidBody2D)           <- ball.gd (visual only)
│   └── CollisionShape2D         (CircleShape2D, radius 20)
├── TopWall    (StaticBody2D)    <- screen top edge
├── BottomWall (StaticBody2D)    <- screen bottom edge
├── LeftWall   (StaticBody2D)    <- screen left edge
└── RightWall  (StaticBody2D)    <- screen right edge
```

### The Ball Script

```gdscript
# scripts/ball.gd
extends RigidBody2D

func _draw() -> void:
    draw_circle(Vector2.ZERO, 20, Color.TOMATO)
    draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color(0.8, 0.2, 0.1), 2.0)
```

The entire script is just the visual. All movement, gravity, and collision response come from the engine. The ball's initial velocity is set in the Inspector via `Linear Velocity` (or in code: `linear_velocity = Vector2(200, -300)`). The `PhysicsMaterial` resource on the `RigidBody2D` has `bounce = 1.0` for a perfectly elastic bounce.

### Why _draw() Works Without queue_redraw()

`_draw()` renders at the node's local origin (0, 0). The physics engine updates the `RigidBody2D`'s global transform each physics frame, which automatically triggers a redraw. The visual follows the physics position without any manual `queue_redraw()` calls.

### StaticBody2D Walls

`StaticBody2D` is an immovable physics body — it receives collisions but never moves. Four walls are placed at the screen edges with `RectangleShape2D` collision shapes. When the ball's `CircleShape2D` contacts a wall's `RectangleShape2D`, the engine computes the collision normal, applies the bounce, and reflects velocity automatically.

## RigidBody2D Theory

### Physics Simulation vs. Kinematic Movement

| | CharacterBody2D | RigidBody2D |
|---|---|---|
| Velocity control | You set `velocity` directly | Engine integrates forces |
| Collision response | You write it | Engine handles it |
| Gravity | You add manually | Engine applies it |
| Best for | Player characters, enemies | Balls, crates, debris, projectiles |

### How the Engine Steps Each Frame

Each physics tick (60 Hz by default):

1. **Force accumulation** — gravity (`980 px/s²` downward) is added to the velocity vector.
2. **Position integration** — `position += velocity * delta`.
3. **Broadphase collision detection** — overlapping shape AABBs are found.
4. **Narrowphase + response** — exact collision normal is computed; velocity is reflected: `v_out = v_in - 2 * dot(v_in, n) * n`, then scaled by `bounce`.

Setting `PhysicsMaterial.bounce = 1.0` makes the reflection scale factor 1.0 (perfectly elastic — no energy lost). The default is 0.0 (all kinetic energy absorbed on contact).

### Disabling Gravity

Set `gravity_scale = 0.0` to make a RigidBody2D float in space — useful for space games or for objects that should only respond to explicit forces. The fragments in the `destructibles` demo use `gravity_scale = 1.2` (slightly stronger pull) for a satisfying drop.

## How to Adapt This in Your Project

- **Crate physics**: Use `RigidBody2D` with a `RectangleShape2D`. Set `mass` to make it feel heavier. Apply `apply_central_impulse(direction * force)` when the player pushes it.
- **Projectiles**: Use `RigidBody2D` with `gravity_scale = 0.0` and set `linear_velocity` at spawn. Connect `body_entered` to detect hits.
- **Debris on death**: Spawn multiple `RigidBody2D` fragments at the dead entity's position (see the `destructibles` demo) and set random `linear_velocity` and `angular_velocity`.
- **Limiting speed**: Override `_integrate_forces(state)` and clamp `state.linear_velocity` to a maximum magnitude — the only safe way to cap rigid body speed.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `RigidBody2D` | Physics-simulated body (engine controls velocity) |
| `RigidBody2D.linear_velocity` | Current velocity vector (readable and settable) |
| `RigidBody2D.gravity_scale` | Multiplier on world gravity (0 = weightless) |
| `RigidBody2D.apply_central_impulse(v)` | Apply instant force (no delta needed) |
| `RigidBody2D._integrate_forces(state)` | Override for custom force/velocity logic |
| `PhysicsMaterial.bounce` | Elasticity: 0 = dead stop, 1 = perfect bounce |
| `StaticBody2D` | Immovable physics barrier |
| `draw_arc(center, radius, start, end, pts, color, width)` | Partial circle outline |

## Key Constants

```gdscript
# Set in Inspector on the RigidBody2D node (not in script):
# Linear Velocity: Vector2(200, -300)   <- initial launch direction
# PhysicsMaterial.bounce: 1.0           <- perfectly elastic
```

## Files

| File | Purpose |
|------|---------|
| `scripts/ball.gd` | Visual rendering only (draw_circle + draw_arc) |
| `ball.gd` | Same script, placed at project root for direct reference |
| `scenes/main.tscn` | Ball, four StaticBody2D walls, PhysicsMaterial configuration |

## Use as a building block

**Copy:** `scripts/ball.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

