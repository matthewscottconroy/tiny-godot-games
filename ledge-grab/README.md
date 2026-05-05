# Ledge Grab

Wall sliding and wall jumping — the player clings to walls mid-air, slows their fall, and can launch off at an angle. Demonstrates `is_on_wall_only()` and `get_wall_normal()` in Godot's `CharacterBody2D`.

## Purpose

Wall jumping is a core mechanic in many platform games (Hollow Knight, Celeste, Mega Man X). Without it, vertical wall sections are dead ends. With it, they become traversal puzzles. This demo shows the minimal implementation: detect wall contact in the air, cap fall speed while sliding, and apply an outward impulse on jump press.

## Controls

- **Arrow keys / WASD**: Move left and right
- **Up / W**: Jump (or wall-jump when sliding)
- Jump toward a wall, slide down it, then press Up to launch off

## How It Works

### State Machine

```
IDLE  → FALL → WALL_SLIDE → (press jump) → JUMP → FALL …
RUN   → JUMP → FALL       → FLOOR        → RUN  …
```

The key new state is `WALL_SLIDE`: entered whenever the player is airborne and touching a wall.

### `scripts/player.gd`

**Wall slide — slow the fall:**
```gdscript
elif is_on_wall_only():
    velocity.y = minf(velocity.y + GRAVITY * delta, WALL_SLIDE)
    velocity.x = 0.0
```
`is_on_wall_only()` is true when touching a wall but NOT the floor. `minf` clamps the fall speed to `WALL_SLIDE = 60`, making the player appear to cling to the surface.

**Wall jump — push away:**
```gdscript
    if Input.is_action_just_pressed("ui_up"):
        var normal := get_wall_normal()
        velocity.x = normal.x * WALL_JUMP_X
        velocity.y = WALL_JUMP_Y
```
`get_wall_normal()` returns a unit vector pointing away from the wall surface: `(1, 0)` for a left wall, `(-1, 0)` for a right wall. Multiplying by `WALL_JUMP_X` sends the player horizontally away from the wall. Setting `velocity.y = WALL_JUMP_Y` provides the upward boost.

**Reduced air control:**
```gdscript
else:
    velocity.y += GRAVITY * delta
    velocity.x = lerpf(velocity.x, dir * SPEED, 0.08)
```
In normal air (not wall sliding), horizontal speed lerps toward the target rather than snapping. This gives airborne momentum — the player can't instantly reverse direction mid-jump. The `0.08` factor gives about 12 frames to reach full horizontal speed.

### Why `is_on_wall_only()`

`is_on_wall()` returns true even when on a corner where both a wall and floor are touching. `is_on_wall_only()` returns true only when touching a wall and NOT the floor, which prevents triggering wall-slide logic when standing on a platform edge.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CharacterBody2D.is_on_wall_only()` | True when touching a wall but not the floor |
| `CharacterBody2D.get_wall_normal()` | Unit vector pointing away from the touched wall |
| `minf(a, b)` | Float minimum — caps fall speed during wall slide |
| `lerpf(from, to, weight)` | Smooth interpolation for air-control feel |
| `move_and_slide()` | Updates wall/floor contact state after movement |
