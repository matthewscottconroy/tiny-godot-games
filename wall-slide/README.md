# Wall Slide

A minimal Godot 4.2 demo focused on wall-sliding mechanics: gravity reduction while pressing into a wall, terminal slide velocity, and slide-distance tracking.

## Controls

| Key | Action |
|-----|--------|
| Left / Right (or A / D) | Move |
| Up (or W) | Jump (floor only — no wall jump) |

Hold into a wall while airborne to slide down slowly.

## How It Works

### Gravity Reduction

When the player is on a wall, not on the floor, and pressing toward the wall, gravity is multiplied by `WALL_SLIDE_GRAV`:

```gdscript
var pressing_into_wall := (h * get_wall_normal().x) < 0.0
var grav_scale := WALL_SLIDE_GRAV if (on_wall and pressing_into_wall and not on_floor) else 1.0
velocity.y += GRAVITY * grav_scale * delta
```

`h * wn.x < 0` detects the "pressing into" condition: if the wall normal points right (`wn.x = +1`) and you press left (`h = -1`), the product is negative.

### Terminal Slide Velocity

A speed cap prevents runaway acceleration during long slides:

```gdscript
velocity.y = minf(velocity.y, SLIDE_SPEED_CAP)
```

### Visual Feedback

The player turns orange while sliding. The info label shows real-time slide speed (px/s) and cumulative distance slid.

## Key Constants

```gdscript
const GRAVITY         := 900.0    # normal downward acceleration (px/s²)
const WALL_SLIDE_GRAV := 0.12     # gravity multiplier while sliding (12% of normal)
const SLIDE_SPEED_CAP := 80.0     # maximum downward speed while on wall (px/s)
const JUMP_VEL        := -380.0   # floor-jump velocity (no wall jumping in this demo)
```

## Project Structure

```
wall-slide/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn       # outer walls + two inner walls for practice
├── scripts/
│   ├── main.gd         # draws wall geometry
│   └── player.gd       # wall-slide CharacterBody2D with speed/distance tracking
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
