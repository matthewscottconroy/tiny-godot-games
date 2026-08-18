# Homing Projectile

<!-- tags: component -->

A missile that steers toward a moving target each frame using `lerp_angle` on its velocity direction. Speed stays constant — only the heading rotates toward the target.

## Purpose

Homing projectiles are a staple of shmups, action-RPGs, and tower-defense games. Classics like *Gradius*, *Ikaruga*, and virtually every JRPG magic system rely on some form of guided munition. The mechanic creates a fundamentally different gameplay dynamic from straight-line projectiles: the player feels hunted, or rewarded when a missile finally connects after a long arc. The challenge for designers is tuning `TURN_SPEED` — too fast and the weapon is unfair; too slow and it misses entirely against agile targets.

The core insight is that homing is just angle interpolation applied to velocity every frame. There is no complex physics simulation: compute the angle from projectile to target, smoothly rotate the current heading toward it by a capped amount, then rebuild the velocity vector at the original speed. The math is three lines.

This demo isolates the homing logic from everything else, making it easy to transplant into any action game. The projectile is a plain `Node2D` with a manually-managed velocity rather than a `CharacterBody2D`, which keeps the per-frame math explicit and portable.

## How It Works

### Node Tree

```
Main (Node2D)          ← main.gd
├── Target (Node2D)    ← draggable target square
└── [HomingProjectile ×N]   ← projectile.gd, spawned at runtime
```

The projectile is a self-contained class, `HomingProjectile`
(`scripts/projectile.gd`), so it's the drop-in part: `main.gd` just spawns one
per shot and hands it a start position, direction, and target.

### Spawning (`scripts/main.gd`)

```gdscript
func _fire() -> void:
    var proj := HomingProjectile.new()
    add_child(proj)
    proj.init(Vector2(90, 240), Vector2.RIGHT, _target)
```

Projectiles are created at runtime without a `.tscn` file — because `HomingProjectile` has a `class_name`, `new()` is all it takes (no `preload`/`set_script` dance).

### Steering (`scripts/projectile.gd`)

```gdscript
@export var speed := 280.0
@export var turn_speed := 3.5

func _process(delta: float) -> void:
    if is_instance_valid(_target):
        var to_target := (_target.global_position - global_position).angle()
        var cur_angle := _vel.angle()
        var new_angle := lerp_angle(cur_angle, to_target, turn_speed * delta)
        _vel           = Vector2.from_angle(new_angle) * speed

    _trail.append(position)
    if _trail.size() > 12:
        _trail.pop_front()

    position += _vel * delta
    rotation  = _vel.angle()
```

Three steps every frame: compute target angle, lerp the heading, rebuild velocity at constant speed. The `rotation` assignment aligns the drawn sprite with travel direction automatically.

### Trail

Previous positions are stored in `_trail` (capped at 12 entries). Each is drawn as a small yellow circle with opacity proportional to its age — older entries are more transparent.

## Homing Algorithm

### `lerp_angle` vs `lerpf`

Angles wrap at ±π. If the projectile faces 170° and the target is at −170°, `lerpf` would rotate the long way around (340°). `lerp_angle` always takes the shortest arc (20° in this case). This is essential for homing that crosses the ±180° boundary.

### Speed Preservation

```gdscript
_vel = Vector2.from_angle(new_angle) * SPEED
```

The velocity is rebuilt from scratch each frame at exactly `SPEED` magnitude. Accumulating angle increments on the existing vector would introduce floating-point drift that slowly changes the projectile's speed.

### Turn Rate and Maneuverability

`TURN_SPEED = 3.5` means the projectile closes ~3.5 radians per second at full weight — roughly a half-circle in under a second. Against a target moving at typical game speeds, this allows the missile to curve but not instantly snap. Design implications:

- `TURN_SPEED < 2.0` — homing arc, easily dodged
- `TURN_SPEED 2–5` — standard homing missile feel
- `TURN_SPEED > 8.0` — nearly instant tracking, feels unfair

### Target Validity

```gdscript
if is_instance_valid(_target):
```

The target may be destroyed mid-flight. Without this check, reading `_target.global_position` on a freed node crashes with a null-object error. With it, the projectile travels straight after the target disappears — a natural-feeling behavior at no extra cost.

## How to Adapt This in Your Project

**Wire to an enemy:** Replace `_target` with any `Node2D`. Pass the closest enemy reference from your game manager via `init()`.

**Multiple targets:** Track the nearest enemy by sorting `get_tree().get_nodes_in_group("enemies")` by distance at spawn time.

**Proximity detonation:** Add a collision check each frame — `position.distance_to(_target.global_position) < 20.0` — and call `queue_free()` plus emit an explosion signal.

**Predictive homing:** Instead of targeting the current position, offset the target by `_target.velocity * time_to_intercept` for a lead-aim missile that never misses a moving target.

**Spawn from a scene:** Once you need a sprite, sound, or collision shape, save the projectile as a `.tscn` and `instantiate()` it instead of `HomingProjectile.new()`.

## Use as a building block

**Copy:** `scripts/projectile.gd` (the `HomingProjectile` class). It's a self-contained `Node2D` — spawn it, `init()` it, and it flies and cleans itself up.

**Public API**
- `@export speed` / `turn_speed` / `lifetime` — tune per-weapon in the Inspector.
- `init(pos, dir, target)` — start position, initial heading, and the `Node2D` to chase.

**Integrate**
1. `var proj := HomingProjectile.new(); add_child(proj)`.
2. `proj.init(muzzle_pos, aim_dir, nearest_enemy)`.
3. It steers toward the target at constant speed, flies straight if the target is freed, and self-frees after `lifetime`.

**Notes**
- `class_name HomingProjectile` is global — rename if it collides.
- `turn_speed` is the whole feel dial: low = lazy, dodgeable missiles; high = near-unavoidable. For lead-aim, pass a predicted target position.
- Add damage by checking `position.distance_to(target)` each frame, or promote it to a scene with an `Area2D` for real collision.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `lerp_angle(from, to, weight)` | Interpolate angles via the shortest arc |
| `Vector2.from_angle(angle)` | Build a unit vector from radians |
| `Vector2.angle()` | Extract the angle of a vector in radians |
| `is_instance_valid(node)` | Safe check before accessing a potentially-freed node |
| `class_name` + `Type.new()` | Instantiate a scripted node by type, no `preload` needed |
| `@export var` | Expose tuning (speed, turn rate) to the Inspector |

## Controls

| Input | Action |
|-------|--------|
| Space (`ui_select`) | Fire a homing projectile |
| (no movement — target is fixed in the scene) | |

## Key Constants

```gdscript
# projectile.gd — @export fields (defaults shown)
@export var speed := 280.0       # pixels per second — projectile travel speed
@export var turn_speed := 3.5    # radians per second — how quickly it steers
@export var lifetime := 4.0      # seconds before auto-cleanup
# trail cap: 12 positions stored, rendered with alpha fade
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Spawns projectiles on Space, draws the gun and target, tracks fire count |
| `scripts/projectile.gd` | **`HomingProjectile`** — reusable steering, trail, lifetime |
| `tests/test_logic.gd` | Unit tests: angle convergence, speed preservation, trail cap, lifetime |

## Related demos

- [boid-flocking](../boid-flocking) — 35 agents flock via separation, alignment, and cohesion — emergent behavior.
- [groups](../groups) — Broadcast a method call to every node in a named group in one line.
- [radial-menu](../radial-menu) — Hold Tab to open a six-item radial action menu.
- [tool-script](../tool-script) — `@tool`: a layout helper that arranges its children in the editor, before the game runs.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

