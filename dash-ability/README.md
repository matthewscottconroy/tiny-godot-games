# Dash Ability

A horizontal dash that overrides normal movement for a fixed duration, with a cooldown timer, invincibility frames, and a ghost-image afterimage trail — all layered on top of a standard platformer controller without modifying its core logic.

## Purpose

The dash is one of the most expressive abilities in action games. It appears in *Celeste* (air dash), *Hollow Knight* (dash strike), *Dead Cells* (roll), *Hades* (dash + invincibility), and *Mega Man X* (slide dash). Beyond traversal speed, the dash creates a moment of commitment: the player cannot steer during the dash window, making the timing and direction of the activation the skill expression.

The three interlocking timers — dash duration, cooldown, and invincibility frames — are independent design levers. Cooldown controls how often the ability can be used. Duration controls how far the player travels. Iframes control how much protection the dash provides. Tuning each independently lets you build wildly different feels: a short dash with long iframes feels like a dodge roll; a long dash with zero iframes feels like a speed burst; a medium dash with a long cooldown feels like a teleport.

This demo shows how to add all of this to an existing platformer controller with minimal coupling. The core movement code is unchanged; the dash is a state that temporarily takes over velocity for a fixed window.

## How It Works

### Node Tree

```
Main (Node2D)                      ← (no script)
├── Player (CharacterBody2D)       ← player.gd
│   └── InfoLabel (Label)
└── [floor + platforms, StaticBody2D ×N]
```

### State Variables (`scripts/player.gd`)

```gdscript
var _dashing    := false          # currently in dash window
var _dash_timer := 0.0            # time remaining in this dash
var _cooldown   := 0.0            # time until next dash is allowed
var _iframes    := 0.0            # invincibility window remaining
var _dash_dir   := 1.0            # direction locked at dash start
var _facing     := 1.0            # last horizontal input direction
var _ghosts:    Array[Vector2] = []  # positions for afterimage trail
```

Each concern is its own variable. They are never combined — keeping them separate makes it easy to read any one timer without reinterpreting a shared state enum.

### Dash Trigger

```gdscript
if Input.is_action_just_pressed("ui_select") and _cooldown <= 0.0 and not _dashing:
    _dashing    = true
    _dash_timer = DASH_DURATION
    _dash_dir   = _facing        # lock direction at the moment of press
    _iframes    = IFRAME_TIME
    _cooldown   = DASH_COOLDOWN
    _ghosts.clear()
```

All three timers start on the same frame as `_dashing = true`. Direction is locked to `_facing` at the instant of the press — not re-read during the dash — so changing input mid-dash has no effect.

### Dash Velocity Override

```gdscript
if _dashing:
    _ghosts.append(global_position)
    if _ghosts.size() > GHOST_MAX:
        _ghosts.pop_front()
    velocity.x = _dash_dir * DASH_SPEED
    velocity.y = 0.0              # cancel gravity during dash
    _dash_timer -= delta
    if _dash_timer <= 0.0:
        _dashing = false
else:
    velocity.x = h * SPEED
    if Input.is_action_just_pressed("ui_up") and is_on_floor():
        velocity.y = JUMP_VEL
```

While dashing, `velocity.y = 0.0` cancels gravity so the player travels horizontally even if airborne. This is the standard feel for a horizontal dash; remove it for a velocity-preserving air dash.

### Ghost Trail

Each frame during the dash, `global_position` is appended to `_ghosts`. The array is capped at `GHOST_MAX = 8` entries using a circular buffer (push back, pop front). In `_draw()`:

```gdscript
for i in _ghosts.size():
    var alpha := float(i) / GHOST_MAX * 0.4
    var gp    := to_local(_ghosts[i])
    draw_rect(Rect2(gp.x - 12, gp.y - 24, 24, 48), Color(0.4, 0.6, 1.0, alpha))
```

Older ghosts (lower index) have lower alpha; newer ghosts are more opaque. `to_local()` converts stored world positions into the node's local draw space.

### Visual State Feedback

