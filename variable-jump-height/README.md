# Variable Jump Height

A minimal Godot 4 demo showing hold-to-jump-higher mechanics via a velocity cut on early button release.

## Controls

| Key | Action |
|-----|--------|
| Left / Right (or A / D) | Move |
| Up (or W) — tap | Short jump |
| Up (or W) — hold | Full-height jump |

## How It Works

### Jump Cut

When the jump button is released early while the player is still rising (`velocity.y < 0`), vertical velocity is multiplied by `JUMP_CUT`:

```gdscript
if _jumping and Input.is_action_just_released("ui_up") and velocity.y < 0.0:
    velocity.y *= JUMP_CUT
    _jumping = false
```

`JUMP_CUT = 0.4` means a tap produces 40% of maximum jump velocity — roughly 60% less height than a full hold.

### Why Not Just a Weaker Jump?

The cut approach gives a **continuous** spectrum of heights based on hold duration, not just two discrete values. Players intuitively learn to control jump height without needing to think about the underlying physics.

### The Guard Condition

`velocity.y < 0.0` ensures the cut only fires when still rising. If the player releases after the peak (when already falling), no cut is applied since it would actually *increase* the fall speed.

## Key Constants

```gdscript
const JUMP_VEL := -520.0   # maximum upward velocity (full hold)
const GRAVITY  := 900.0    # downward acceleration (px/s²)
const JUMP_CUT := 0.4      # vy multiplier on early release (0 = instant stop, 1 = no effect)
```

## Project Structure

```
variable-jump-height/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn       # platforms at three heights demonstrating jump range
├── scripts/
│   ├── main.gd         # draws level geometry
│   └── player.gd       # variable-height jump CharacterBody2D
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
