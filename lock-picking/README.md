# Lock Picking

A minimal Godot 4 demo showing a lock-picking mechanic: rotate a lock cylinder to find the hidden correct angle; tension builds when you're close and unlocks when full.

## Purpose

Minigames like this are almost entirely feel: a hidden target value, a continuous input, and feedback that gets more intense as you close in. The code is a couple of numbers, so the interesting part is the mapping from distance-to-target onto tension, sound, and visual response. This demo isolates that mapping.

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

## Files

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

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `wrapf()` | Keep the cylinder angle inside a single turn |
| `absf()` | Distance from the hidden target angle |
| `draw_arc()` / `draw_circle()` | Render the cylinder and tension gauge |
| `InputEventMouseMotion.relative` | Rotate by mouse movement rather than absolute position |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

