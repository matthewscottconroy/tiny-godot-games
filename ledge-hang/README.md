# Ledge Hang

A platformer demo where the player automatically grabs platform ledge corners when falling past them, freezes in a hanging state, then pulls up or drops on input — all built with a custom AABB physics system and no Godot physics engine.

## Purpose

Ledge hanging transforms platformer level design. Without it, a near-miss on a jump means falling and restarting. With it, players get a second chance — they can catch the edge and recover. The mechanic appears in *Prince of Persia*, *Assassin's Creed*, *Uncharted*, *Celeste*, and virtually every precision platformer where the environment is intended to be climbed.

The implementation is more nuanced than it looks. Detection has to be tight enough to feel responsive but loose enough to not require pixel-perfect positioning. The hang state must freeze physics completely — otherwise gravity and collision resolution fight with the locked position. Pull-up requires briefly teleporting the player above the platform to prevent the collision resolver from pushing them back down. Each of these decisions is a solved problem with a clear idiom, and this demo isolates them for study.

## How It Works

### State Machine

The player has two states managed by `PState`:

```gdscript
enum PState { NORMAL, HANGING }
```

In `NORMAL`, standard platformer physics apply: gravity, horizontal movement, jump, and AABB collision resolution. Ledge grab detection runs only when `vel.y > 0` (falling). In `HANGING`, velocity is zeroed and position is locked to the ledge corner each frame — the player is frozen until input.

### Ledge Grab Detection

`_check_ledge_grab()` runs every frame while falling. For each platform, three proximity conditions must all be true simultaneously:

**Vertical alignment** — player's top edge must be close to the platform's top surface:
```gdscript
var player_top := _pos.y - PLAYER_H
if absf(player_top - plat.position.y) > LEDGE_VERT_RANGE:
    continue
```

**Left edge check** — player's right side passes the platform's left corner:
```gdscript
if absf((_pos.x + PLAYER_W * 0.5) - left_edge) < LEDGE_GRAB_RANGE:
    _hang_edge = Vector2(left_edge, plat_top)
    _state = PState.HANGING
    return
```

**Right edge check** — player's left side passes the platform's right corner:
```gdscript
if absf((_pos.x - PLAYER_W * 0.5) - right_edge) < LEDGE_GRAB_RANGE:
    _hang_edge = Vector2(right_edge, plat_top)
    _state = PState.HANGING
    return
```

`LEDGE_GRAB_RANGE = 8px` and `LEDGE_VERT_RANGE = 10px` define the detection window. The yellow dots drawn at each ledge corner show exactly where these checks activate.

### Hang State Position Lock

While hanging, physics are bypassed entirely:

```gdscript
PState.HANGING:
    _vel = Vector2.ZERO
    _pos.y = _hang_edge.y + PLAYER_H
    if _hang_edge.x <= _pos.x:
        _pos.x = _hang_edge.x + PLAYER_W * 0.5
    else:
        _pos.x = _hang_edge.x - PLAYER_W * 0.5
```

The player is snapped so their top is at the ledge level and their body is to the correct side of the ledge corner. The collision resolver is still called each frame but finds no overlaps (the player is positioned outside all platforms), so it does nothing.

### Pull-Up and Drop

```gdscript
if jump_just:
    # Pull up onto platform
    _pos.y = _hang_edge.y - 2.0
    _vel.y = -100.0
    _state = PState.NORMAL
elif down_just:
    # Drop
    _vel.y = 100.0
    _state = PState.NORMAL
```

Pull-up teleports the player 2px above the platform surface before returning to `NORMAL`. Without this teleport, the collision resolver would immediately push the player back down through the platform edge. The small `vel.y = -100` nudge ensures they land cleanly. Drop gives a small downward push so the player clears the ledge before normal gravity takes over.

### AABB Collision Resolution

`_resolve_collisions()` uses minimum-overlap push-out:

```gdscript
var overlap_x := minf(pr.end.x, plat.end.x) - maxf(pr.position.x, plat.position.x)
var overlap_y := minf(pr.end.y, plat.end.y) - maxf(pr.position.y, plat.position.y)
if overlap_x < overlap_y:
    # push horizontally (less overlap on X axis)
else:
    # push vertically (less overlap on Y axis)
```

The axis with smaller overlap is the shortest path out of the intersection. When pushed vertically upward (player center above platform center), `_on_floor` is set, enabling jumping.

## How to Adapt This in Your Project

To use with `CharacterBody2D`, detect the hang condition in `_physics_process` after `move_and_slide()`, then set `velocity = Vector2.ZERO` and override `global_position` directly while in the hanging state. For animated characters, trigger a "hanging" animation clip in `HANGING` and a "climb" clip during pull-up. Increase `LEDGE_GRAB_RANGE` for a more forgiving grab window or decrease it for precision platformers. Add a "ledge shimmy" by updating `_hang_edge.x` while hanging based on horizontal input. For a pull-up animation, tween the player position from the hanging position to the standing position over 0.3 seconds before returning control.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Rect2.intersects(other)` | AABB overlap test for collision detection |
| `Rect2.end` | Shorthand for `position + size` (bottom-right corner) |
| `Input.is_action_pressed("ui_up")` | Detects jump/pull-up input |
| `queue_redraw()` | Schedules `_draw()` for the next frame |
| `draw_rect(rect, color, filled, width)` | Draws platforms and player body |
| `draw_circle(pos, radius, color)` | Highlights ledge corner grab points |

## Controls

| Input | Action |
|-------|--------|
| Left / Right Arrow | Move horizontally |
| Up Arrow | Jump (NORMAL) / Pull up onto platform (HANGING) |
| Down Arrow | Drop from ledge (HANGING) |
| — | Ledge grab triggers automatically when falling past a corner |

## Key Constants

```gdscript
const SPEED            := 180.0  # Horizontal run speed (px/s)
const JUMP_VEL         := -380.0 # Upward velocity on jump
const GRAVITY          := 700.0  # Downward acceleration (px/s²)
const PLAYER_W         := 20.0   # Player collision width (px)
const PLAYER_H         := 36.0   # Player collision height (px)
const LEDGE_GRAB_RANGE := 8.0    # Horizontal proximity to trigger ledge grab (px)
const LEDGE_VERT_RANGE := 10.0   # Vertical proximity to trigger ledge grab (px)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Player state machine, ledge detection, AABB collision, pull-up/drop logic, drawing |
| `scenes/main.tscn` | Root Node2D with main.gd attached; platforms defined in `_ready()` |
| `tests/test_logic.gd` | Unit tests for ledge detection geometry and state transitions |
| `tests/test.tscn` | Scene that runs the tests |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [arrow-sprite](../arrow-sprite) — Basic 2D movement with arrow keys, normalized direction, frame-rate-independent motion.
- [grapple-hook](../grapple-hook) — Fire a grapple and swing like a pendulum with a custom AABB-vs-circle collision system.
- [input-recording](../input-recording) — Capturing input per frame and replaying it deterministically.
- [multiplayer-prediction](../multiplayer-prediction) — Applying input locally, then reconciling when the authoritative server disagrees.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

