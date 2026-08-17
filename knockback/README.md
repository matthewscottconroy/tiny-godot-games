# Knockback

Velocity-based hit recoil: a separate `_knockback` vector is computed on contact, layered on top of normal movement velocity, and decays exponentially each frame. Patrolling enemies trigger hits via `Area2D` overlap, and invincibility frames prevent stun-locking.

## Purpose

Knockback is deceptively difficult to get right. The naive implementation sets `velocity = impulse_direction * strength`, which completely cancels player input momentum and creates an unresponsive, frustrating feel. A better approach maintains a separate knockback vector that adds to control velocity — the player still has partial influence during the recoil arc. This is the approach used in *Hollow Knight*, *Dead Cells*, and most action platformers that feel good to play.

The supporting systems matter just as much as the knockback itself. Without invincibility frames, a player inside a patrol enemy takes repeated hits every physics frame, resulting in instant death. Without the `_knockback.y` one-shot pattern, the upward component would fight gravity every frame rather than launching the player upward once and letting gravity take back over naturally. Each of these details is a solved pattern that appears across many genres.

## How It Works

The recoil state and math live in a reusable class, `Knockback`
(`scripts/knockback.gd`), a plain `RefCounted`. The player *owns* one
(`var _kb := Knockback.new()`) and layers its `velocity` on top of normal
control each frame. The player script keeps only movement + drawing; the recoil
is the drop-in part.

### Separation of Knockback and Control Velocity

The knockback velocity is kept separate from the body's `velocity` and summed in:

```gdscript
func _physics_process(delta: float) -> void:
    _kb.update(delta)                       # decays knockback + ages i-frames

    var ctrl_x := Input.get_axis("ui_left", "ui_right") * SPEED
    velocity.x = ctrl_x + _kb.velocity.x
    if _kb.velocity.y != 0.0:               # upward pop applied once...
        velocity.y = _kb.velocity.y
        _kb.velocity.y = 0.0                # ...then gravity takes over
```

`velocity.x` is always the sum of control input and horizontal knockback, so the player can partially fight or ride the recoil. The vertical pop is consumed in a single frame — applied to `velocity.y` and immediately zeroed — so the player arcs up once instead of being pushed up every frame.

### Hit Detection and Direction

When an enemy's `Area2D` overlaps the player, it calls `take_hit(global_position)`, which forwards to `Knockback.hit()`:

```gdscript
func take_hit(from: Vector2) -> void:
    if _kb.hit(from, global_position):      # false while invincible
        _hp = maxi(_hp - 1, 0)
```

Inside `Knockback.hit(source, target)`, `(target - source).normalized()` is the unit vector pointing from the enemy toward the player, so the player is pushed away from whatever hit them. The horizontal component is `dir.x * impulse`; `up = -260` is a fixed upward component regardless of direction, giving every hit the same arc height. `hit()` returns `false` (and does nothing) while i-frames are active, which is why HP only drops on a real hit.

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

### Knockback Decay and I-frames (inside `Knockback.update`)

```gdscript
func update(delta: float) -> void:
    iframes = maxf(iframes - delta, 0.0)
    velocity = velocity.lerp(Vector2.ZERO, decay_rate * delta)
```

`velocity.lerp(Vector2.ZERO, weight)` moves the knockback toward zero each frame. With `decay_rate = 7.0`, it reaches near-zero in about 0.3–0.4 seconds — higher values give snappy recoil, lower values a long slide. `iframes` counts down from 0.8 s; while it's positive `hit()` no-ops, and the player flashes red (`_kb.is_invincible()`).

## How to Adapt This in Your Project

Add `KB_DECAY` as an exported parameter on the player to let designers tune recovery time per character or per hit type. For directional knockback (e.g., a downward slam), compute `dir` from hit normal instead of hit position. For knockback resistance, multiply `KB_IMPULSE` by a `resistance` stat before applying. To implement hitlag (brief slowdown on hit), set `Engine.time_scale = 0.1` for 4–6 frames on hit and restore it after. For multi-hit combos, extend `_iframes` per-hit and track a `hit_count` to scale escalating knockback.

Pitfall: never apply `_kb.velocity.y` directly to `velocity.y` every frame without zeroing it. If you forget the `_kb.velocity.y = 0.0` after the first application, the upward force fights gravity every frame and the player floats indefinitely.

## Use as a building block

**Copy:** `scripts/knockback.gd` (the `Knockback` class). It's a `RefCounted` with no scene dependencies — pure vector math.

**Public API**
- tuning: `impulse`, `up`, `decay_rate`, `iframe_time`
- state: `velocity: Vector2`, `iframes: float`
- `hit(source, target) -> bool` — apply recoil away from `source`; `false` if still invincible.
- `update(delta)` — decay velocity + age i-frames (call each frame).
- `is_invincible() -> bool`

**Integrate** (on any `CharacterBody2D`)
1. `var _kb := Knockback.new()` (tweak `_kb.impulse` etc. if desired).
2. Each frame: `_kb.update(delta)`, then `velocity.x = control_x + _kb.velocity.x` and apply `_kb.velocity.y` once (zero it after).
3. On damage: `if _kb.hit(attacker_pos, global_position): hp -= 1`.

**Notes**
- `class_name Knockback` is global — rename if it collides.
- For knockback resistance, scale `impulse` per character. For a downward slam, pass the hit normal instead of a position as `source`.

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
# player.gd — movement
const SPEED    := 200.0   # Horizontal run speed (px/s)
const JUMP_VEL := -400.0  # Upward velocity on jump
const GRAVITY  := 900.0   # Downward acceleration (px/s²)

# knockback.gd — recoil tuning (fields, tweak per instance)
var impulse     := 480.0  # Horizontal knockback strength (px/s)
var up          := -260.0 # Vertical knockback component (fixed upward launch)
var decay_rate  := 7.0    # Knockback decay (higher = shorter duration)
var iframe_time := 0.8    # Invincibility duration after a hit (s)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/knockback.gd` | **`Knockback`** — reusable recoil + i-frames (`hit`/`update`) |
| `scripts/player.gd` | Movement + drawing; owns a `Knockback` and layers its velocity in |
| `scripts/enemy.gd` | Patrolling `Area2D` that calls `take_hit()` on the player |
| `scripts/main.gd` | Draws the floor |
| `scripts/enemy.gd` | Patrol movement, Area2D hit detection, duck-typed `take_hit` dispatch |
| `scripts/main.gd` | Scene background drawing |
| `scenes/main.tscn` | Player CharacterBody2D, two patrolling enemies, floor |
| `tests/test_logic.gd` | Unit tests for knockback direction, decay, iframe blocking, and velocity composition |
| `tests/test.tscn` | Scene that runs the tests |

## Related demos

- [status-effects](../status-effects) — Poison/burn/freeze as timed, stackable, data-driven modifiers.
- [health-bar](../health-bar) — A complete HP system with animated bar, feedback flashes, and game-over.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

