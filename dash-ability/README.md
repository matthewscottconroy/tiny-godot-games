# Dash Ability

Directional dash with a cooldown, invincibility frames, and a ghost-image trail. Press Space to dash in the facing direction. Shows how to layer an ability on top of normal movement without breaking the core controller.

## Purpose

Dashes are one of the most common action-game abilities, but the implementation has several independent concerns: the dash velocity overrides normal control, a cooldown prevents spam, iframes protect the player during the dash window, and a ghost trail gives visual feedback. This demo separates each concern into its own variable.

## Controls

- **Arrow keys / WASD**: Move and face a direction
- **Up**: Jump
- **Space**: Dash in the currently-faced direction

## How It Works

### State variables

```gdscript
var _dashing    := false     # currently in dash window
var _dash_timer := 0.0       # time remaining in current dash
var _cooldown   := 0.0       # time until next dash allowed
var _iframes    := 0.0       # invincibility window
var _facing     := 1.0       # last horizontal direction (+1 or -1)
var _ghosts:    Array[Vector2] = []  # previous positions for trail
```

### Dash trigger (`scripts/player.gd`)

```gdscript
if Input.is_action_just_pressed("ui_select") and _cooldown <= 0.0 and not _dashing:
    _dashing    = true
    _dash_timer = DASH_DURATION
    _dash_dir   = _facing
    _iframes    = IFRAME_TIME
    _cooldown   = DASH_COOLDOWN
```

All three timers start simultaneously on the same frame. The dash overrides `velocity.x` and zeroes `velocity.y` so the player travels horizontally regardless of gravity.

### Ghost trail

```gdscript
if _dashing:
    _ghosts.append(global_position)
    if _ghosts.size() > GHOST_MAX:
        _ghosts.pop_front()
```

Previous positions are stored each frame during the dash. `_draw()` renders them with increasing opacity toward the current position.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.is_action_just_pressed("ui_select")` | Detect single-frame press (Space) |
| `to_local(global_position)` | Convert world position to draw-space |
| `maxf(v - delta, 0.0)` | Timer countdown that clamps at zero |
| `velocity.y = 0.0` | Cancel gravity during horizontal dash |