```gdscript
var col := Color.YELLOW if _dashing else (Color(1.0, 0.5, 0.5) if _iframes > 0.0 else Color.DODGER_BLUE)
```

- Yellow: actively dashing
- Pink/salmon: dash ended, iframes still active (invincible)
- Blue: normal state

This color coding makes the invisible iframes window tangible during development.

## Dash Mechanic Theory

### Cooldown vs Duration

`DASH_DURATION = 0.14s` is the time the player is locked into the dash. `DASH_COOLDOWN = 0.65s` is the time before another dash is allowed. They are independent:

- `COOLDOWN > DURATION`: there is a gap between dashes where the player moves normally. This is the standard feel.
- `COOLDOWN == DURATION`: dashes chain immediately. Results in a teleport-like feel.
- `COOLDOWN < DURATION`: impossible to trigger (cooldown starts simultaneously with the dash and `_cooldown <= 0.0` is false until it expires, by which time the dash has ended).

### Invincibility Frames

`IFRAME_TIME = 0.20s` exceeds `DASH_DURATION = 0.14s` by 0.06s, so the player remains invincible for a brief moment after the dash ends. This is deliberate: it rewards committing to a dash through an attack, even if the dash timing is slightly off.

### Gravity Cancellation

`velocity.y = 0.0` during the dash makes it feel like a teleport dash rather than an arc. For a *Celeste*-style diagonal air dash, change the direction vector to `Vector2(_dash_dir, -1).normalized()` and do not zero `velocity.y`.

## How to Adapt This in Your Project

**8-directional dash:** Store `_dash_dir` as a `Vector2` rather than a float, computed from the last input direction: `_dash_dir = Input.get_vector(...).normalized()`. Use `if _dash_dir == Vector2.ZERO: _dash_dir = Vector2(_facing, 0)` as a fallback.

**Dash charges:** Replace the boolean cooldown with a `_charges: int` counter. Decrement on dash, regenerate one charge per second up to a maximum. This is *Celeste*'s system.

**Dash through enemies:** While `_iframes > 0`, skip collision response with enemy hitboxes by checking the iframe state in your hitbox handler before applying damage.

**Dash recharge on landing:** Connect to `is_on_floor()` becoming true after a dash and reset `_cooldown = 0.0` — allows dashing again immediately after landing.

**Camera lead:** Push the camera offset in `_dash_dir` during the dash so the player can see where they're going.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.is_action_just_pressed("ui_select")` | Single-frame press detection (Space) |
| `to_local(global_position)` | Convert a world position to local draw-space coordinates |
| `maxf(v - delta, 0.0)` | Count-down timer that clamps at zero |
| `velocity.y = 0.0` | Cancel gravity during the dash window |
| `Input.get_axis("ui_left", "ui_right")` | Horizontal input as −1/0/+1 float |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys | Move and face a direction |
| Up | Jump |
| Space (`ui_select`) | Dash in the facing direction (when cooldown is ready) |

## Key Constants

```gdscript
const SPEED         := 200.0   # normal horizontal speed (px/s)
const JUMP_VEL      := -420.0  # jump impulse (negative = up)
const GRAVITY       := 900.0   # gravity acceleration (px/s²)
const DASH_SPEED    := 650.0   # velocity during dash window (px/s)
const DASH_DURATION := 0.14    # seconds the dash lasts
const DASH_COOLDOWN := 0.65    # seconds before next dash
const IFRAME_TIME   := 0.20    # invincibility window (exceeds dash duration)
const GHOST_MAX     := 8       # maximum trail ghost positions stored
```

## Files

| File | Purpose |
|------|---------|
| `scripts/player.gd` | All dash logic: state machine, timers, ghost trail, visual feedback |

## Use as a building block

**Copy:** `scripts/player.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [moving-platforms](../moving-platforms) — Oscillating platforms that correctly carry the player via `constant_linear_velocity`.
- [wall-jump](../wall-jump) — Wall-sliding and wall-jumping mechanics.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

