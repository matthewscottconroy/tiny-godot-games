# Wind Effect

Simulates 80 wind-blown leaf particles with direction-angle control, sinusoidal gust variation, velocity damping, per-particle lifetime fade, and motion-blur rendering using `draw_line`.

## Purpose

Environmental particle systems give a world atmosphere and a sense of scale that static art cannot. Wind-blown leaves, falling snow, rising ash — these effects tell the player about the world state (is it stormy? calm? magical?) without a single line of narrative text. They also make levels feel alive when nothing gameplay-critical is happening.

This demo avoids Godot's built-in `GPUParticles2D` intentionally. Instead it implements the particle loop from scratch in GDScript, making every simulation decision explicit: how forces accumulate, how drag works, how lifetime and alpha connect, and how to draw direction-aware motion blur. Understanding this loop is a prerequisite for writing custom particle behaviors that `GPUParticles2D` cannot express.

## How It Works

### Particle Data

Each particle is a Dictionary with position, velocity, size, alpha, color, and lifetime:

```gdscript
func _spawn_particle() -> Dictionary:
    var edge: int = randi() % 2   # 0=top, 1=left
    # ...spawn position at screen edge...
    return {
        "pos":          Vector2(...),
        "vel":          Vector2(randf_range(-10, 10), randf_range(-5, 5)),
        "size":         randf_range(2.0, 6.0),
        "alpha":        1.0,
        "color":        LEAF_COLORS[randi() % 6],
        "lifetime":     randf_range(3.0, 8.0),
        "max_lifetime": same as lifetime,
    }
```

Particles spawn from the top or left edge (the upwind sides) with a small random initial velocity. This creates the appearance of leaves blowing in from off-screen.

### Physics Update (`scripts/main.gd`)

```gdscript
var effective_wind := Vector2(cos(_wind_angle), sin(_wind_angle)) \
    * (_wind_strength + sin(_time * 0.7) * 20.0)

for p in _particles:
    p["vel"] += effective_wind * delta + Vector2(0.0, GRAVITY * delta)
    p["vel"] *= 0.98                       # air resistance (drag)
    p["pos"] += p["vel"] * delta
    p["lifetime"] -= delta
    p["alpha"] = p["lifetime"] / p["max_lifetime"]
```

Three forces act on each particle per frame:

1. **Wind force**: `effective_wind * delta` — direction set by `_wind_angle`, magnitude by `_wind_strength` plus a slow sine gust.
2. **Gravity**: constant downward acceleration of `GRAVITY = 40.0 px/s²`.
3. **Drag**: velocity multiplied by `0.98` every frame. At 60fps, this is `0.98^60 ≈ 0.30` per second — meaning particles lose about 70% of their velocity per second to air resistance. This prevents runaway acceleration and gives a terminal-velocity feel.

### Sinusoidal Gust Variation

```gdscript
_wind_strength + sin(_time * 0.7) * 20.0
```

The `sin(_time * 0.7)` term has a period of `2π / 0.7 ≈ 9 seconds`. Every nine seconds the wind completes a full gust cycle, varying ±20 px/s around the base strength. This low-frequency variation makes the wind feel natural rather than constant.

### Lifetime and Alpha Fade

```gdscript
p["alpha"] = p["lifetime"] / p["max_lifetime"]
```

Alpha is simply the fraction of lifetime remaining — a linear fade from 1.0 at spawn to 0.0 at death. Combined with the random lifetime (3–8 seconds) and random initial position, particles are desynchronized naturally.

### Motion Blur via `draw_line`

```gdscript
var vel_len: float = vel.length()
if vel_len > 5.0:
    var tail: Vector2 = pos - vel.normalized() * minf(vel_len * 0.08, sz * 1.5)
    draw_line(pos, tail, col, sz * 0.6)
else:
    draw_circle(pos, sz * 0.5, col)
```

Fast particles render as a short line segment pointing backward from their current position. The tail length is `vel.length() * 0.08`, capped at `size * 1.5` to prevent overly long streaks. This is a fake motion blur — it doesn't require multiple samples — but produces a convincing impression of speed at minimal cost.

### Wind Direction Indicator

A compass circle in the top-right corner shows wind direction as a yellow arrow. Arrow length is remapped from `[0, 200]` (strength range) to `[5, 24]` (arrow pixel length):

```gdscript
var arrow_len: float = remap(_wind_strength, 0.0, 200.0, 5.0, 24.0)
```

The arrowhead is two lines rotated ±perpendicular from the shaft tip, drawn manually without any helper node.

## How to Adapt This in Your Project

- **Snow**: Set `GRAVITY` to 20.0 (light), `_wind_strength` to 30.0, use white/pale blue colors, set `_cycle_speed` slow. Spawn from the top edge only.
- **Ash/embers**: Spawn from a point source (e.g., a fire position) rather than screen edges. Add slight upward initial velocity. Use orange/red colors.
- **Directional leaves on moving player**: Set `_wind_angle` based on the negative of the player's velocity direction. As the player runs right, leaves blow left relative to the player.
- **GPUParticles2D migration**: The per-particle dictionary data maps directly to `GPUParticles2D` particle attributes. Port the force calculations to a `process_material` (ParticleProcessMaterial) for GPU execution.
- **Pitfall**: Using a `for` loop over 80 dictionaries at 60fps is fine. Scaling to 500+ particles will stall the main thread. Use `PackedVector2Array` for position/velocity instead of dictionaries for large particle counts.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `randf_range(min, max)` | Random float in range |
| `randi() % n` | Random integer index |
| `draw_line(from, to, color, width)` | Motion blur streak per particle |
| `draw_circle(pos, radius, color)` | Dot rendering for slow particles |
| `remap(value, in_min, in_max, out_min, out_max)` | Scale arrow length to wind strength |
| `Vector2(cos(a), sin(a))` | Unit direction vector from angle |

## Controls

| Key | Action |
|-----|--------|
| Left Arrow | Rotate wind direction counter-clockwise (−0.2 rad) |
| Right Arrow | Rotate wind direction clockwise (+0.2 rad) |
| Up Arrow | Increase wind strength (max 200 px/s) |
| Down Arrow | Decrease wind strength (min 0 px/s) |

## Key Constants

```gdscript
const PARTICLE_COUNT := 80     # total simultaneous particles
const GRAVITY        := 40.0   # downward acceleration (px/s²)
_wind_strength       = 60.0    # initial wind force (px/s)
_cycle_speed (gust)  = sin(_time * 0.7) * 20.0  # ±20 px/s gust variation
drag_per_frame       = 0.98    # velocity multiplier (≈70% loss/second)
lifetime_range       = 3.0..8.0 seconds
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Particle spawn/update/respawn, wind physics, motion blur drawing, wind indicator |
| `scenes/main.tscn` | Single Node2D scene |
| `tests/test.tscn` | Unit tests for wind vector calculation and particle lifetime |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

