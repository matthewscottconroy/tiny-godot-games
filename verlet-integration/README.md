# Verlet Integration

A minimal Godot 4 demo showing position-based Verlet rope physics: a chain of particles connected by distance constraints, with mouse drag interaction.

## Purpose

Verlet integration stores the previous position instead of a velocity, which makes constraints trivial — move a point and its velocity follows automatically. That property is what makes it the standard choice for rope, cloth, and soft bodies. This demo builds a rope from particles and distance constraints, relaxed over several iterations per frame.

## Controls

| Input | Action |
|-------|--------|
| LMB drag | Grab and move any rope particle |

## How It Works

### Verlet Integration

Instead of storing velocity explicitly, position is integrated from the difference between current and previous positions:

```gdscript
var vel  := pos[i] - prev[i]
prev[i]  = pos[i]
pos[i]  += vel + GRAVITY * dt * dt
```

This automatically carries momentum forward. Changing `prev[i]` before the integration step gives an impulse — useful for collisions.

### Distance Constraints

After integration, each segment is corrected to its rest length by moving both endpoints toward the midpoint by half the error:

```gdscript
var dv   := pos[i + 1] - pos[i]
var dist := dv.length()
var corr := dv * ((dist - SEG_LENGTH) / dist * 0.5)
pos[i]     += corr
pos[i + 1] -= corr
```

Running this `ITERATIONS` times per frame lets the rope converge toward the rest shape before rendering.

### Anchor Pin

`pos[0]` is reset to `ANCHOR` at the start and end of every constraint pass. Pinning additional particles (e.g., both ends) creates a hanging bridge or net.

## Key Constants

```gdscript
const NUM_PARTICLES := 24     # chain length
const SEG_LENGTH    := 16.0   # rest distance between adjacent particles (px)
const GRAVITY       := Vector2(0.0, 500.0)  # acceleration applied each step
const ITERATIONS    := 12     # constraint solver passes per frame
```

## Files

```
verlet-integration/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd         # verlet step + distance constraints + mouse drag
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```

## Key Godot APIs

| API | Purpose |
|-----|---------|
| Position + previous position | Velocity is implied, so constraints are trivial |
| `Vector2.distance_to()` | Measure a distance constraint's error |
| `PackedVector2Array` | Tight storage for particle positions |
| `draw_line()` / `draw_circle()` | Render the rope and its particles |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

