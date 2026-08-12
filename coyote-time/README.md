# Coyote Time

A minimal Godot 4 demo showing two classic platformer feel improvements: **coyote time** and **jump buffering**.

## Purpose

Players blame the game when a jump does not come out, and they are usually right. Two forgiveness windows fix almost all of it: coyote time lets a jump register for a few frames after walking off a ledge, and jump buffering lets a press slightly before landing still fire. Both are just timers, but where you tick and clear them decides whether the feel is tight or floaty. This demo isolates the pair so the timing is visible.

## Controls

| Key | Action |
|-----|--------|
| Left / Right (or A / D) | Move |
| Up (or W) | Jump |

Watch the on-screen timers to see coyote time and the jump buffer in action.

## How It Works

### The Problem with Strict Floor Checks

A naive jump implementation (`if is_on_floor() and jump_pressed`) punishes the player for two reasons:

1. **Running off a ledge**: The player is airborne for one frame before they can react — the jump window is already closed.
2. **Pressing jump early**: If the player presses jump a few frames before landing, nothing happens because they weren't on the floor yet.

Both make the game feel unresponsive and unfair. Coyote time and jump buffering fix each problem respectively.

### Coyote Time

A grace period (`COYOTE_TIME = 0.12 s`) is granted *after* the player walks off a ledge. During this window they can still jump as if they were on the floor.

```gdscript
# Detect the exact frame we left the floor
if _was_on_floor and not is_on_floor():
    _coyote_timer = COYOTE_TIME

# Keep it fresh while actually grounded
if is_on_floor():
    _coyote_timer = COYOTE_TIME

_coyote_timer -= delta
_coyote_timer  = maxf(_coyote_timer, 0.0)
```

### Jump Buffering

The player's jump-button press is remembered for `BUFFER_TIME = 0.15 s`. If they land within that window, the jump fires immediately — rewarding early input rather than ignoring it.

```gdscript
if Input.is_action_just_pressed("ui_up"):
    _jump_buffer = BUFFER_TIME

_jump_buffer -= delta
_jump_buffer  = maxf(_jump_buffer, 0.0)
```

### The Jump Condition

Both tricks are unified in a single check:

```gdscript
if _coyote_timer > 0.0 and _jump_buffer > 0.0:
    velocity.y    = JUMP_VEL
    _coyote_timer = 0.0   # consume the coyote window
    _jump_buffer  = 0.0   # consume the buffered press
```

Clearing both timers after the jump prevents double-jumps.

## Key Constants

```gdscript
const SPEED       := 200.0   # horizontal run speed (px/s)
const JUMP_VEL    := -420.0  # upward velocity on jump
const GRAVITY     := 900.0   # downward acceleration (px/s²)
const COYOTE_TIME := 0.12    # grace period after leaving a ledge (seconds)
const BUFFER_TIME := 0.15    # early-jump memory window (seconds)
```

## Files

```
coyote-time/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn       # Two platforms of different widths
├── scripts/
│   ├── main.gd         # Draws platforms via _draw()
│   └── player.gd       # Coyote time + jump buffer CharacterBody2D
├── tests/
│   ├── test.tscn       # Run this scene to execute tests
│   └── test_logic.gd   # Pure-GDScript unit tests
└── README.md
```

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CharacterBody2D.is_on_floor()` | Ground check that drives both timers |
| `Input.is_action_just_pressed()` | Edge-triggered jump press to buffer |
| `move_and_slide()` | Move and refresh the floor state |
| `delta` | Tick both forgiveness windows frame-rate independently |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

