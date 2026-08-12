# Boid Flocking

35 agents self-organize into flocks via separation, alignment, and cohesion forces. No explicit leader — emergent group behavior from three simple per-agent rules applied each frame.

## Purpose

Flocking (Craig Reynolds' "boids" algorithm) demonstrates emergent behavior: complex group dynamics arise from local rules each agent applies independently. The same technique drives crowd AI, fish schools, and particle swarms in games.

## Controls

None — the flock simulates on its own. Tune the separation, alignment, and
cohesion weights in `scripts/boid.gd` and re-run to see the behaviour change.

## How It Works

### The three rules (`scripts/boid.gd`)

For each boid, find all neighbors within `NEIGHBOR_RADIUS`:

**Separation** — steer away from nearby boids to avoid crowding:
```gdscript
if dist < SEP_RADIUS:
    sep -= d.normalized() / dist  # stronger push the closer they are
```

**Alignment** — match the average velocity of neighbors:
```gdscript
var ali_desired := (ali / n).normalized() * MAX_SPEED
steering += (ali_desired - vel) * ALI_WEIGHT
```

**Cohesion** — steer toward the center of mass of neighbors:
```gdscript
var coh_desired := ((coh / n) - position).normalized() * MAX_SPEED
steering += (coh_desired - vel) * COH_WEIGHT
```

### Speed clamping

```gdscript
if spd > MAX_SPEED: vel = vel.normalized() * MAX_SPEED
elif spd < MIN_SPEED and spd > 0.001: vel = vel.normalized() * MIN_SPEED
```

A minimum speed prevents boids from stopping; a maximum prevents runaway acceleration.

### Edge wrapping

```gdscript
if position.x < 0.0:    position.x += vp.x
elif position.x > vp.x: position.x -= vp.x
```

Boids wrap around the viewport instead of bouncing, giving the illusion of an unbounded space.

### Dynamic spawn (`scripts/main.gd`)

```gdscript
var b := Node2D.new()
b.set_script(BoidScript)
add_child(b)
b.init(Vector2(randf_range(40, 600), randf_range(40, 440)))
```

Boids are created at runtime from a script reference — no scene file per boid needed.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.normalized()` | Direction without magnitude |
| `node.set_script(script)` | Attach script to a dynamically-created node |
| `randomize()` | Seed the RNG for non-repeating initial positions |
| `draw_polygon(points, colors)` | Triangle per boid with facing direction |

## Files

| File | What it holds |
|------|---------------|
| `scripts/boid.gd` | `boid` behaviour |
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/boid.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/boid.gd`**
- `init(pos: Vector2) -> void`
- `step(boids: Array, delta: float) -> void`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

