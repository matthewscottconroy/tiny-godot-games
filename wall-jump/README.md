# Wall Jump

A minimal Godot 4.2 demo showing wall-sliding and wall-jumping mechanics.

## Controls

| Key | Action |
|-----|--------|
| Left / Right (or A / D) | Move |
| Up (or W) | Jump / Wall-jump |

## How It Works

### Wall Slide (Gravity Reduction)

When the player is:
- touching a wall (`is_on_wall()`)
- pressing toward that wall (horizontal input sign is opposite to `get_wall_normal().x`)
- not on the floor (`not is_on_floor()`)

…gravity is multiplied by `WALL_SLIDE_GRAV` (0.2), slowing the descent to a gentle slide. This gives the player time to react and jump.

### Wall Jump

When the player presses jump while on a wall (and not on the floor), the new velocity is:

```gdscript
velocity = Vector2(-get_wall_normal().x * WALL_JUMP_VX, JUMP_VEL)
```

`get_wall_normal()` returns a unit vector pointing *away* from the wall surface. Negating its X component and multiplying by `WALL_JUMP_VX` pushes the player away from the wall horizontally, while `JUMP_VEL` sends them upward.

- **Left wall** → normal is `(+1, 0)` → jump goes left (`-300`, `-420`)
- **Right wall** → normal is `(-1, 0)` → jump goes right (`+300`, `-420`)

### Key Godot APIs

| API | Purpose |
|-----|---------|
| `is_on_wall()` | True when the character collides with a wall this frame |
| `get_wall_normal()` | Unit vector perpendicular to the wall, pointing away from it |
| `is_on_floor()` | True when standing on a surface within `floor_max_angle` |
| `move_and_slide()` | Integrates velocity, resolves collisions, updates floor/wall/ceiling state |

## Key Constants

```gdscript
const SPEED           := 180.0   # horizontal run speed (px/s)
const JUMP_VEL        := -420.0  # upward velocity on jump (negative = up)
const GRAVITY         := 900.0   # downward acceleration (px/s²)
const WALL_SLIDE_GRAV := 0.2     # gravity multiplier while wall-sliding
const WALL_JUMP_VX    := 300.0   # horizontal speed gained from wall-jump
```

## Project Structure

```
wall-jump/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn       # Main scene: two walls, a floor, and the player
├── scripts/
│   ├── main.gd         # Draws the level geometry via _draw()
│   └── player.gd       # Wall-slide + wall-jump CharacterBody2D
├── tests/
│   ├── test.tscn       # Run this scene to execute tests
│   └── test_logic.gd   # Pure-GDScript unit tests (no scene tree needed)
└── README.md
```
