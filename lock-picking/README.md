# Lock Picking

A minimal Godot 4 demo showing a lock-picking mechanic: rotate a lock cylinder to find the hidden correct angle; tension builds when you're close and unlocks when full.

## Controls

| Input | Action |
|-------|--------|
| Drag LMB left/right | Rotate the cylinder |
| Space (when unlocked) | Try a new lock |

## How It Works

### Hidden Correct Angle

Each lock is initialized with a random `_correct_angle` in `[-160°, +160°]`. The player has no direct indication of it — they must probe by rotating.

### Tension Mechanic

Each frame, the angular distance from the current position to the correct angle is computed:

```gdscript
var diff := absf(wrapf(_current_angle - _correct_angle, -180.0, 180.0))
if diff < TOLERANCE:
    _tension += delta * FILL_SPEED   # fill when close
else:
    _tension -= delta * DRAIN_SPEED  # drain when far
```

The tension bar fills quickly when near the correct angle and drains even faster when you move away, rewarding slow careful sweeping over rapid guessing.

### Unlock

When `_tension` reaches 1.0, `_unlocked = true` and the cylinder glows green.

### Angle Wrapping

`wrapf(angle, -180.0, 180.0)` ensures that an angle of 179° and one of -179° are correctly recognized as only 2° apart, preventing a false "far" reading at the ±180° seam.

## Key Constants

```gdscript
const TOLERANCE   := 14.0   # degrees — how close you need to be
const FILL_SPEED  := 2.5    # tension fill rate (per second near correct angle)
const DRAIN_SPEED := 4.0    # tension drain rate (per second away from angle)
const DRAG_SENS   := 0.35   # mouse pixels → degrees rotation
```

## Project Structure

```
lock-picking/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd         # cylinder rotation, tension fill/drain, unlock, _draw()
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
