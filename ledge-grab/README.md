# Ledge Grab

Wall sliding and wall jumping built on `CharacterBody2D`: the player clings to walls mid-air, slows their descent, and launches off at a diagonal angle using `get_wall_normal()` for automatic direction calculation.

## Purpose

Wall jumping is a defining mechanic in dozens of acclaimed platformers: *Hollow Knight*, *Celeste*, *Mega Man X*, *Super Metroid*, and *Ori and the Blind Forest*. It transforms otherwise impassable vertical surfaces into traversal puzzles and gives players a skill-expressive recovery option when a jump falls short. Without wall jumping, tall walls are dead ends; with it, they become tools.

This demo shows the minimal implementation using Godot's built-in `CharacterBody2D` API. The key insight is that `get_wall_normal()` already knows which direction the wall faces — there is no need to track which wall was hit or check the player's facing direction. The normal vector directly provides the launch direction. This means the same three lines of code work identically for left walls, right walls, and any angled surface within `floor_max_angle`.

## How It Works

### Wall Slide — Capping Fall Speed

When airborne and touching a wall, fall speed is capped instead of letting gravity accumulate freely:

```gdscript
elif is_on_wall_only():
    velocity.y = minf(velocity.y + GRAVITY * delta, WALL_SLIDE)
    velocity.x = 0.0
```

`is_on_wall_only()` returns true only when touching a wall and not the floor simultaneously, preventing the slide logic from triggering on corners. `WALL_SLIDE = 60 px/s` is much slower than free-fall terminal velocity, giving the player time to react. `velocity.x = 0.0` prevents the player from walking along the wall mid-slide.

### Wall Jump — Using the Surface Normal

```gdscript
if Input.is_action_just_pressed("ui_up"):
    var normal := get_wall_normal()
    velocity.x = normal.x * WALL_JUMP_X
    velocity.y = WALL_JUMP_Y
```

`get_wall_normal()` returns a unit vector pointing away from the wall surface: `(1, 0)` for a left wall (normal points right), `(-1, 0)` for a right wall (normal points left). Multiplying `normal.x` by `WALL_JUMP_X = 260` gives the correct horizontal push away from whatever wall the player is touching. `WALL_JUMP_Y = -380` provides the upward boost.

### Air Control with Lerp

Outside of wall-slide and floor states, horizontal speed gradually transitions toward the target rather than snapping:

```gdscript
else:
    velocity.y += GRAVITY * delta
    velocity.x = lerpf(velocity.x, dir * SPEED, 0.08)
```

The `0.08` weight means the player needs roughly 12 frames (~0.2 seconds) to reach full horizontal speed from rest. This preserves momentum — a player who wall-jumped with a 260 px/s horizontal component can't instantly reverse to -200 px/s by pressing the other direction. The lerp creates the natural arc feel that distinguishes a responsive platformer from a floaty one.

### State Tracking

The state is updated after `move_and_slide()` so it reflects Godot's latest collision state:

```gdscript
func _update_state() -> void:
    if is_on_floor():
        state = State.RUN if absf(velocity.x) > 10 else State.IDLE
    elif is_on_wall_only():
        state = State.WALL_SLIDE
    else:
        state = State.JUMP if velocity.y < 0 else State.FALL
```

Five states: `IDLE`, `RUN`, `JUMP`, `FALL`, `WALL_SLIDE`. The player color changes per state so the current state is always visible at a glance.

## Why `is_on_wall_only()`

`is_on_wall()` returns true even when touching both a wall and a floor corner simultaneously. Using `is_on_wall()` would trigger wall-slide logic while standing on a platform edge next to a wall — the player would slow to `WALL_SLIDE = 60 px/s` vertically while trying to walk normally. `is_on_wall_only()` excludes this case, keeping the behavior correct at corners.

## How to Adapt This in Your Project

Increase `WALL_JUMP_X` relative to `SPEED` to make wall jumping feel powerful; set them equal for a balanced feel. Add a wall-jump cooldown timer to prevent "infinite wall climbing" by alternating between two parallel walls. Use `is_action_just_pressed` instead of `is_action_pressed` for jump input to prevent jump buffering while still wall-sliding. To animate the wall-slide, drive an `AnimationPlayer` from the state enum. Add wall-jump coyote time by tracking `time_since_left_wall` and allowing wall jumps for a brief window after leaving the surface.

Pitfall: placing the wall-slide check before the floor check in a priority system can cause the player to wall-slide while standing on a floor edge next to a wall. Always check `is_on_wall_only()` (not `is_on_wall()`) and verify it before any wall-specific behavior.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CharacterBody2D.is_on_wall_only()` | True when touching a wall but not the floor — avoids corner false positives |
| `CharacterBody2D.get_wall_normal()` | Unit vector pointing away from the contacted wall surface |
| `CharacterBody2D.is_on_floor()` | True when standing on a surface within `floor_max_angle` |
| `move_and_slide()` | Moves by `velocity`, resolves collisions, updates floor/wall/ceiling flags |
| `minf(a, b)` | Caps fall speed during wall slide |
| `lerpf(from, to, weight)` | Smooth horizontal velocity interpolation for air-control momentum |

## Controls

| Input | Action |
|-------|--------|
| Left / Right Arrow | Move horizontally |
| Up Arrow | Jump (on floor) / Wall-jump (while wall-sliding) |

## Key Constants

```gdscript
const SPEED       := 180.0   # Horizontal run speed (px/s)
const JUMP_VEL    := -400.0  # Upward velocity on regular jump
const GRAVITY     := 900.0   # Downward acceleration (px/s²)
const WALL_SLIDE  := 60.0    # Maximum fall speed while touching a wall (px/s)
const WALL_JUMP_X := 260.0   # Horizontal velocity component on wall jump (px/s)
const WALL_JUMP_Y := -380.0  # Vertical velocity component on wall jump
```

## Files

| File | Purpose |
|------|---------|
| `scripts/player.gd` | Wall slide, wall jump, air control, state machine, color-coded drawing |
| `scenes/main.tscn` | CharacterBody2D player node, static floor, two tall walls |
| `tests/test_logic.gd` | Unit tests for wall normal direction and velocity calculation |
| `tests/test.tscn` | Scene that runs the tests |

## Use as a building block

**Copy:** `scripts/player.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

