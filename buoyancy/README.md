# Buoyancy

<!-- tags: shows-its-working -->

A custom 2D physics simulation of five boxes floating or sinking in water based on their density, built without Godot's physics engine using only `_physics_process` and `_draw`.

## Purpose

Buoyancy is one of the first custom physics effects developers reach for when building water-based games — think *Subnautica*, *Sea of Thieves*, or any 2D platformer with a swimming section. Godot's built-in physics doesn't simulate fluid displacement, so games that need objects to bob on a water surface must implement Archimedes' principle directly.

Beyond water, the same depth-fraction pattern applies to other fluid-like systems: lava that slows enemies who wade into it, quicksand that bogs down the player proportionally to submersion depth, or oil slicks that damp vehicle momentum. Understanding how to compute a "what fraction of me is inside this thing" metric unlocks all of these effects.

The simulation is deliberately kept self-contained — no `RigidBody2D`, no `Area2D` — so the physics equations are readable in isolation. All five boxes run in a single loop in `_physics_process`, making it easy to study the balance between gravity and buoyancy as you change the density constants.

## How It Works

### Gravity and Weight

Each box has a `density` value. Gravity is scaled by density so denser objects feel heavier:

```gdscript
box.vel.y += GRAVITY * box.density * delta
```

A box with `density = 0.3` accelerates downward at only 30% the rate of a `density = 1.0` box. This mirrors real physics: a styrofoam block (low density) has less weight than a steel block of the same volume.

### Submersion Fraction

The critical measurement is how much of the box is below the waterline (`WATER_Y = 240.0`). The box center is tracked by `box.pos`, and its bottom edge is at `box.pos.y + box.size.y * 0.5`:

```gdscript
var bottom := box.pos.y + box.size.y * 0.5
var submerged := clampf(bottom - WATER_Y, 0.0, box.size.y)
var depth_frac := submerged / box.size.y
```

`depth_frac` ranges from `0.0` (fully above water) to `1.0` (fully submerged). This single number drives both the buoyant force and the water damping.

### Buoyant Force

The upward buoyancy impulse is proportional to `depth_frac`:

```gdscript
box.vel.y -= BUOYANCY * depth_frac * delta
```

At equilibrium the box rests at the depth where `GRAVITY * density == BUOYANCY * depth_frac`, meaning `depth_frac == density * GRAVITY / BUOYANCY`. With the constants used here (`GRAVITY = 500`, `BUOYANCY = 900`), a `density = 0.3` box floats with `depth_frac ≈ 0.167` — about one-sixth submerged.

### Water Damping

When any part of the box is submerged, velocity decays to simulate fluid drag:

```gdscript
if depth_frac > 0.0:
    var damp_factor := pow(DAMPING, delta) * depth_frac + (1.0 - depth_frac)
    box.vel *= damp_factor
```

The damping is blended by `depth_frac` so a half-submerged box experiences half the drag of a fully submerged one. This prevents oscillation and produces the characteristic bobbing-then-settling behavior.

## The Equilibrium Model

The resting depth for any floating box satisfies:

```
GRAVITY * density * depth_frac_at_rest = BUOYANCY * depth_frac_at_rest
→ depth_frac_at_rest = (GRAVITY / BUOYANCY) * density
```

For this demo (`GRAVITY / BUOYANCY ≈ 0.556`):

| Density | Floats/Sinks | Rest depth_frac |
|---------|-------------|-----------------|
| 0.3     | Floats high  | ≈ 0.167 (17% submerged) |
| 0.6     | Floats       | ≈ 0.333 (33% submerged) |
| 0.9     | Barely floats| ≈ 0.500 (50% submerged) |
| 1.1     | Barely sinks | > 1.0 — sinks to bottom |
| 1.4     | Sinks fast   | > 1.0 — sinks to bottom |

Any `density >= BUOYANCY / GRAVITY ≈ 1.8` sinks regardless of submersion.

## How to Adapt This in Your Project

Replace the `box` dictionary with your own node or resource. The three key lines — weight, buoyancy, and damping — can be attached to any object that has a `position` and `velocity`. To support non-rectangular shapes, compute `depth_frac` from the object's actual submerged area (e.g., a circular object uses the circular segment formula). To add water surface waves, replace the flat `WATER_Y` constant with a sampled sine curve. For 3D, the same logic extends naturally: compute the fraction of an AABB below a water plane and apply an upward force scaled by volume, not height.

Pitfall: if `DAMPING` is too high and applied without the `depth_frac` blend, objects above the waterline will slow down in the air — avoid applying damping unless `depth_frac > 0`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `_physics_process(delta)` | Fixed timestep update loop for physics |
| `clampf(value, min, max)` | Clamps the submerged depth to valid range |
| `pow(DAMPING, delta)` | Frame-rate-independent exponential velocity decay |
| `queue_redraw()` | Triggers `_draw()` next frame |
| `draw_rect(rect, color)` | Draws filled rectangle for water and boxes |
| `ThemeDB.fallback_font` | Access default font without a font resource file |

## Controls

| Key | Action |
|-----|--------|
| R | Reset all boxes to starting positions |

## Key Constants

```gdscript
const WATER_Y  := 240.0  # Y coordinate of the water surface (screen center)
const GRAVITY  := 500.0  # Downward acceleration base (scaled by density)
const BUOYANCY := 900.0  # Upward force per unit of depth_frac
const DAMPING  := 0.85   # Per-second velocity multiplier while submerged
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | All simulation logic: gravity, buoyancy, damping, collision, drawing |
| `scenes/main.tscn` | Root Node2D with main.gd attached |
| `tests/test_logic.gd` | Unit tests for depth_frac computation and float/sink logic |
| `tests/test.tscn` | Scene that runs the tests |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [2d-lighting](../2d-lighting) — Runtime `GradientTexture2D` point lights under a global `CanvasModulate`.
- [ability-system](../ability-system) — Four hotkey abilities with independent cooldowns and a shared mana pool.
- [audio-positional](../audio-positional) — `AudioStreamPlayer2D` spatial attenuation with a synthesized tone.
- [behavior-tree](../behavior-tree) — Enemy AI driven by a composable behavior tree (patrol/investigate/chase/attack).

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

