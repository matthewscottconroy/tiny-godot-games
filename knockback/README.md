# Knockback

Velocity-based hit recoil: a separate `_knockback` vector is computed on contact, layered on top of normal movement velocity, and decays exponentially each frame. Patrolling enemies trigger hits via `Area2D` overlap, and invincibility frames prevent stun-locking.

## Purpose

Knockback is deceptively difficult to get right. The naive implementation sets `velocity = impulse_direction * strength`, which completely cancels player input momentum and creates an unresponsive, frustrating feel. A better approach maintains a separate knockback vector that adds to control velocity — the player still has partial influence during the recoil arc. This is the approach used in *Hollow Knight*, *Dead Cells*, and most action platformers that feel good to play.

The supporting systems matter just as much as the knockback itself. Without invincibility frames, a player inside a patrol enemy takes repeated hits every physics frame, resulting in instant death. Without the `_knockback.y` one-shot pattern, the upward component would fight gravity every frame rather than launching the player upward once and letting gravity take back over naturally. Each of these details is a solved pattern that appears across many genres.

## How It Works

### Separation of Knockback and Control Velocity

The player keeps `_knockback` as a separate `Vector2`, distinct from `velocity`:

```gdscript
var _knockback := Vector2.ZERO

func _physics_process(delta: float) -> void:
    _knockback = _knockback.lerp(Vector2.ZERO, KB_DECAY * delta)

    var ctrl_x := Input.get_axis("ui_left", "ui_right") * SPEED
    velocity.x  = ctrl_x + _knockback.x
    if _knockback.y != 0.0:
        velocity.y   = _knockback.y
        _knockback.y = 0.0
```

`velocity.x` is always the sum of control input and horizontal knockback. The player can partially fight or ride the knockback by pressing the opposite or same direction. `_knockback.y` is consumed in one frame — applied to `velocity.y` and immediately zeroed. This launches the player upward once; after that, gravity takes over naturally and the player arcs back down without being pushed up every frame.

### Hit Detection and Direction

When an enemy's `Area2D` overlaps the player, it calls `take_hit(global_position)`:

```gdscript
func take_hit(from: Vector2) -> void:
    if _iframes > 0.0:
        return
    var dir    := (global_position - from).normalized()
    _knockback  = Vector2(dir.x * KB_IMPULSE, KB_UP)
    _iframes    = 0.8
    _hp         = maxi(_hp - 1, 0)
```

`(global_position - from).normalized()` is the unit vector pointing from the enemy toward the player — the player is pushed away from whatever hit them. The horizontal component is `dir.x * KB_IMPULSE`, preserving the diagonal direction from the hit. `KB_UP = -260` is a fixed upward component regardless of direction, giving every hit the same arc height.

### Enemy Hit Detection via Area2D

The enemy is a plain `Node2D` (not a physics body) that doesn't block the player's movement:

```gdscript
func _ready() -> void:
    _origin = position
    _area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.has_method("take_hit"):
        body.take_hit(global_position)
```

`has_method("take_hit")` is duck-typed dispatch — the enemy doesn't depend on a specific class or interface, only on the target having a `take_hit` method. This pattern allows multiple object types (player, destructible objects, other enemies) to receive hits without changing the enemy script.

### Knockback Decay

```gdscript
_knockback = _knockback.lerp(Vector2.ZERO, KB_DECAY * delta)
```

`Vector2.lerp(Vector2.ZERO, weight)` moves the knockback toward zero each frame by `KB_DECAY * delta`. With `KB_DECAY = 7.0`, the knockback reaches near-zero in about 0.3–0.4 seconds. Higher values create snappy, short-duration knockback; lower values create long, sliding recoil.

### Invincibility Frames

```gdscript
_iframes = maxf(_iframes - delta, 0.0)
```

`_iframes` counts down from 0.8 seconds after a hit. While `_iframes > 0`, `take_hit` returns early without applying any effect. The player flashes red during this window:

```gdscript
var col := Color(1.0, 0.3, 0.3, 0.5) if _iframes > 0.0 else Color.DODGER_BLUE
```

## How to Adapt This in Your Project

Add `KB_DECAY` as an exported parameter on the player to let designers tune recovery time per character or per hit type. For directional knockback (e.g., a downward slam), compute `dir` from hit normal instead of hit position. For knockback resistance, multiply `KB_IMPULSE` by a `resistance` stat before applying. To implement hitlag (brief slowdown on hit), set `Engine.time_scale = 0.1` for 4–6 frames on hit and restore it after. For multi-hit combos, extend `_iframes` per-hit and track a `hit_count` to scale escalating knockback.

Pitfall: never apply `_knockback.y` directly to `velocity.y` every frame without zeroing it. If you forget the `_knockback.y = 0.0` after the first application, the upward force fights gravity every frame and the player floats indefinitely.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.lerp(to, weight)` | Exponential decay of knockback toward zero each frame |
| `Area2D.body_entered` | Signal fired when a `CharacterBody2D` enters the enemy's hit area |
| `has_method("take_hit")` | Duck-typed dispatch without requiring a specific class |
| `(global_pos - from).normalized()` | Direction vector pointing away from hit source |
| `maxi(value, 0)` | Clamps HP to prevent going negative |
| `maxf(iframes - delta, 0.0)` | Countdown timer that stops at zero |
| `move_and_slide()` | Applies `velocity` and resolves platform collisions |

## Controls

| Input | Action |
|-------|--------|
| Left / Right Arrow | Move (partial control retained during knockback) |
| Up Arrow | Jump |
| — | Walk into enemies to take knockback hits |

## Key Constants

```gdscript
const SPEED      := 200.0   # Horizontal run speed (px/s)
const JUMP_VEL   := -400.0  # Upward velocity on jump
const GRAVITY    := 900.0   # Downward acceleration (px/s²)
const KB_IMPULSE := 480.0   # Horizontal knockback strength (px/s)
const KB_UP      := -260.0  # Vertical knockback component (fixed upward launch)
const KB_DECAY   := 7.0     # Knockback decay rate (higher = shorter duration)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/player.gd` | Knockback vector, iframes, take_hit(), velocity composition, drawing |
| `scripts/enemy.gd` | Patrol movement, Area2D hit detection, duck-typed `take_hit` dispatch |
| `scripts/main.gd` | Scene background drawing |
| `scenes/main.tscn` | Player CharacterBody2D, two patrolling enemies, floor |
| `tests/test_logic.gd` | Unit tests for knockback direction, decay, iframe blocking, and velocity composition |
| `tests/test.tscn` | Scene that runs the tests |
