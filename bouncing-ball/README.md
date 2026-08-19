# Bouncing Ball

<!-- tags: physics -->

A ball that bounces around the screen using Godot's built-in rigid body physics engine — no manual velocity or collision code required.

## Purpose

Most player characters use `CharacterBody2D` where you control velocity directly and write collision responses yourself. But for objects that obey physical laws — balls, crates, debris, coins — writing that simulation manually is unnecessary work. `RigidBody2D` hands off velocity integration, gravity, and collision response entirely to the physics engine.

This distinction matters architecturally. In platformers, destructible environments scatter debris (RigidBody2D) while the player navigates (CharacterBody2D). In puzzle games, objects the player pushes are rigid bodies. In pinball games, the entire scene except the flippers is rigid body physics. Understanding when to use each body type is a fundamental Godot design decision.

This demo shows the minimum viable RigidBody2D: a ball with a collision shape, a `PhysicsMaterial` with `bounce = 0.85`, and four static wall barriers. The ball script contains almost no code — the engine does the work.

## Controls

| Input | Action |
|-------|--------|
| LMB | Drop the ball again from the top |

Adjust the physics material and gravity in the scene to change how it behaves.

## How It Works

### Node Tree

```
Main (Node2D)                    <- main.gd (draws the walls, handles the click)
├── Hint (Label)
├── Ball (RigidBody2D)           <- ball.gd (visual only)
│   └── CollisionShape2D         (CircleShape2D, radius 20)
├── Floor     (StaticBody2D)     <- screen bottom edge
├── Ceiling   (StaticBody2D)     <- screen top edge
├── LeftWall  (StaticBody2D)     <- screen left edge
└── RightWall (StaticBody2D)     <- screen right edge
```

### Drawing the Walls

A `StaticBody2D` with a `CollisionShape2D` is invisible at run time — collision
shapes are drawn by the editor, not by the game. This demo opened onto a ball
falling through empty space and rebounding off nothing, which is the one thing it
exists to show.

`main.gd` draws them, and reads each rectangle back out of the collision shape
rather than repeating it as a `ColorRect`:

```gdscript
var box := collider.shape as RectangleShape2D
rects.append(Rect2(body.position + collider.position - box.size * 0.5, box.size))
```

Derived rather than duplicated, so a wall cannot be drawn anywhere the physics
is not. The alternative — four `ColorRect`s positioned by hand — is one edit away
from a picture that disagrees with the simulation.

### Putting the Ball Back

Assigning to a `RigidBody2D`'s `position` does not work: the physics server owns
the transform and overwrites the assignment on the next step. `PhysicsServer2D`
is the supported way in, and the velocities have to be cleared separately or the
ball arrives at the top carrying the speed it had at the bottom.

```gdscript
PhysicsServer2D.body_set_state(_ball.get_rid(),
        PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, BALL_START))
PhysicsServer2D.body_set_state(_ball.get_rid(),
        PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
```

### The Ball Script

```gdscript
# scripts/ball.gd
extends RigidBody2D

func _draw() -> void:
    draw_circle(Vector2.ZERO, 20, Color.TOMATO)
    draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color(0.8, 0.2, 0.1), 2.0)
```

The entire script is just the visual. All movement, gravity, and collision response come from the engine. The ball's initial velocity is set in the Inspector via `Linear Velocity` (or in code: `linear_velocity = Vector2(200, -300)`). The `PhysicsMaterial` resource on the `RigidBody2D` has `bounce = 0.85`: high enough to keep bouncing for a while, short of the perfectly elastic 1.0 that would never settle.

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

`PhysicsMaterial.bounce` is that scale factor: 1.0 is perfectly elastic and loses nothing, the default 0.0 absorbs all of it on contact, and this demo's 0.85 loses 15% of the speed at each impact — which is why the rebound is visibly lower every time.

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
# Set in the scene on the RigidBody2D node, not in script:
# PhysicsMaterial.bounce:   0.85   <- lossy, so the rebounds get shorter
# PhysicsMaterial.friction: 0.05   <- nearly frictionless walls
```

The ball starts at rest at `(320, 60)` and is dropped by gravity alone. Giving it
a `linear_velocity` in the scene would launch it instead, which is the same demo
with one more thing to explain.

## Files

| File | Purpose |
|------|---------|
| `scripts/ball.gd` | Visual rendering only (draw_circle + draw_arc) |
| `scripts/main.gd` | Draws the walls from their collision shapes; click to reset |
| `scenes/main.tscn` | Ball, four StaticBody2D walls, PhysicsMaterial configuration |

## Use as a building block

**Copy:** `scripts/main.gd` — `wall_rects()` is the reusable half, turning any
set of rectangular static bodies into something you can see while you build the
level.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

## Related demos

- [destructibles](../destructibles) — Click boxes to shatter them into scattered `RigidBody2D` fragments.
- [joint-physics](../joint-physics) — A `PinJoint2D` pendulum chain and a `DampedSpringJoint2D` weight, built in code.
- [rigid-body](../rigid-body) — `RigidBody2D` objects that fall, collide, and stack under gravity.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

