# Variable Jump Height

A minimal Godot 4 demo showing hold-to-jump-higher mechanics via a velocity cut on early button release.

## Purpose

Holding jump longer to jump higher is one of the highest-value feel improvements available, and it costs three lines: when the button is released while still rising, cut the upward velocity. This demo isolates the cut so the difference between a tap and a hold is measurable rather than a matter of opinion.

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

## Files

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

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.is_action_just_pressed()` | Start the jump |
| `Input.is_action_just_released()` | The moment to cut the rise |
| `CharacterBody2D.velocity` | Halve the upward component on release |
| `move_and_slide()` | Apply the result |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

