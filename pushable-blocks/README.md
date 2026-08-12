# Pushable Blocks

A player that shoves `CharacterBody2D` blocks by walking into them. Push impulses are read from `move_and_slide()` collision data and applied directly to the block's velocity, with exponential friction for natural deceleration.

## Purpose

Interactive environment objects — crates, barrels, boulders — appear in virtually every genre: *Portal* and *The Witness* use blocks as puzzle elements, *The Legend of Zelda* series built an entire dungeon vocabulary around pushing blocks onto pressure plates, and modern platformers use them as moving terrain. The mechanic creates player agency over the environment and opens a design space of puzzles that feel physical and satisfying.

Godot's `CharacterBody2D` does not push other `CharacterBody2D` nodes automatically — both bodies stop at the collision surface. The solution is to read the collision normal from `get_slide_collision()` after `move_and_slide()` and apply a velocity impulse to the block manually. This approach is more predictable than using `RigidBody2D`, where gameplay-relevant push strength depends on mass, friction coefficients, and the physics solver's internal state.

The friction system (`lerpf` toward zero) gives blocks a natural slide-and-stop feel. Blocks don't snap to a halt instantly; they coast for a fraction of a second, which reads as "weight" without requiring a physics simulation.

## How It Works

### Node Tree

```
Main (Node2D)                      ← main.gd (floor geometry)
├── Player (CharacterBody2D)       ← player.gd
├── Block (CharacterBody2D)        ← pushable.gd
├── Block (CharacterBody2D)
└── Block (CharacterBody2D)
```

Blocks are in the `"pushable"` group so the player can identify them by type without `instanceof` checks against a custom class.

### Push Detection (`scripts/player.gd`)

```gdscript
const PUSH_STR := 240.0

func _physics_process(delta: float) -> void:
    # ... normal movement ...
    move_and_slide()

    for i in get_slide_collision_count():
        var col  := get_slide_collision(i)
        var body := col.get_collider()
        if body is CharacterBody2D and body.is_in_group("pushable"):
            body.push(-col.get_normal().x * PUSH_STR)
```

After `move_and_slide()` resolves all collisions, `get_slide_collision_count()` returns the number of surfaces touched this frame. For each collision, `get_collider()` returns the physics body that was hit. If it is a pushable block, `push()` is called with the horizontal push strength.

`col.get_normal()` is the surface normal pointing from the block toward the player. Negating it gives the direction from the player into the block (the push direction). Only `.x` is used — blocks should not be launched upward by a walking collision.

### Block Velocity with Friction (`scripts/pushable.gd`)

```gdscript
const GRAVITY  := 900.0
const FRICTION := 5.5

var _push_vel := 0.0

func push(horizontal_strength: float) -> void:
    _push_vel = horizontal_strength

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    velocity.x = _push_vel
    _push_vel  = lerpf(_push_vel, 0.0, FRICTION * delta)
    if absf(_push_vel) < 1.0:
        _push_vel = 0.0
    move_and_slide()
```

`_push_vel` is separate from `velocity.x` so it can carry friction state across frames. Each frame, `velocity.x` is assigned from `_push_vel`, then `_push_vel` decays toward zero via `lerpf`. The `absf < 1.0` snap prevents the exponential decay from running forever with a near-zero velocity.

### Why `lerpf` Friction Feels Natural

Linear friction reduces velocity by the same amount each frame, stopping abruptly:
```
t=0: 240  t=1: 200  t=2: 160 ... t=5: 40  t=6: 0  (sharp stop)
```

Exponential friction (`lerpf` toward zero) reduces velocity by a fraction each frame:
```
t=0: 240  t=0.1: 226  t=0.2: 213 ... (smooth asymptotic approach to 0)
```

The exponential profile is physically analogous to air resistance and matches how real objects slow down. It also makes the block feel heavier — it takes more distance to stop at the same initial speed.

## How to Adapt This in Your Project

**Limit push to horizontal-only contacts:** The current code filters by `-col.get_normal().x`. If you want to allow vertical pushing (for a top-down game), use `body.push_2d(-col.get_normal() * PUSH_STR)` and handle both axes in the block.

**Stack physics:** If a block hits a wall, its `move_and_slide()` stops it but `_push_vel` continues decaying naturally — no special case needed. The block just stops sooner.

**Weight variation:** Add `@export var push_resistance: float = 1.0` to the block script and apply it in the player: `body.push(-col.get_normal().x * PUSH_STR / body.push_resistance)`. Heavier blocks need more force.

**Trigger on rest:** Check `absf(_push_vel) < 1.0 and was_moving` to emit a signal when the block comes to a stop — useful for puzzle games that check block positions on each rest.

**Visual feedback:** Change `block_color` on push and lerp it back over 0.5 seconds to indicate a block was just shoved.

**Group filtering:** Replace `body.is_in_group("pushable")` with a custom class check (`body is PushableBlock`) once you subclass the pushable script for type safety.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CharacterBody2D.get_slide_collision_count()` | Number of surfaces touched in the last `move_and_slide()` call |
| `CharacterBody2D.get_slide_collision(i)` | `KinematicCollision2D` for the i-th contact point |
| `KinematicCollision2D.get_collider()` | The physics body at the contact |
| `KinematicCollision2D.get_normal()` | Surface normal pointing from collider toward the character |
| `Node.is_in_group(name)` | Group membership check — avoids hard-coded type names |
| `lerpf(a, b, t)` | Exponential decay toward zero for friction |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys | Move |
| Up | Jump |
| Walk into a block | Push it |

## Key Constants

```gdscript
# player.gd
const PUSH_STR := 240.0    # initial horizontal velocity applied to the block

# pushable.gd
const GRAVITY  := 900.0    # block falls if not on floor
const FRICTION := 5.5      # lerpf rate toward zero — higher = stops sooner
```

## Files

| File | Purpose |
|------|---------|
| `scripts/player.gd` | Movement, collision loop, push impulse application |
| `scripts/pushable.gd` | Block movement, `push()` API, exponential friction, gravity |
| `scripts/main.gd` | Static floor geometry |

## Use as a building block

**Copy:** `scripts/player.gd`, `scripts/pushable.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/pushable.gd`**
- `@export block_color: Color`
- `push(horizontal_strength: float) -> void`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

