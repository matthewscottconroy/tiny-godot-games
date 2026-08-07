# Steering Behaviors

Eight autonomous agents demonstrate Craig Reynolds' classic steering behaviors — Seek/Arrive, Flee, and Wander — using force-based velocity accumulation with toroidal screen wrapping.

## Purpose

Steering behaviors are the building block of autonomous agent movement. They were formalized by Craig Reynolds in 1999 and remain the foundation of vehicle AI in games, robotics simulations, and crowd systems. A steering force is a Vector2 that says "I want to go this direction at this speed" minus "I am currently going this direction at this speed." Integrating many small steering forces per frame produces smooth, organic motion without keyframing.

Seek/Arrive is used for homing missiles, enemy pursuit, and pick-up magnets. Flee drives enemies that run from explosions or player weapons. Wander appears in idle NPC movement, patrol roaming, and procedural camera drift. Combining multiple behaviors with weighted summing (not shown here, but the natural extension) enables emergent group behaviors like swarming and escorting. The same architecture underlies Godot's built-in `NavigationAgent2D` and Unity's NavMesh agents at a higher level.

## How It Works

The steering math lives in a reusable class, `SteeringAgent`
(`scripts/steering_agent.gd`), a plain `RefCounted` holding `position` /
`velocity` plus one method per behaviour. `scripts/main.gd` is just the demo
driver: it spawns eight agents, feeds each the selected behaviour, wraps them on
screen, and draws them.

### Force Accumulation Loop (`scripts/main.gd`)

Each frame the driver asks the agent for a steering force and integrates it:

```gdscript
func _process(delta: float) -> void:
    for agent in _agents:
        var force := _steering_for(agent, delta)   # agent.seek/flee/wander
        agent.step(force, delta)                    # integrate + move
        # Toroidal wrap keeps everyone on screen (demo-specific, not steering).
        agent.position = Vector2(
            fposmod(agent.position.x, WORLD_SIZE.x),
            fposmod(agent.position.y, WORLD_SIZE.y),
        )
```

`SteeringAgent.step()` adds the force, caps speed with `limit_length` (magnitude
only, direction unchanged), and advances the position. `fposmod` wraps
coordinates toroidally so agents reappear on the opposite side — a demo concern,
which is why it lives in the driver rather than the reusable class.

### Seek / Arrive (`SteeringAgent.seek`)

```gdscript
func seek(target: Vector2) -> Vector2:
    var to_target := target - position
    var dist := to_target.length()
    var speed := max_speed
    if dist < arrive_radius:
        speed = max_speed * (dist / arrive_radius)   # linear deceleration
    var desired := to_target.normalized() * speed if dist > 0.01 else Vector2.ZERO
    return (desired - velocity).limit_length(max_force)
```

Arrive slows agents linearly within `arrive_radius` (60 px) so they stop smoothly instead of overshooting and oscillating.

### Flee (`SteeringAgent.flee`)

```gdscript
func flee(target: Vector2) -> Vector2:
    var to_target := target - position
    var dist := to_target.length()
    if dist < flee_radius and dist > 0.01:
        var desired := -to_target.normalized() * max_speed
        return (desired - velocity).limit_length(max_force)
    return (-velocity).limit_length(max_force)        # decelerate to rest
```

Outside `flee_radius` (150 px) agents gently decelerate rather than maintaining full speed, giving a natural "threat zone" feel.

### Wander (`SteeringAgent.wander`)

```gdscript
func wander(delta: float) -> Vector2:
    wander_angle += randf_range(-wander_jitter, wander_jitter) * delta
    var ahead := velocity.normalized() if velocity.length() > 0.1 else Vector2.RIGHT
    var target := position + ahead * wander_distance \
        + Vector2(cos(wander_angle), sin(wander_angle)) * wander_radius
    var to_target := target - position
    var desired := to_target.normalized() * max_speed if to_target.length() > 0.01 else Vector2.ZERO
    return (desired - velocity).limit_length(max_force)
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

This is Reynolds' **velocity matching** formulation. The steering force is the delta needed to reach the desired velocity, clamped to a maximum force that represents the agent's maximum acceleration. A higher `max_force` gives snappier, more responsive agents; a lower value gives sluggish, heavy motion.

**Wander geometry**: `wander_distance` (80 px) controls how far ahead the wander circle center is projected. A larger distance makes the agent commit more strongly to its current direction before turning. `wander_radius` (50 px) controls the amplitude of wandering. `wander_jitter` (90 radians/s) controls how fast the angle can change — high jitter = erratic, low jitter = sweeping curves.

## Use as a building block

**Copy:** `scripts/steering_agent.gd` (the `SteeringAgent` class). It is a plain
`RefCounted` with no scene or node dependencies.

**Public API**
- state: `position`, `velocity`
- tuning: `max_speed`, `max_force`, `arrive_radius`, `flee_radius`, `wander_radius`, `wander_distance`, `wander_jitter`
- behaviours (each returns a steering force): `seek(target)`, `flee(target)`, `wander(delta)`
- integration: `step(force, delta)`

**Integrate**
1. Create an agent per entity: `var agent := SteeringAgent.new()` and set `position`/`velocity`.
2. Each frame: `agent.step(agent.seek(target_pos), delta)`, then copy `agent.position` onto your sprite/`CharacterBody2D`.
3. Combine behaviours by summing forces with weights before `step()`:
   `agent.step(agent.seek(goal) * 0.7 + separation * 1.5, delta)` (clamp the sum to `max_force` if needed).

**Notes**
- `class_name SteeringAgent` is global to the project — rename if it collides.
- The demo drives plain positions and draws them; in a real project let the agent's `position` steer a `CharacterBody2D` (`velocity = agent.velocity; move_and_slide()`).
- Arrive (built into `seek`) is almost always preferable to pure seek for AI that stops at a destination — without it, agents orbit the target in tight jitter loops.
- For obstacle avoidance, cast a forward probe proportional to speed and add a force perpendicular to any hit surface before `step()`.

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

## Key Parameters

Tuning lives on `SteeringAgent` as plain fields (set per-agent in code); the
driver exposes `agent_count` as an `@export` on the demo node.

```gdscript
# SteeringAgent fields (defaults)
var max_speed       := 140.0   # px/s — terminal velocity
var max_force       := 200.0   # max steering acceleration (px/s²)
var arrive_radius   := 60.0    # slow-down zone for Seek
var flee_radius     := 150.0   # activation radius for Flee
var wander_radius   := 50.0    # radius of the wander circle
var wander_distance := 80.0    # how far ahead the circle is projected
var wander_jitter   := 90.0    # radians/s of random angle change

# main.gd
@export var agent_count := 8
```

## Files

| File | Purpose |
|------|---------|
| `scripts/steering_agent.gd` | **`SteeringAgent`** — reusable steering math (`seek`/`flee`/`wander`/`step`) |
| `scripts/main.gd` | Demo driver: spawns agents, selects behaviour, wraps + draws |
| `scenes/main.tscn` | `Node2D` root with `main.gd` attached |
| `tests/test_logic.gd` | Headless unit tests for each steering behavior |
| `tests/test.tscn` | Test runner scene |
