# Steering Behaviors

Eight autonomous agents demonstrate Craig Reynolds' classic steering behaviors — Seek/Arrive, Flee, and Wander — using force-based velocity accumulation with toroidal screen wrapping.

## Purpose

Steering behaviors are the building block of autonomous agent movement. They were formalized by Craig Reynolds in 1999 and remain the foundation of vehicle AI in games, robotics simulations, and crowd systems. A steering force is a Vector2 that says "I want to go this direction at this speed" minus "I am currently going this direction at this speed." Integrating many small steering forces per frame produces smooth, organic motion without keyframing.

Seek/Arrive is used for homing missiles, enemy pursuit, and pick-up magnets. Flee drives enemies that run from explosions or player weapons. Wander appears in idle NPC movement, patrol roaming, and procedural camera drift. Combining multiple behaviors with weighted summing (not shown here, but the natural extension) enables emergent group behaviors like swarming and escorting. The same architecture underlies Godot's built-in `NavigationAgent2D` and Unity's NavMesh agents at a higher level.

## How It Works

### Force Accumulation Loop (`scripts/main.gd`)

Each frame, a steering force is computed per agent and added to its velocity:

```gdscript
func _process(delta: float) -> void:
    for agent in _agents:
        var steering := _compute_steering(agent, delta)
        agent["vel"] += steering * delta
        agent["vel"] = (agent["vel"] as Vector2).limit_length(MAX_SPEED)
        agent["pos"] += agent["vel"] * delta
        agent["pos"] = Vector2(
            fposmod(agent["pos"].x, 640.0),
            fposmod(agent["pos"].y, 480.0)
        )
```

`limit_length` caps speed without changing direction. `fposmod` wraps coordinates toroidally so agents reappear on the opposite side.

### Seek / Arrive

```gdscript
Behavior.SEEK:
    var to_target := _target - pos
    var dist := to_target.length()
    var speed := MAX_SPEED
    if dist < ARRIVE_RADIUS:
        speed = MAX_SPEED * (dist / ARRIVE_RADIUS)  # linear deceleration
    if dist > 0.01:
        desired = to_target.normalized() * speed
    steering = desired - vel
    steering = steering.limit_length(MAX_FORCE)
```

Arrive slows agents linearly within `ARRIVE_RADIUS` (60 px) so they stop smoothly instead of overshooting and oscillating.

### Flee

```gdscript
Behavior.FLEE:
    var to_target := _target - pos
    var dist := to_target.length()
    if dist < FLEE_RADIUS and dist > 0.01:
        desired = -to_target.normalized() * MAX_SPEED
        steering = desired - vel
        steering = steering.limit_length(MAX_FORCE)
    else:
        steering = -vel.limit_length(MAX_FORCE)  # decelerate to rest
```

Outside `FLEE_RADIUS` (150 px) agents gently decelerate rather than maintaining full speed, giving a natural "threat zone" feel.

### Wander

```gdscript
Behavior.WANDER:
    agent["wander_angle"] += randf_range(-WANDER_JITTER, WANDER_JITTER) * delta
    var ahead := vel.normalized() if vel.length() > 0.1 else Vector2(1, 0)
    var wander_target := pos + ahead * WANDER_DIST
                           + Vector2(cos(wander_angle), sin(wander_angle)) * WANDER_RADIUS
    var to_wander := wander_target - pos
    desired = to_wander.normalized() * MAX_SPEED
    steering = desired - vel
    steering = steering.limit_length(MAX_FORCE)
```

The wander target is a point on a circle projected ahead of the agent. Jittering the angle of that circle each frame produces smooth, curved trajectories. Because the circle is always in front of the agent, direction changes are gradual — no sharp 180° reversals.

## Steering Theory

All three behaviors use the same fundamental formula:

```
desired_velocity = direction * desired_speed
steering_force   = desired_velocity - current_velocity
steering_force   = clamp(steering_force, MAX_FORCE)
velocity        += steering_force * delta
```

This is Reynolds' **velocity matching** formulation. The steering force is the delta needed to reach the desired velocity, clamped to a maximum force that represents the agent's maximum acceleration. A higher `MAX_FORCE` gives snappier, more responsive agents; a lower value gives sluggish, heavy motion.

**Wander geometry**: `WANDER_DIST` (80 px) controls how far ahead the wander circle center is projected. A larger distance makes the agent commit more strongly to its current direction before turning. `WANDER_RADIUS` (50 px) controls the amplitude of wandering. `WANDER_JITTER` (90 radians/s) controls how fast the angle can change — high jitter = erratic, low jitter = sweeping curves.

## How to Adapt This in Your Project

- To combine behaviors, compute each steering force separately and sum them with weights: `steering = seek * 0.7 + separation * 1.5`. Normalize if the total exceeds `MAX_FORCE`.
- For a chase enemy that gives up, add a maximum speed to the pursued target and trigger a flee behavior instead when the enemy cannot catch up.
- Arrive is almost always preferable to pure Seek for any AI that stops at a destination — without it, agents orbit the target in tight jitter loops.
- To add obstacle avoidance, cast a forward probe of length proportional to speed and apply a steering force perpendicular to any hit surface.
- `WANDER_JITTER` is a frame-rate-dependent quantity (radians per second). The `* delta` multiplication already makes it frame-rate independent.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.limit_length(max)` | Cap vector magnitude without changing direction |
| `Vector2.normalized()` | Unit vector — direction only |
| `Vector2.length()` | Magnitude for distance checks |
| `fposmod(value, modulus)` | Positive modulo for toroidal wrapping |
| `randf_range(min, max)` | Random float for wander jitter |
| `draw_polygon(pts, colors)` | Draw arrow-shaped agents |
| `InputEventMouseMotion` | Capture mouse position as steering target |

## Controls

| Key / Input | Action |
|-------------|--------|
| S | Switch all agents to Seek / Arrive |
| F | Switch all agents to Flee |
| W | Switch all agents to Wander |
| Mouse | Move the seek / flee target (yellow crosshair) |

The active behavior name appears in the top-right corner. The target crosshair is hidden in Wander mode.

## Key Constants

```gdscript
const AGENT_COUNT   := 8
const MAX_SPEED     := 140.0   # px/s — terminal velocity
const MAX_FORCE     := 200.0   # max steering acceleration (px/s²)
const ARRIVE_RADIUS := 60.0    # slow-down zone for Seek
const FLEE_RADIUS   := 150.0   # activation radius for Flee
const WANDER_RADIUS := 50.0    # radius of the wander circle
const WANDER_DIST   := 80.0    # how far ahead the circle is projected
const WANDER_JITTER := 90.0    # radians/s of random angle change
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | All logic: agent initialization, `_compute_steering()`, `_draw()` |
| `scenes/main.tscn` | `Node2D` root with `main.gd` attached |
| `tests/test_logic.gd` | Headless unit tests for each steering behavior |
| `tests/test.tscn` | Test runner scene |
