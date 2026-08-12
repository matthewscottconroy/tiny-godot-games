# Verlet Integration

A minimal Godot 4 demo showing position-based Verlet rope physics: a chain of particles connected by distance constraints, with mouse drag interaction.

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

## Project Structure

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
