# Line of Sight

Two enemies patrol a side-scrolling scene and switch to ALERT when they have unobstructed physics-raycast line of sight to the player. Walk behind the walls to break detection.

## Purpose

Enemy awareness systems need to distinguish "close enough to detect" from "actually has a clear view." A distance check alone fails: an enemy standing directly behind a thin wall should not see you. Physics raycasting solves this in a single function call — cast a ray from the enemy to the player and check whether anything on the wall collision layer blocks it.

This demo shows the exact Godot 4 API and collision-layer setup required to make raycasts hit walls but not characters. The distance pre-check short-circuits before the raycast on the majority of frames, keeping the per-frame cost minimal. The same pattern scales from two enemies to hundreds.

Compare this to the vision-cone demo, which implements LOS with manual math (Liang-Barsky slab test) on static AABB obstacles. Use physics raycasting (this demo) when your walls are `StaticBody2D` nodes in the scene tree. Use manual math when walls are pure data (Rect2 arrays) with no physics presence.

## How It Works

### Collision Layer Setup

| Object | Layer |
|--------|-------|
| Player, Enemies | 1 |
| Walls | 2 |

The raycast uses `collision_mask = 2` — it only detects objects on layer 2. Enemies and the player are on layer 1, so they are invisible to the ray. Without this separation the ray would immediately "hit" the enemy body it originates from.

### Detection Check (`scripts/enemy.gd`)

```gdscript
func _check_los() -> void:
    if not _player: _can_see = false; return
    var dist := global_position.distance_to(_player.global_position)
    if dist > VISION_RANGE:
        _can_see = false
        return           # skip the raycast — cheap gate first
    _can_see = _has_los(global_position, _player.global_position)
```

Distance check first (one float comparison), raycast only when within range.

### The Raycast (`scripts/line_of_sight.gd`)

The raycast itself is packaged as a one-call static helper, `LineOfSight.is_clear`, so any enemy can reuse it:

```gdscript
static func is_clear(space_state, from, to, obstacle_mask, exclude := []) -> bool:
    var params := PhysicsRayQueryParameters2D.create(from, to)
    params.exclude        = exclude
    params.collision_mask = obstacle_mask
    return space_state.intersect_ray(params).is_empty()   # empty = clear LOS
```

The enemy calls it with its world's space state, the wall mask, and the RIDs to ignore:

```gdscript
func _has_los(from: Vector2, to: Vector2) -> bool:
    return LineOfSight.is_clear(
        get_world_2d().direct_space_state, from, to, 2,
        [self.get_rid(), _player.get_rid()])
```

`exclude` is an `Array[RID]` — the enemy excludes itself and the player so the ray doesn't immediately collide with its origin or destination body. `intersect_ray` returns an empty Dictionary when nothing is hit, so `is_empty()` means "clear line of sight."

### Player Movement (`scripts/player.gd`)

```gdscript
func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
    if is_on_floor() and Input.is_action_just_pressed("ui_up"):
        velocity.y = -380.0
    move_and_slide()
```

Standard `CharacterBody2D` physics — `move_and_slide` handles collision response with walls and floor.

### Visual Feedback (`scripts/enemy.gd`)

```gdscript
func _draw() -> void:
    var body_col := Color.TOMATO if _can_see else Color.CORAL
    draw_circle(Vector2.ZERO, 16, body_col)
    if not _can_see and _player:
        var dir := (_player.global_position - global_position).normalized()
        for i in 18:
            var a := lerp(-0.55, 0.55, float(i) / 17.0)
            draw_line(Vector2.ZERO, dir.rotated(a) * VISION_RANGE, Color(1.0, 0.9, 0.0, 0.04))
    if _can_see and _player:
        var to_player := _player.global_position - global_position
        draw_line(Vector2.ZERO, to_player, Color(1, 0.2, 0.2, 0.6), 2.0)
```

When searching, a faint yellow fan shows the vision arc. When the enemy has LOS, a solid red line connects it to the player.

## Line-of-Sight Theory

The raycast approach has O(1) cost per enemy (one ray, regardless of scene complexity, because the physics broadphase prunes non-overlapping bodies before calling the narrow-phase). Adding 10 enemies adds 10 rays per frame — linear scaling.

For enemies that need directional awareness (should only see forward), add an angle check before the raycast:

```gdscript
var to_player := _player.global_position - global_position
var facing    := Vector2.RIGHT.rotated(rotation)
if facing.dot(to_player.normalized()) < cos(deg_to_rad(60)):
    _can_see = false; return
```

This combines the cone logic from the vision-cone demo with the physics raycast from this demo — the full production pattern.

## How to Adapt This in Your Project

- For multiple players in co-op, cache all player nodes at `_ready()` and check LOS to each. Return true if any player is visible.
- To add peripheral vision, run two raycasts with different angles and `collision_mask` values, or combine with a dot-product angle check.
- For performance with many enemies, throttle `_check_los` to run every 3–5 frames with a staggered offset per enemy (use `Engine.get_process_frames() % 4 == enemy_id % 4`).
- `params.hit_from_inside = true` allows the ray to detect when it starts inside a shape — useful for detecting the player inside a trigger zone.

## Use as a building block

**Copy:** `scripts/line_of_sight.gd` (the `LineOfSight` class — one static method, no dependencies).

**Public API**
- `LineOfSight.is_clear(space_state, from, to, obstacle_mask, exclude := []) -> bool`

**Integrate**
1. `var ss := get_world_2d().direct_space_state`.
2. `if LineOfSight.is_clear(ss, eyes, target, WALL_MASK, [get_rid(), target_rid]): can_see = true`.
3. Gate it behind a cheap distance check (as the enemy does) so the raycast only runs when the target is in range.

**Notes**
- `class_name LineOfSight` is global — rename if it collides.
- Put walls/occluders on their own collision layer and pass that as `obstacle_mask`, so characters don't block each other's sight.
- Combine with [vision-cone](../vision-cone)'s `VisionCone` for a full FOV-cone + physics-occlusion detector.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `get_world_2d().direct_space_state` | Access the physics space for manual queries |
| `PhysicsRayQueryParameters2D.create(from, to)` | Create ray parameters |
| `params.exclude` | `Array[RID]` of bodies the ray ignores |
| `params.collision_mask` | Bitmask — which layers the ray intersects |
| `PhysicsDirectSpaceState2D.intersect_ray(params)` | Fire the ray; returns `{}` if clear |
| `Node.get_rid()` | Get the Resource ID for use in exclusion arrays |
| `CharacterBody2D.move_and_slide()` | Physics-resolved movement with floor/wall detection |
| `Input.get_axis("ui_left", "ui_right")` | Signed axis input from two actions |

## Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move left and right |
| Up / W / Space | Jump |

Walk behind the gray walls to break line of sight. Enemies display "ALERT!" in orange when they see the player and "patrol" at half opacity when searching.

## Key Constants

```gdscript
# enemy.gd
const VISION_RANGE := 320.0   # px — max detection distance

# player.gd
const SPEED   := 180.0        # horizontal speed px/s
const GRAVITY := 900.0        # px/s²
```

## Files

| File | Purpose |
|------|---------|
| `scripts/line_of_sight.gd` | **`LineOfSight`** — reusable raycast occlusion test (`is_clear`) |
| `scripts/enemy.gd` | `CharacterBody2D` enemy: range gate + `LineOfSight.is_clear`, `_draw` |
| `scripts/player.gd` | `CharacterBody2D` player: movement and jump |
| `scenes/main.tscn` | Side-scrolling scene with two enemies, walls, and floor |
| `tests/` | Unit tests for LOS logic |
