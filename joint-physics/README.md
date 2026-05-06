# Joint Physics

Demonstrates Godot's two most useful 2D joints side by side: a `PinJoint2D` pendulum chain (left) and a `DampedSpringJoint2D` hanging weight (right), with all bodies and joints created entirely in code at runtime.

## Purpose

Joints are the foundation of physical objects that need to stay connected while still moving: chain bridges, ragdolls, vehicle suspension, swinging doors, and destructible scaffolding. Rather than manually enforcing distance constraints each frame (as in the rope-physics demo), joints delegate that work to Godot's physics solver, which handles constraint resolution automatically and robustly.

`PinJoint2D` is a rigid pivot — the two connected bodies share a single world point they can rotate around but never separate from. This is what you want for pendulums, door hinges, and chain links. `DampedSpringJoint2D` adds elasticity: the bodies are pulled toward a rest length by a configurable spring force, with a damping coefficient to bleed energy over time. This is what you want for bouncy platforms, vehicle suspension, and cloth that sags.

Knowing when to choose each joint — and how to configure their parameters — is the key lesson. This demo lets you see both behaviors simultaneously so the difference is immediately obvious.

## How It Works

### Runtime Body and Joint Creation

All physics bodies are created in `_ready()` using factory helpers rather than a designed scene. This pattern is common for procedurally generated levels, chains of variable length, or any object whose topology isn't known at edit time.

```gdscript
func _make_rigid_circle(pos: Vector2, radius: float) -> RigidBody2D:
    var body := RigidBody2D.new()
    var col  := CollisionShape2D.new()
    var cs   := CircleShape2D.new()
    cs.radius = radius
    col.shape = cs
    body.add_child(col)
    body.position = pos
    add_child(body)
    return body
```

`StaticBody2D` anchors are created the same way. The critical step is `add_child(body)` before setting `body.position` — Godot requires the node to be in the scene tree before its physics properties take effect.

### PinJoint2D — Rigid Pivot

```gdscript
func _pin(body_a: Node2D, body_b: Node2D, world_pos: Vector2) -> void:
    var joint := PinJoint2D.new()
    joint.position = world_pos
    add_child(joint)
    joint.node_a = body_a.get_path()
    joint.node_b = body_b.get_path()
```

The joint's `position` is the world-space pin point — where the two bodies are locked together. Godot records each body's offset from this point at creation time. The pendulum chain pins each link at the position of the previous link's center, creating a classic chain. The first link in the chain gets a horizontal offset of `-30px` to start with a nonzero angle and trigger swinging immediately.

### DampedSpringJoint2D — Elastic Connection

```gdscript
func _spring(body_a: Node2D, body_b: Node2D, stiffness: float, damping: float) -> void:
    var dist  := body_a.position.distance_to(body_b.position)
    var joint := DampedSpringJoint2D.new()
    joint.position    = (body_a.position + body_b.position) * 0.5
    joint.length      = dist
    joint.rest_length = dist * 0.80
    joint.stiffness   = stiffness
    joint.damping     = damping
    add_child(joint)
    joint.node_a = body_a.get_path()
    joint.node_b = body_b.get_path()
}
```

Setting `rest_length` to 80% of the natural distance pre-tensions the spring: it immediately tries to pull the weight upward, creating a visible sag and a restoring bounce when disturbed. Two springs attach diagonally from the left and right anchors so the weight hangs stably in the center rather than swinging to one side.

## DampedSpringJoint2D Parameters

| Parameter | Effect | Demo Value |
|-----------|--------|------------|
| `length` | Natural length — zero force at this distance | Anchor-to-weight distance |
| `rest_length` | Target the spring tries to reach | 80% of natural length |
| `stiffness` | Spring constant (`k`) — higher = faster oscillation | `30.0` |
| `damping` | Energy dissipation — higher = oscillation dies faster | `2.0` |

Increasing `stiffness` to 200+ makes the spring feel like rubber; dropping `damping` below 0.5 causes prolonged bouncing.

## Interaction

Left-click applies an impulse to the bottom pendulum bob, right-click applies a random impulse to the spring weight:

```gdscript
if event.button_index == MOUSE_BUTTON_LEFT:
    var last := _pend_bodies.back() as RigidBody2D
    if last:
        last.apply_central_impulse(Vector2(220, -80))
elif event.button_index == MOUSE_BUTTON_RIGHT:
    if _spring_weight:
        _spring_weight.apply_central_impulse(Vector2(randf_range(-180, 180), -250))
```

`apply_central_impulse` is an instantaneous velocity change at the body's center of mass (no torque). The pendulum gets a fixed diagonal kick; the spring weight gets a random horizontal component each time for varied behavior.

## How to Adapt This in Your Project

For a chain bridge, create a row of `RigidBody2D` nodes pinned together in a horizontal line with static anchors at the ends. For ragdoll limbs, pin body segments at joint positions (shoulder, elbow, knee) and set angular limits using `PinJoint2D.softness`. For vehicle suspension, use `DampedSpringJoint2D` between the chassis and each wheel body with high stiffness and moderate damping. To make joints breakable, call `joint.queue_free()` when the bodies' separation exceeds a threshold.

Pitfall: always `add_child()` a body before assigning it to a joint's `node_a`/`node_b`. If the node isn't in the scene tree yet, `get_path()` returns an empty `NodePath` and the joint silently does nothing.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `PinJoint2D` | Rigid pivot joint — connected bodies rotate around a fixed world point |
| `PinJoint2D.node_a`, `.node_b` | `NodePath` references to the two connected bodies |
| `DampedSpringJoint2D` | Spring-damper joint with configurable stiffness and energy loss |
| `DampedSpringJoint2D.rest_length` | Target spring length (pull bodies toward this distance) |
| `DampedSpringJoint2D.stiffness` | Spring constant — higher values oscillate faster |
| `DampedSpringJoint2D.damping` | Energy dissipation — higher values settle faster |
| `RigidBody2D.apply_central_impulse(impulse)` | Instantaneous velocity change at center of mass |
| `RigidBody2D.linear_damp` | Per-body drag independent of the joint damping |

## Controls

| Input | Action |
|-------|--------|
| Left Click | Apply impulse to the bottom pendulum bob |
| Right Click | Apply random impulse to the spring weight |

## Key Constants

```gdscript
const LINK_COUNT    := 5      # Number of links in the pendulum chain
const LINK_SPACING  := 50.0   # Vertical distance between pendulum link centers (px)
const SPRING_GAP    := 90.0   # Half-distance between the two spring anchors (px)
# Spring joint parameters (passed to _spring()):
# stiffness = 30.0, damping = 2.0, rest_length = 80% of natural distance
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Body/joint factory helpers, pendulum and spring scene builders, interaction, drawing |
| `scenes/main.tscn` | Root Node2D with main.gd attached; all physics created at runtime |
