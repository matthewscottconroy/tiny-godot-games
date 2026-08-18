# Rigid Body

<!-- tags: physics, ui -->

Demonstrates `RigidBody2D` as a fully physics-driven object: click anywhere to spawn boxes and circles that fall, collide, and stack under gravity — all controlled by the physics engine with no manual velocity code.

## Purpose

`RigidBody2D` is Godot's fully-simulated physics body. Unlike `CharacterBody2D` (where you set velocity explicitly), a rigid body responds to gravity, forces, impulses, and collisions automatically. This demo shows how to create rigid bodies dynamically at runtime by constructing a node tree in code, and how to assign different collision shapes for different shapes.

## Controls

- **Left-click** anywhere in the scene to spawn an object at that position
- Objects alternate between boxes and circles
- Watch them fall, bounce, and pile up

## How It Works

### Node Tree (at runtime)

```
Main (Node2D)               ← main.gd
├── CountLabel (Label)
├── (static walls via _draw())
└── Body0 (RigidBody2D)     ← physics_body.gd  (created on click)
    └── CollisionShape2D
```

Each spawned body is created entirely in code.

### `scripts/main.gd`

```gdscript
func _spawn(pos: Vector2) -> void:
    var use_circle := count % 2 == 1

    var body := RigidBody2D.new()
    body.set_script(BodyScript)
    body.is_circle = use_circle
    body.body_color = colors[count % colors.size()]
    body.gravity_scale = 1.5
    body.position = pos

    var col := CollisionShape2D.new()
    if use_circle:
        var s := CircleShape2D.new()
        s.radius = 15.0
        col.shape = s
    else:
        var s := RectangleShape2D.new()
        s.size = Vector2(32, 32)
        col.shape = s
    body.add_child(col)
    add_child(body)
    count += 1
```

**Critical ordering:** `body.is_circle` and `body.body_color` are set **before** `add_child(body)`. When a node is added to the scene tree, `_ready()` runs immediately. If properties were set after `add_child()`, `_ready()` would have already run with the defaults.

`body.set_script(BodyScript)` assigns the script. `BodyScript` is preloaded:
```gdscript
const BodyScript = preload("res://scripts/physics_body.gd")
```

### `scripts/physics_body.gd`

```gdscript
extends RigidBody2D

var is_circle  := false
var body_color := Color.ORANGE

func _draw() -> void:
    if is_circle:
        draw_circle(Vector2.ZERO, 15.0, body_color)
    else:
        draw_rect(Rect2(-16, -16, 32, 32), body_color)

func _process(_delta: float) -> void:
    queue_redraw()
```

The script only provides the visual (`_draw()`) and `queue_redraw()` each frame to keep the visual in sync with the physics transform. All movement, gravity, and collision are handled by the engine.

## RigidBody2D Theory

### Simulation Model

At each physics step:
1. **Forces accumulate**: gravity (`(0, 980) * gravity_scale`), applied forces (`apply_force()`), and collision impulses
2. **Velocity integrates**: `velocity += force / mass * delta`
3. **Position integrates**: `position += velocity * delta`
4. **Collisions resolve**: shapes are tested for overlap; if overlapping, impulses are applied to separate them and conserve momentum

This is **Newtonian mechanics** simulated by Godot's physics engine (Godot Physics or Jolt, depending on project settings).

### gravity_scale

`gravity_scale = 1.5` makes these bodies fall 50% faster than the project's default gravity. Adjusting this per-body is useful for differentiated physics behavior: feathers (low scale), rocks (high scale).

### RigidBody2D vs CharacterBody2D

| | RigidBody2D | CharacterBody2D |
|---|---|---|
| Gravity | Automatic | Manual (add to velocity) |
| Velocity | Set via forces/impulses | Set directly |
| Collision response | Physics-calculated | Manual handling |
| Stack/pile behavior | Works naturally | Complex to implement |
| Best for | Debris, balls, crates | Players, enemies |

### Dynamic Node Creation

```gdscript
var body := RigidBody2D.new()   # allocate
body.set_script(BodyScript)     # attach script
body.is_circle = true           # set properties BEFORE add_child
body.add_child(col)             # build child tree
add_child(body)                 # enter scene tree → _ready() runs
```

The order matters: setting properties before `add_child` ensures `_ready()` runs with the correct values.

### CollisionShape2D at Runtime

A `RigidBody2D` requires at least one `CollisionShape2D` child with a `Shape2D` resource. Creating this in code:
```gdscript
var col   := CollisionShape2D.new()
var shape := CircleShape2D.new()
shape.radius = 15.0
col.shape    = shape
body.add_child(col)
```

The shape resource is attached to the `CollisionShape2D` before adding it to the body.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `RigidBody2D` | Fully physics-simulated body |
| `RigidBody2D.gravity_scale` | Gravity multiplier |
| `RigidBody2D.linear_velocity` | Current velocity (can be set for impulses) |
| `CollisionShape2D` | Shape container node |
| `CircleShape2D` / `RectangleShape2D` | Shape resources |
| `Node.set_script(script)` | Attach a script after construction |
| `Node.add_child(node)` | Add to scene tree (triggers _ready) |
| `InputEventMouseButton.position` | Screen position of click |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scripts/physics_body.gd` | `physics body` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/physics_body.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

## Related demos

- [joint-physics](../joint-physics) — A `PinJoint2D` pendulum chain and a `DampedSpringJoint2D` weight, built in code.
- [bouncing-ball](../bouncing-ball) — A ball bouncing via Godot's built-in rigid body physics — no manual velocity code.
- [destructibles](../destructibles) — Click boxes to shatter them into scattered `RigidBody2D` fragments.
- [boid-flocking](../boid-flocking) — 35 agents flock via separation, alignment, and cohesion — emergent behavior.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

