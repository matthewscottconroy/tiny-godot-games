# Joint Physics

Demonstrates `PinJoint2D` (rigid pivot, left side) and `DampedSpringJoint2D` (elastic spring, right side) — building a pendulum chain and a hanging spring weight entirely in code.

## Purpose

Joints connect physics bodies without manual constraint math. `PinJoint2D` creates a hinge that allows rotation but prevents separation — ideal for chains, ragdolls, and rope bridges. `DampedSpringJoint2D` adds elasticity with configurable stiffness and damping — ideal for suspension, bouncy platforms, and cloth simulation. This demo shows both at once so you can feel the difference.

## Controls

- **Left-click**: Apply an impulse to the bottom of the pendulum chain
- **Right-click**: Apply a random impulse to the spring weight

## How It Works

### Node Tree

All physics bodies and joints are created dynamically in `_ready()`. The scene only contains the root `Node2D` and a `HUD`.

### `scripts/main.gd`

- **`_make_rigid_circle(pos, radius)`** — Creates a `RigidBody2D` with a `CircleShape2D` collision shape and adds it to the scene.
- **`_make_static_circle(pos, radius)`** — Same, but `StaticBody2D` (immovable anchor).
- **`_pin(body_a, body_b, world_pos)`** — Creates a `PinJoint2D` at `world_pos`. The joint constrains both bodies to pass through that point, allowing them to rotate freely around it.
- **`_spring(body_a, body_b, stiffness, damping)`** — Creates a `DampedSpringJoint2D` connecting the two bodies. `rest_length` is 80% of their initial distance, so the spring immediately applies a restoring force.
- **`_draw_spring_line(a, b)`** — Draws a zigzag line between two points to visualize the spring (Godot doesn't draw joints automatically).

### PinJoint2D Mechanics

```gdscript
var pin := PinJoint2D.new()
pin.position = upper_body.position  # pin point in world space
add_child(pin)
pin.node_a = upper_body.get_path()
pin.node_b = lower_body.get_path()
```

The joint's world position is where the two bodies are pinned together. At initialization, Godot computes each body's offset from the pin point. These offsets are maintained throughout the simulation, allowing the bodies to rotate around the pin while maintaining their relative distances.

### DampedSpringJoint2D Parameters

| Parameter | Effect |
|-----------|--------|
| `length` | Natural length — no force at this distance |
| `rest_length` | Target length the spring tries to reach |
| `stiffness` | Spring constant — higher = stiffer, faster oscillation |
| `damping` | Energy loss — higher = oscillation dies faster |

Setting `rest_length < length` creates a pre-tensioned spring that pulls the bodies closer.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `PinJoint2D` | Rigid pivot joint between two physics bodies |
| `PinJoint2D.node_a`, `.node_b` | NodePaths to the connected bodies |
| `DampedSpringJoint2D` | Spring-damper joint |
| `DampedSpringJoint2D.length` | Natural (zero-force) spring length |
| `DampedSpringJoint2D.rest_length` | Target length the spring seeks |
| `DampedSpringJoint2D.stiffness` | Restoring force coefficient |
| `DampedSpringJoint2D.damping` | Energy dissipation coefficient |
| `RigidBody2D.apply_central_impulse(impulse)` | Instant velocity change |
