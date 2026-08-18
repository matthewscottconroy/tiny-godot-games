# Particle Effects

<!-- tags: ui -->

Demonstrates `CPUParticles2D` for fire, smoke, sparkle, and explosion effects — all driven by runtime property changes on a single reused emitter node.

## Purpose

Particle systems are a core visual effects tool for impacts, ambient atmosphere, magic spells, and environmental effects. `CPUParticles2D` simulates all particles on the CPU using configurable parameters. Understanding which parameters control what allows you to construct a wide variety of effects from a single node type.

## Controls

- **Fire**: Looping fire column effect
- **Smoke**: Drifting grey smoke
- **Sparkle**: Spreading gold particles with gravity
- **Explosion**: One-shot burst (runs once, then stops)
- **Stop**: Stop the current emitter

## How It Works

### Node Tree

```
Main (Node2D)                  ← main.gd
├── Particles (CPUParticles2D)
├── ModeLabel (Label)
└── Buttons (HBoxContainer)
    ├── FireBtn, SmokeBtn, SparkleBtn, ExplosionBtn, StopBtn
```

One `CPUParticles2D` is reused for all effects. Each button function reconfigures its properties and restarts it.

### `scripts/main.gd`

Each preset function sets a group of properties and sets `emitting = true`. The key property groups:

| Property | Purpose |
|---|---|
| `one_shot` | `true` = emit once then stop; `false` = loop |
| `amount` | Maximum number of particles alive at once |
| `lifetime` | How long each particle lives (seconds) |
| `direction` | Base movement direction (Vector2) |
| `spread` | Angle cone around direction (degrees) |
| `gravity` | Constant acceleration on all particles |
| `initial_velocity_min/max` | Speed range at spawn |
| `scale_amount_min/max` | Size range of particles |
| `color` | Base particle color |

**Fire:**
```gdscript
particles.one_shot            = false
particles.amount              = 40
particles.lifetime            = 0.9
particles.direction           = Vector2(0, -1)   # upward
particles.spread              = 22.0             # narrow cone
particles.gravity             = Vector2(0, -30)  # slight upward drift
particles.initial_velocity_min = 60.0
particles.initial_velocity_max = 120.0
particles.color               = Color.ORANGE_RED
```

**Smoke** uses a wider spread (40°), larger scale (8–16), longer lifetime (2.5s), and a semi-transparent grey.

**Sparkle** uses 180° spread (omnidirectional), downward gravity (particles arc and fall), and gold color.

**Explosion** uses `one_shot = true` and calls `particles.restart()`:
```gdscript
func _burst() -> void:
    particles.one_shot = true
    # ... configure ...
    particles.restart()
    particles.emitting = true
```

`restart()` resets the particle system's internal state, ensuring a clean burst even if called while the previous emission is still fading.

## CPUParticles2D Theory

### Particle Lifecycle

Each particle has:
1. **Birth** — spawned at the emitter's position with initial velocity and properties
2. **Life** — moves according to direction, velocity, and gravity
3. **Death** — removed when `lifetime` expires

`amount` is the maximum concurrent particles. At steady state (looping), new particles spawn as old ones die, maintaining the visual density.

### Spread and Direction

`direction` is the central emission vector. `spread` is the half-angle of the cone. At `spread = 180`, particles emit in all directions. At `spread = 0`, all particles travel exactly in `direction`.

The velocity at birth is: `direction.rotated(random angle in [-spread, +spread]) * random(min, max)`

### one_shot vs Looping

- `one_shot = false` + `emitting = true` → particles spawn continuously until `emitting = false`
- `one_shot = true` → particles spawn until `amount` is reached, then stop spawning. Existing particles continue until their lifetime expires.

`restart()` resets the internal emission counter so `one_shot` bursts can be re-triggered.

### CPU vs GPU Particles

`CPUParticles2D` runs the particle simulation on the CPU. This is compatible with all hardware and can be exported to all platforms including mobile. It is slower than `GPUParticles2D` for large particle counts (>1000) but fully configurable from GDScript.

`GPUParticles2D` runs on the GPU and supports far larger counts but requires custom shader materials to modify behavior and is not supported on all older hardware.

### Visual Variety from Parameters

Dramatic variety comes from adjusting a few key parameters:
- **lifetime × velocity = travel distance** — short lifetime + high velocity = fire sparks; long lifetime + low velocity = drifting smoke
- **gravity** — downward gravity = realistic trajectory; upward or sideways = magical or wind effects
- **spread** — narrow = laser/beam; wide = explosion/radial burst

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CPUParticles2D.emitting` | Start/stop particle emission |
| `CPUParticles2D.one_shot` | Single burst vs continuous |
| `CPUParticles2D.amount` | Max concurrent particles |
| `CPUParticles2D.lifetime` | Seconds each particle lives |
| `CPUParticles2D.direction` | Base emission direction |
| `CPUParticles2D.spread` | Cone half-angle in degrees |
| `CPUParticles2D.gravity` | Constant acceleration |
| `CPUParticles2D.initial_velocity_min/max` | Spawn speed range |
| `CPUParticles2D.restart()` | Reset and re-fire |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [accessibility-options](../accessibility-options) — Colourblind-safe palettes, reduced motion, text scaling, and shape cues.
- [animated-sprite](../animated-sprite) — A sprite sheet generated entirely in code — no image files or imports.
- [animation-tree](../animation-tree) — `AnimationTree` + `AnimationNodeStateMachine` driving squash-and-stretch.
- [area-trigger](../area-trigger) — `Area2D` invisible trigger zones firing signals on body enter/exit.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

