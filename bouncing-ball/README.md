# Bouncing Ball

A ball that bounces around the screen using Godot's built-in rigid body physics engine — no manual velocity or collision code required.

## Purpose

This demo illustrates the difference between **kinematic movement** (you control velocity directly, as in most player characters) and **rigid body physics** (the engine simulates forces, momentum, and collisions). It shows that a `RigidBody2D` needs almost no code — you only need to define the collision shape and visual.

## How It Works

### Node Tree

```
Main (Node2D)
├── Ball (RigidBody2D)          ← ball.gd
│   ├── CollisionShape2D        (CircleShape2D, radius 20)
│   └── (visuals via _draw())
├── Walls (StaticBody2D ×4)    (top/bottom/left/right screen edges)
└── (background draw)
```

### `scripts/ball.gd`

```gdscript
extends RigidBody2D

func _draw() -> void:
    draw_circle(Vector2.ZERO, 20, Color.TOMATO)
    draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color(0.8, 0.2, 0.1), 2.0)
```

The script is almost entirely empty. It only provides `_draw()` for the visual. All movement, collision response, and energy conservation are handled by the physics engine.

The ball's initial velocity is set via the Inspector's `Linear Velocity` property (or could be set in code with `linear_velocity = Vector2(200, -300)`).

## RigidBody2D Theory

### Physics Simulation vs Kinematic Movement

| | CharacterBody2D | RigidBody2D |
|---|---|---|
| Velocity control | You set `velocity` directly | Engine integrates forces |
| Collision response | You handle it | Engine handles it |
| Gravity | You add it manually | Engine applies it |
| Best for | Player characters, enemies | Balls, crates, debris |

### How the Engine Steps the Ball

Each physics frame (60 Hz by default):
1. **Forces accumulate**: gravity (`980 px/s²` downward by default) is added to velocity.
2. **Position integration**: `position += velocity * delta`
3. **Collision detection**: shapes are checked against nearby bodies.
4. **Collision response**: velocity is reflected based on the surface normal and the body's `bounce` (physics material).

Setting `physics_material.bounce = 1.0` makes a perfectly elastic bounce — no energy is lost. The default bounce is `0.0`, so the ball would slow and stop. The scene sets bounce to 1.0 for continuous bouncing.

### StaticBody2D Walls

`StaticBody2D` is an immovable physics body — it can receive collisions but does not move. Four walls surround the viewport, acting as invisible barriers. Their collision shapes are `WorldBoundaryShape2D` or `RectangleShape2D` matching the screen edges.

### Why RigidBody2D Needs `queue_redraw()`

`_draw()` is only called when Godot marks the node as needing a redraw. `RigidBody2D` moves its visual automatically via the physics transform, but since `_draw()` renders at the node's local origin and the engine updates the node's **global transform**, the ball's visual follows the physics position without needing `queue_redraw()` each frame. The engine's transform sync triggers the redraw automatically.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `RigidBody2D` | Physics-simulated body |
| `RigidBody2D.linear_velocity` | Current velocity vector |
| `RigidBody2D.gravity_scale` | Multiplier on world gravity |
| `PhysicsMaterial.bounce` | Elasticity of collisions (0 = no bounce, 1 = perfect) |
| `StaticBody2D` | Immovable physics barrier |
| `draw_arc(center, radius, start, end, points, color, width)` | Partial circle outline |
