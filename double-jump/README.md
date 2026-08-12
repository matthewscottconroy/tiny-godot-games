# Double Jump

A minimal Godot 4 demo showing the double-jump mechanic.

## Controls

| Key | Action |
|-----|--------|
| Left / Right (or A / D) | Move |
| Up (or W) | Jump — press again mid-air for second jump |

## How It Works

### Jump Counter

A `_jumps_left` integer tracks remaining jumps. It resets to `MAX_JUMPS` whenever `is_on_floor()` is true, and decrements by 1 each time a jump is triggered.

```gdscript
if is_on_floor():
    _jumps_left = MAX_JUMPS

if Input.is_action_just_pressed("ui_up") and _jumps_left > 0:
    velocity.y = JUMP_VEL
    _jumps_left -= 1
```

Both jumps apply the same `JUMP_VEL`. A separate `SECOND_JUMP_VEL` constant (slightly weaker) is a common variant for a floatier second jump.

### Reset Condition

`_jumps_left` only resets when `is_on_floor()` is true. Mid-air reset variants (e.g., reset on wall contact, on coyote frames, or on collecting a power-up) follow the same pattern — just add additional reset conditions.

### Extending to N Jumps

Change `MAX_JUMPS` to 3 or more. The counter mechanism requires no other changes.

## Key Constants

```gdscript
const SPEED     := 180.0   # horizontal run speed (px/s)
const JUMP_VEL  := -420.0  # upward velocity applied on every jump
const GRAVITY   := 900.0   # downward acceleration (px/s²)
const MAX_JUMPS := 2        # jumps available before landing is required
```

## Project Structure

```
double-jump/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn       # three stacked platforms + floor + player
├── scripts/
│   ├── main.gd         # draws level geometry via _draw()
│   └── player.gd       # double-jump CharacterBody2D
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
