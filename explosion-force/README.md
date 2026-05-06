# Explosion Force

Click anywhere to detonate an explosion that flings nearby balls outward, with force that falls off linearly with distance and a visual shockwave ring that expands and fades.

## Purpose

Radial impulse from an explosion is one of the most-used effects in action games. *Minecraft* uses it for TNT, *Hades* for Poseidon's boons, *Enter the Gungeon* for barrel detonations. The same math — normalize a direction vector, scale by a falloff factor — also drives knockback from boss slams, grenade blasts, shockwave abilities, and physics-based puzzles.

Getting the falloff shape right is what separates satisfying explosions from weak ones. Inverse-linear falloff (`1 - dist/radius`) gives a gradual gradient: balls at the center feel a full kick, balls near the edge get just a nudge. This produces the characteristic "center flies, edge drifts" look. Inverse-square would be more physically accurate but concentrates too much force at the origin for gameplay purposes.

The shockwave ring is equally important for readability. Players need to understand the blast radius at a glance. An expanding ring that matches the force radius doubles as both feedback and tutorial — "anything inside that ring got hit."

## How It Works

### Impulse Calculation

When the player clicks, `_explode(epicenter)` fires for every ball within `EXPLOSION_RADIUS`:

```gdscript
func _explode(epicenter: Vector2) -> void:
    _shockwaves.append({pos = epicenter, radius = 0.0, alpha = 1.0})
    for ball in _balls:
        var diff := ball.pos - epicenter
        var dist := diff.length()
        if dist < EXPLOSION_RADIUS and dist > 0.1:
            ball.vel += diff.normalized() * EXPLOSION_STRENGTH * (1.0 - dist / EXPLOSION_RADIUS)
```

The direction is `diff.normalized()` — a unit vector pointing away from the epicenter toward the ball. The magnitude is `EXPLOSION_STRENGTH * (1 - dist / EXPLOSION_RADIUS)`, which scales from 1.0 at the center down to 0.0 at the edge. The guard `dist > 0.1` prevents a divide-by-zero when a ball sits exactly on the epicenter.

### Ball Physics

Each frame in `_process`:

```gdscript
ball.vel.y += GRAVITY * delta
ball.vel *= pow(DAMPING, delta)
ball.pos += ball.vel * delta
```

Gravity pulls balls down constantly, while `pow(DAMPING, delta)` applies frame-rate-independent drag. Balls bounce off all four screen edges with 30% energy loss (`* 0.7` on the reflected component).

### Shockwave Ring

Each shockwave is a dictionary with a growing `radius` and fading `alpha`:

```gdscript
sw.radius += 280.0 * delta
sw.alpha  -= 1.8 * delta
```

Faded shockwaves are removed each frame using `Array.filter`:

```gdscript
_shockwaves = _shockwaves.filter(func(sw): return sw.alpha > 0.0)
```

The ring reaches full size (`EXPLOSION_RADIUS = 180px`) in about 0.64 seconds, giving players time to see the blast area.

## The Falloff Formula

```
impulse_magnitude = EXPLOSION_STRENGTH * (1 - dist / EXPLOSION_RADIUS)
```

| Distance | Multiplier | Impulse |
|----------|-----------|---------|
| 0 px     | 1.00      | 450 px/s |
| 45 px    | 0.75      | 337 px/s |
| 90 px    | 0.50      | 225 px/s |
| 135 px   | 0.25      | 112 px/s |
| 180 px   | 0.00      | 0 px/s   |

Balls outside `EXPLOSION_RADIUS` are completely unaffected.

## How to Adapt This in Your Project

Replace `ball.vel +=` with `RigidBody2D.apply_central_impulse()` to use Godot's built-in physics. Change the falloff from linear to quadratic (`(1 - dist/radius)^2`) for a sharper center effect. Add a `damage` value calculated from the same falloff fraction to combine visual and gameplay impact in one pass. To limit which objects are affected, check a group or layer before applying the impulse. For 3D, use `Vector3` and iterate over `get_overlapping_bodies()` from a `SphereShape3D` query.

Pitfall: always guard against zero distance before calling `.normalized()`. Without the `dist > 0.1` check, a ball spawned exactly at the click point produces a zero vector that normalizes to `(NaN, NaN)` and corrupts the simulation.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.normalized()` | Unit direction vector for impulse direction |
| `Vector2.length()` | Distance from epicenter for falloff calculation |
| `pow(DAMPING, delta)` | Frame-rate-independent velocity damping |
| `Array.filter(callable)` | Remove expired shockwaves each frame |
| `draw_arc(center, radius, from, to, points, color, width)` | Shockwave ring visual |
| `InputEventMouseButton.position` | World position of the click for explosion origin |

## Controls

| Input | Action |
|-------|--------|
| Left Click | Detonate an explosion at cursor position |
| R | Randomize all ball positions and velocities |

## Key Constants

```gdscript
const BALL_COUNT        := 12     # Number of balls in the simulation
const EXPLOSION_RADIUS  := 180.0  # Maximum distance from epicenter that receives force (px)
const EXPLOSION_STRENGTH := 450.0 # Impulse applied at distance 0 (px/s)
const GRAVITY           := 300.0  # Downward acceleration (px/s²)
const DAMPING           := 0.99   # Per-second velocity multiplier (air resistance)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | All logic: explosion, ball physics, shockwave animation, drawing |
| `scenes/main.tscn` | Root Node2D with main.gd attached |
| `tests/test_logic.gd` | Unit tests for impulse magnitude and falloff math |
| `tests/test.tscn` | Scene that runs the tests |
