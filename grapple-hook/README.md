# Grapple Hook

A 2D platformer where the player fires a grapple hook at any surface. When the hook lands, the player swings like a pendulum, with full air control, floor jumping, and a custom AABB-vs-circle collision system — all written without Godot's physics engine.

## Purpose

Grapple hooks are defining mechanics in games like *Bionic Commando*, *Nidhogg 2*, *Just Cause*, and *Celeste*'s Badeline segments. They transform traversal: instead of running around obstacles, players swing over them. Implementing a grapple hook teaches three fundamental techniques at once — projectile travel, taut-rope constraints, and pendulum physics — all of which compose naturally with standard platformer code.

This demo uses a hand-rolled collision system on purpose. Understanding minimum-penetration push-out is a prerequisite for implementing the grapple constraint correctly, because both involve projecting a body onto the nearest surface and canceling the outward velocity component. The same radial velocity cancellation that keeps the player at rope length is the same idea as the floor velocity zeroing in the collision resolver.

## How It Works

### Hook State Machine

The hook is managed by a three-state enum:

```gdscript
enum GState { IDLE, FLYING, ATTACHED }
```

**IDLE** — Standard platformer. Gravity applies, left/right moves the player. Left-click fires the hook.

**FLYING** — The hook tip travels at `HOOK_SPEED = 550 px/s` in the direction of the click. Each frame it checks every platform `Rect2`. The moment `rect.has_point(_hook_pos)` returns true, the state transitions to `ATTACHED` and `_rope_len` is recorded as the current player-to-hook distance.

**ATTACHED** — Pendulum physics. Gravity and damping apply to the player's velocity. After each integration step, the rope length constraint is enforced to keep the player from drifting farther than `_rope_len` from the anchor.

### Pendulum Constraint

```gdscript
var rope := _pos - _hook_pos
if rope.length() > _rope_len:
    var rope_dir := rope.normalized()
    _pos = _hook_pos + rope_dir * _rope_len
    # Remove outward radial velocity
    var radial := rope_dir * _vel.dot(rope_dir)
    if _vel.dot(rope_dir) > 0.0:
        _vel -= radial
```

This is a position-based constraint: if the player has drifted too far, snap them back to exactly `_rope_len`. Then cancel only the outward component of velocity (`dot > 0` means the player is moving away from the anchor). Tangential velocity — the sideways swing — is preserved. The result is a rope that stretches to its limit and then allows a clean pendulum swing without bouncing or jitter.

### Collision Resolution

Platforms are static `Rect2` values. For each platform, the player circle is tested against a radius-expanded rect:

```gdscript
var expanded := Rect2(rect.position - Vector2(PLAYER_R, PLAYER_R), rect.size + Vector2(PLAYER_R * 2.0, PLAYER_R * 2.0))
if not expanded.has_point(_pos):
    continue
```

If the player center is inside the expanded rect, the minimum-penetration axis is chosen and the player is pushed out:

```gdscript
var min_x := minf(overlap_left, overlap_right)
var min_y := minf(overlap_top, overlap_bottom)
if min_x < min_y:
    # push horizontally
else:
    # push vertically — set _on_floor if pushing up
```

This prevents corner-sticking and correctly identifies floor contacts.

## The Velocity Transform at the Rope Limit

When the rope goes taut, only the tangential velocity component remains. Visually, this converts falling-plus-moving-horizontally into a clean arc. The math:

```
radial_component  = dot(vel, rope_dir) * rope_dir   # the part going away from anchor
tangential_vel    = vel - radial_component           # the part swinging sideways
```

The `if _vel.dot(rope_dir) > 0.0` guard is essential: it only cancels outward velocity, not inward. When swinging back toward the anchor, the rope is slack and the player can move freely inward.

## How to Adapt This in Your Project

Replace the hand-rolled collision with `move_and_slide()` on a `CharacterBody2D` — set `_pos` from `global_position` and apply `_vel` through `velocity`. Add multiple hook points for a dual-hook system. Shorten the rope each frame while holding a button to reel in. Clamp `_rope_len` to a maximum value to prevent shooting across the entire level. Add a cooldown timer before the hook can be re-fired to prevent instant re-latching after a miss. To add a chain visual, pass `_pos` and `_hook_pos` to the rope-physics pattern from the rope demo.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Rect2.has_point(pos)` | Hook landing detection against platform rectangles |
| `Vector2.dot(other)` | Decomposes velocity into radial and tangential components |
| `Vector2.normalized()` | Unit direction for rope constraint and impulse application |
| `Vector2.direction_to(target)` | Normalized vector toward the click target for hook launch |
| `Input.get_axis("ui_left", "ui_right")` | Horizontal input as a -1.0 to 1.0 float |
| `pow(SWING_DAMP, delta)` | Frame-rate-independent velocity damping during swing |

## Controls

| Input | Action |
|-------|--------|
| Left / Right Arrow | Move horizontally (reduced control while swinging) |
| Up Arrow | Jump when on floor |
| Left Click | Shoot hook toward cursor; cancel if hook is already flying |
| R | Reset player to starting position |

## Key Constants

```gdscript
const SPEED      := 200.0   # Horizontal run speed (px/s)
const JUMP_VEL   := -360.0  # Upward velocity on jump
const GRAVITY    := 700.0   # Downward acceleration (px/s²)
const HOOK_SPEED := 550.0   # Hook tip travel speed (px/s)
const SWING_DAMP := 0.993   # Per-second velocity multiplier during pendulum swing
const PLAYER_R   := 12.0    # Player collision radius (px)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Player movement, hook state machine, pendulum physics, collision, drawing |
| `scenes/main.tscn` | Root Node2D with main.gd attached; level defined in-script |
| `tests/test_logic.gd` | Unit tests for hook direction, constraint enforcement, and rope length |
| `tests/test.tscn` | Scene that runs the tests |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

