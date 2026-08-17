# Spread Shot

Fires a configurable burst of N bullets distributed evenly across a fixed angle. Each bullet travels in a straight line; only the initial direction differs between them.

## Purpose

Shotgun-style spread fire is one of the oldest and most satisfying attack patterns in games, appearing in everything from *Contra* and *Doom* to modern roguelikes like *Enter the Gungeon* and *Hades*. It rewards close-range aggression, punishes distance, and creates a coverage pattern that makes the player feel powerful without being as precise as a single aimed shot.

The spread pattern is purely about how initial directions are distributed. There is no physics interaction between bullets — each one is an independent projectile. This means the entire spread can be computed in a single loop, and the math reduces to one `lerpf` call per bullet. Understanding this decomposition makes it trivial to extend: increase bullet count, widen the arc, add randomness, or weight the center bullets more heavily.

A fire cooldown (`FIRE_COOLDOWN = 0.45s`) prevents spam and gives each burst a distinct sound and visual beat, which is essential for the mechanic to feel deliberate rather than automatic.

## How It Works

### Node Tree

```
Main (Node2D)              ← main.gd (draws floor/platforms)
└── Player (CharacterBody2D) ← player.gd
    └── InfoLabel (Label)
```

Bullets are spawned as children of `Main` (the player's parent), not of the player itself, so they persist after the player moves away.

### Spread Calculation (`scripts/player.gd`)

```gdscript
const BULLET_COUNT := 5
const SPREAD_DEG   := 40.0

func _fire() -> void:
    var half := deg_to_rad(SPREAD_DEG * 0.5)   # 0.349 rad
    var base := Vector2(_facing, 0.0)           # right or left unit vector
    for i in BULLET_COUNT:
        var t     := float(i) / (BULLET_COUNT - 1) if BULLET_COUNT > 1 else 0.5
        var angle := lerpf(-half, half, t)
        var b     := Node2D.new()
        b.set_script(BulletScript)
        get_parent().add_child(b)
        b.init(global_position + base * 22.0, base.rotated(angle))
```

`t` runs from `0.0` to `1.0` across the bullet count. `lerpf(-half, half, t)` maps that to an angle from `−20°` to `+20°`. `base.rotated(angle)` applies the offset to the facing direction.

| Bullet | t | angle | direction |
|--------|---|-------|-----------|
| 0 | 0.00 | −20° | top of spread |
| 1 | 0.25 | −10° | |
| 2 | 0.50 |   0° | straight ahead |
| 3 | 0.75 | +10° | |
| 4 | 1.00 | +20° | bottom of spread |

The center bullet always travels exactly straight, regardless of `BULLET_COUNT`.

### Bullet Script (`scripts/bullet.gd`)

```gdscript
const SPEED   := 420.0
const LIFETIME := 1.4

func _process(delta: float) -> void:
    _age += delta
    if _age >= LIFETIME or position.x < -50.0 or position.x > 700.0:
        queue_free()
        return
    position += _vel * delta
    rotation  = _vel.angle()
```

Bullets use `_process`, not `_physics_process` — there is no collision or gravity. Cleanup happens by lifetime or out-of-bounds check. Both checks in the same `if` prevent bullets from living forever when fired off the side of the screen.

## Spread Shot Math

### Uniform Distribution

The `t = i / (N-1)` parameterization guarantees perfectly even angular spacing. The edge case `BULLET_COUNT == 1` uses `t = 0.5` so the single bullet goes straight ahead rather than to one edge.

### Facing Direction

`_facing` is `+1.0` or `−1.0`, updated whenever horizontal input is non-zero:

```gdscript
if h != 0.0:
    _facing = sign(h)
```

`base = Vector2(_facing, 0.0)` is already a unit vector (length 1) pointing left or right. `base.rotated(angle)` preserves the unit length, so `init()` receives a normalized direction and scales it by `SPEED`.

### Spawn Offset

`global_position + base * 22.0` spawns bullets just in front of the gun barrel rather than at the player's center, preventing them from immediately overlapping the player's hitbox.

## How to Adapt This in Your Project

**Change bullet count or spread:** Modify `BULLET_COUNT` and `SPREAD_DEG` in `player.gd`. They are independent — 12 bullets at 20° is very tight; 3 bullets at 90° is a wide-angle burst.

**Add spread randomness:** Replace the uniform `t` with `t + randf_range(-0.1, 0.1)` for a "buckshot" feel where bullets are not perfectly evenly spaced.

**Aim at the cursor:** Replace `base = Vector2(_facing, 0.0)` with `base = (get_global_mouse_position() - global_position).normalized()` for top-down shooter aiming.

**Upgrade to a scene:** Replace `Node2D.new()` + `set_script()` with `preload("res://scenes/bullet.tscn").instantiate()` once bullets need sprites, sounds, or Area2D collision shapes.

**Cooldown HUD:** The `InfoLabel` already displays `READY` or a countdown. Wire this to a progress bar for a visual reload meter.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.rotated(angle)` | Rotate a direction vector by radians |
| `lerpf(a, b, t)` | Evenly distribute bullets across the spread range |
| `deg_to_rad(degrees)` | Convert designer-friendly degrees to radians |
| `preload("res://scripts/bullet.gd")` | Load script resource at parse time |
| `node.set_script(script)` | Attach a script to a dynamically-created node |
| `Input.get_axis("ui_left", "ui_right")` | Read horizontal input as a −1/0/+1 float |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys | Move and face left or right |
| Up | Jump |
| Space (`ui_select`) | Fire spread shot in the facing direction |

## Key Constants

```gdscript
const BULLET_COUNT  := 5      # number of bullets per burst
const SPREAD_DEG    := 40.0   # total arc in degrees (±20° from center)
const FIRE_COOLDOWN := 0.45   # seconds between bursts
const SPEED         := 420.0  # bullet travel speed (in bullet.gd)
const LIFETIME      := 1.4    # bullet auto-cleanup time in seconds
```

## Files

| File | Purpose |
|------|---------|
| `scripts/player.gd` | Movement, cooldown timer, spread-shot spawn loop |
| `scripts/bullet.gd` | Straight-line travel, lifetime/bounds cleanup |
| `scripts/main.gd` | Static background geometry (floor, platforms) |

## Use as a building block

**Copy:** `scripts/bullet.gd`, `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/bullet.gd`**
- `init(pos: Vector2, dir: Vector2) -> void`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [cooldown-shoot](../cooldown-shoot) — Projectile instantiation with a cooldown timer and `ProgressBar` indicator.
- [object-pool](../object-pool) — Pre-allocate and recycle objects instead of creating/destroying them.
- [coin-collector](../coin-collector) — Scene instancing, custom signals, and `Area2D` pickups for a collect-all goal.
- [destructibles](../destructibles) — Click boxes to shatter them into scattered `RigidBody2D` fragments.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

