# Line of Sight

Enemies detect the player using physics raycasts. Walls on collision layer 2 block sight. Move behind walls to break detection; step into open ground to trigger an alert.

## Purpose

Enemy awareness systems need to distinguish "close enough to detect" from "actually has a clear view." Distance checks alone fail: an enemy through a thin wall shouldn't see you. Physics raycasting solves this in one function call — cast a ray from the enemy to the player, check if anything blocks it. This demo shows the exact Godot 4 API and the collision-layer setup needed to make raycasts only hit walls, not other characters.

## Controls

- **Arrow keys / WASD**: Move, Up / W to jump
- Walk between the walls to see enemies switch between `patrol` and `ALERT!`
- Enemy draws a faint cone showing vision direction, and a red line when it has clear sight

## How It Works

### Collision layers

| Object | Layer |
|--------|-------|
| Player, Enemies | 1 |
| Walls | 2 |
| Floor | 3 (both 1 and 2) |

The raycast uses `collision_mask = 2` — it only detects objects on layer 2 (walls). Enemies and the player are on layer 1, so they don't block each other's rays. The floor is on layer 3 so it participates in physics (layer 1) and also blocks LOS raycasts (layer 2) for underground scenarios.

### `scripts/enemy.gd`

```gdscript
func _has_los(from: Vector2, to: Vector2) -> bool:
    var space  := get_world_2d().direct_space_state
    var params := PhysicsRayQueryParameters2D.create(from, to)
    params.exclude        = [self.get_rid(), _player.get_rid()]
    params.collision_mask = 2   # walls only
    var result := space.intersect_ray(params)
    return result.is_empty()    # empty = nothing blocking = clear LOS
```

`params.exclude` is an `Array[RID]` — the enemy excludes itself and the player so the ray doesn't immediately "hit" the bodies it starts and ends at.

`intersect_ray()` returns an empty `Dictionary` when nothing is hit, and a dictionary with `position`, `normal`, `collider` when it hits something. `is_empty()` is the clean check.

**Full detection:**
```gdscript
func _check_los() -> void:
    var dist := global_position.distance_to(_player.global_position)
    if dist > VISION_RANGE:
        _can_see = false
        return
    _can_see = _has_los(global_position, _player.global_position)
```
Distance check first (cheap), raycast second (more expensive). Short-circuit evaluation avoids unnecessary raycasts.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `get_world_2d().direct_space_state` | Access the physics space for manual queries |
| `PhysicsRayQueryParameters2D.create(from, to)` | Create raycast params |
| `params.exclude` | Array of RIDs to ignore in the cast |
| `params.collision_mask` | Bitmask — which layers the ray hits |
| `PhysicsDirectSpaceState2D.intersect_ray(params)` | Fire the ray; returns {} if clear |
| `Node.get_rid()` | Get the resource ID for use in exclusion arrays |
