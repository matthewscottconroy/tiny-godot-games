# Magnet

Ten metallic balls respond to an inverse-square force field from a draggable horseshoe magnet. Toggle between attraction and repulsion with a keypress; watch the field lines reverse direction and the balls scatter or swarm.

## Purpose

Inverse-square force fields appear throughout game development beyond magnets: gravity wells in space shooters (*Osmos*, *Space Engine*), black hole effects that pull projectiles off course, area-denial abilities that push enemies back, homing behavior where the pull force decreases with distance, and treasure-magnet powerups in action RPGs. The underlying math — `force = strength / distance²` — is one of the most reused patterns in physics-driven games.

The attract/repel toggle also illustrates a design pattern that shows up constantly: a single force implementation parameterized by sign. Rather than writing separate attraction and repulsion functions, flipping the direction vector handles both cases. This same approach applies to charged particles, magnetic poles, and any bipolar effect.

The stability guards (minimum distance clamp and force cap) are just as important as the force formula itself. Without them, objects that cluster near the source produce infinite forces that crash the simulation.

## How It Works

### Inverse-Square Force

Each frame, every ball receives a force from the magnet:

```gdscript
var diff           := _magnet_pos - ball["pos"]
var dist           := maxf(diff.length(), MIN_DIST)
var force_magnitude := MAGNET_STRENGTH / (dist * dist)
force_magnitude    = minf(force_magnitude, MAX_FORCE)
var force_dir      := diff.normalized() if _attract else -diff.normalized()
ball["vel"] += force_dir * force_magnitude * delta
```

`MAGNET_STRENGTH / dist²` gives the raw force. `maxf(dist, MIN_DIST)` clamps the denominator to at least 30px, preventing division-by-near-zero. `minf(magnitude, MAX_FORCE)` caps the result at 600 units, preventing runaway acceleration when balls cluster at the magnet.

### Attract vs. Repel

The only difference between attraction and repulsion is the sign of `force_dir`:

```gdscript
var force_dir := diff.normalized() if _attract else -diff.normalized()
```

`diff` points from the ball toward the magnet. In attract mode, force pushes the ball toward the magnet. In repel mode, the force pushes it away. The magnitude calculation is identical in both cases.

### Velocity Damping

Damping is applied as a frame-rate-independent multiplier:

```gdscript
ball["vel"] *= pow(DAMPING, delta * 60.0)
```

The `delta * 60.0` factor normalizes to 60 fps — `DAMPING = 0.992` means about 99.2% velocity retained per 1/60 second frame. Without damping, attracted balls would oscillate around the magnet forever; with it, they spiral in and settle.

### Field Line Visualization

The dashed radial field lines are drawn as short segments that point toward or away from the magnet depending on mode:

```gdscript
if _attract:
    draw_line(_magnet_pos + dir * r1, _magnet_pos + dir * r0, c, 1.5)
else:
    draw_line(_magnet_pos + dir * r0, _magnet_pos + dir * r1, c, 1.5)
```

The segment direction is reversed between modes so the "arrows" point the right way. Alpha fades with `seg` index to show the field weakening at distance.

## The Inverse-Square Law

```
force = MAGNET_STRENGTH / dist²
```

The quadratic denominator means doubling distance quarters the force. This creates the characteristic "dramatic close range, negligible far range" behavior:

| Distance | Force (uncapped) |
|----------|-----------------|
| 30 px (MIN_DIST) | 20.0 units |
| 60 px    | 5.0 units |
| 120 px   | 1.25 units |
| 240 px   | 0.31 units |

Compare to the explosion demo's linear falloff: inverse-square has a much sharper gradient near the source, which suits a magnet that "snaps" nearby objects.

## How to Adapt This in Your Project

For a coin magnet powerup, replace the draggable position with the player position and set `_attract = true`. Add a radius check before the force calculation to limit range (or just rely on the natural falloff — force at 300px is negligible with these constants). For an enemy that repels player projectiles, attach this force calculation to the projectile velocity instead of the enemy. For a gravity well, disable the `MAX_FORCE` cap and increase `MIN_DIST` to taste. Use `MAGNET_GRAB_RADIUS` as a model for making other draggable objects in your UI.

Pitfall: the `pow(DAMPING, delta * 60.0)` formulation assumes DAMPING is calibrated for 60fps. If you switch to a different reference framerate, update the multiplier to match, or switch to `pow(DAMPING_PER_SECOND, delta)` where `DAMPING_PER_SECOND` is the fraction remaining after one full second.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `maxf(a, b)` | Clamps minimum distance to prevent division-by-near-zero |
| `minf(a, b)` | Caps maximum force magnitude for stability |
| `Vector2.normalized()` | Unit direction vector for force application |
| `pow(DAMPING, delta * 60.0)` | Frame-rate-independent exponential velocity decay |
| `draw_arc(center, radius, from, to, points, color, width)` | Horseshoe magnet arc and field ring visuals |
| `InputEventMouseMotion` | Tracks cursor position to drag the magnet |

## Controls

| Input | Action |
|-------|--------|
| Left Click + Drag (on magnet) | Reposition the magnet |
| A | Toggle attract / repel mode |
| R | Reset all balls to random positions |

## Key Constants

```gdscript
const GRAVITY          := 200.0   # Downward acceleration (px/s²)
const MAGNET_STRENGTH  := 18000.0 # Numerator of inverse-square force law
const MAX_FORCE        := 600.0   # Maximum force per frame (stability cap)
const DAMPING          := 0.992   # Per-60fps-frame velocity multiplier
const MIN_DIST         := 30.0    # Minimum distance used in force denominator (px)
const MAGNET_GRAB_RADIUS := 30.0  # Click radius to start dragging the magnet (px)
const BALL_COUNT       := 10      # Number of metallic balls
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Magnet force, damping, drag interaction, field line drawing, ball physics |
| `scenes/main.tscn` | Root Node2D with main.gd attached |
| `tests/test_logic.gd` | Unit tests for force magnitude and attract/repel direction |
| `tests/test.tscn` | Scene that runs the tests |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

