# Raycasting

Demonstrates `RayCast2D` for line-of-sight detection: a ray cast from the scene center toward the mouse cursor that detects the first wall it hits and shows the collision point.

## Purpose

Raycasting has a wide range of applications: line-of-sight for AI, bullet trajectory, cursor picking, laser beams, shadow casters, and distance sensors. This demo shows the core API: directing a ray, forcing an update each frame, reading collision results, and visualizing them.

## Controls

- Move the **mouse** to aim the ray
- The ray extends from the center of the scene toward the mouse, stops at the first wall
- A red dot appears at the hit point; the `Line2D` follows the ray

## How It Works

### Node Tree

```
Main (Node2D)                 ← ray_demo.gd
├── RayCast2D
├── Line2D                    (two-point line from origin to ray endpoint)
└── (three StaticBody2D walls defined in the scene)
```

### `scripts/ray_demo.gd`

```gdscript
func _process(_delta: float) -> void:
    var mouse_local := to_local(get_global_mouse_position())
    var direction   := mouse_local.normalized()
    ray.target_position = direction * RAY_LENGTH  # 700 px

    ray.force_raycast_update()

    if ray.is_colliding():
        _hit_point = to_local(ray.get_collision_point())
        _is_hitting = true
        line.set_point_position(1, _hit_point)
    else:
        _is_hitting = false
        line.set_point_position(1, direction * RAY_LENGTH)

    queue_redraw()
```

Key steps each frame:
1. **Convert mouse to local space** — `to_local()` converts the global mouse position into the coordinate space of this node (centered at the scene origin).
2. **Set target position** — `ray.target_position` is the endpoint relative to the ray's own position. It is set each frame to point toward the mouse.
3. **Force update** — `force_raycast_update()` immediately recalculates the raycast result. Without this, the ray uses the previous frame's result.
4. **Read results** — `is_colliding()` and `get_collision_point()` (in global space, converted back to local via `to_local()`).
5. **Update Line2D** — point 0 stays at the origin; point 1 moves to the hit point or ray end.
6. **Draw hit marker** — `_draw()` draws a red circle at `_hit_point` if `_is_hitting`.

### `_draw()`

```gdscript
func _draw() -> void:
    draw_rect(...)  # Three wall rectangles (StaticBody2D has no built-in visual)
    draw_circle(Vector2(320, 240), 6, Color.WHITE)  # Ray origin
    if _is_hitting:
        draw_circle(_hit_point, 7, Color.RED)
```

`StaticBody2D` is invisible by default. `_draw()` renders rectangles matching each wall's position and size so the scene makes visual sense.

## Raycasting Theory

### What a Raycast Is

A ray is a semi-infinite line starting at a point and extending in a direction. A **raycast** tests this line against geometry and returns the first intersection. In 2D, the geometry is collision shapes; in 3D, it is mesh triangles.

### RayCast2D Properties

- **`position`** — The ray's origin in local space (default: node position)
- **`target_position`** — The ray endpoint, relative to the ray's `position`. The ray direction and length are derived from this.
- **`enabled`** — Whether the ray is active
- **`hit_from_inside`** — Whether to detect collision when the origin is inside a shape

### force_raycast_update()

By default, `RayCast2D` updates its collision result once per physics frame. Using `force_raycast_update()` in `_process()` ensures the result is current even when `_process()` runs more often than the physics step. This is important for smooth, responsive ray visualization.

### Coordinate Space: Local vs Global

`ray.target_position` is **local** to the `RayCast2D` node. `ray.get_collision_point()` returns a **global** position. To draw the hit point using `_draw()` (which uses the node's local coordinate space), it must be converted: `to_local(ray.get_collision_point())`.

Similarly, the mouse position from `get_global_mouse_position()` is in global space. `to_local()` converts it to the Main node's local space.

### get_collision_normal()

`ray.get_collision_normal()` returns a unit vector perpendicular to the surface at the hit point. This is used for:
- Reflecting laser beams (reflect the ray direction across the normal)
- Aligning decals to surfaces
- Calculating surface angles for physics

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `RayCast2D.target_position` | Ray endpoint in local space |
| `RayCast2D.force_raycast_update()` | Recalculate immediately |
| `RayCast2D.is_colliding()` | True if ray hits something |
| `RayCast2D.get_collision_point()` | Global hit position |
| `RayCast2D.get_collision_normal()` | Surface normal at hit |
| `Node2D.to_local(global_pos)` | Convert global to local coordinates |
| `get_global_mouse_position()` | Mouse position in world space |
| `Line2D.set_point_position(idx, pos)` | Move a specific line vertex |

## Files

| File | What it holds |
|------|---------------|
| `scripts/ray_demo.gd` | `ray demo` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/ray_demo.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

