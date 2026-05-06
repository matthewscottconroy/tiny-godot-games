# Destructibles

Click a box to break it. Each box shatters into `RigidBody2D` fragments with `Polygon2D` visuals, scattered outward with random velocities. Multi-hit boxes show crack lines before breaking.

## Purpose

Destructible objects are common in action games — crates, barrels, breakable walls, glass panes. The pattern serves both gameplay (resource drops, path clearing) and feel (satisfying tactile feedback). When something breaks, the visual must communicate the break instantly: the original object disappears, multiple physics fragments scatter, and smaller pieces give the impression of mass and material.

Games like Dead Cells, Spelunky, and most action roguelikes use this exact technique: replace a static body with multiple RigidBody2D fragments on death. The same approach works for 3D games using `RigidBody3D`. The implementation detail that matters most is outward impulse direction — fragments need to fly radially outward from the break point, not randomly in arbitrary directions.

This demo also demonstrates multi-hit feedback with flash and crack visuals, dynamic node creation in code (no pre-made fragment scenes), and the `Area2D.input_pickable` pattern for click detection on physics objects.

## How It Works

### Click Detection

```gdscript
func _ready() -> void:
    input_pickable = true
    input_event.connect(_on_click)

func _on_click(_vp: Viewport, event: InputEvent, _idx: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if _destroyed:
            return
        _hits       += 1
        _flash_timer = 0.12
        queue_redraw()
        if _hits >= hp:
            _shatter()
```

`input_pickable = true` must be set for an `Area2D` to receive input events. Without it, clicks pass through. `_destroyed` guards against double-hit processing in the frame the box is freed.

### Visual Feedback Before Breaking

```gdscript
func _draw() -> void:
    var flash := clampf(_flash_timer * 6.0, 0.0, 1.0)
    var col   := box_color.lerp(Color.WHITE, flash)
    draw_rect(Rect2(-box_size * 0.5, box_size), col)
    if _hits >= 1 and hp > 1:
        var half := box_size * 0.5
        draw_line(Vector2(-half.x * 0.3, -half.y), Vector2(half.x * 0.1, 0), Color(0, 0, 0, 0.5), 2.0)
        draw_line(Vector2(half.x * 0.2,  0),       Vector2(-half.x * 0.1, half.y * 0.8), Color(0, 0, 0, 0.5), 2.0)
```

`_flash_timer` decays in `_process`, and `clampf(_flash_timer * 6.0, 0, 1)` converts the 0.12 s timer into a 0→1 flash intensity that fades in one frame. Crack lines appear only after the first hit on a multi-HP box, telegraphing the weakened state.

### Fragment Spawning

```gdscript
func _shatter() -> void:
    _destroyed = true
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    for i in frag_count:
        var frag := RigidBody2D.new()
        frag.gravity_scale = 1.2
        frag.angular_damp  = 0.5

        var frag_size := Vector2(rng.randf_range(6, 14), rng.randf_range(6, 14))

        var poly := Polygon2D.new()
        poly.polygon = PackedVector2Array([...])   # trapezoid shape
        poly.color = box_color.darkened(rng.randf_range(0.0, 0.35))
        frag.add_child(poly)

        var cshape := CollisionShape2D.new()
        var rect   := RectangleShape2D.new()
        rect.size  = frag_size
        cshape.shape = rect
        frag.add_child(cshape)

        frag.position = global_position + Vector2(
            rng.randf_range(-box_size.x * 0.4, box_size.x * 0.4),
            rng.randf_range(-box_size.y * 0.4, box_size.y * 0.4)
        )
        get_parent().add_child(frag)

        var angle := TAU * i / frag_count + rng.randf_range(-0.4, 0.4)
        frag.linear_velocity = Vector2(
            cos(angle) * frag_speed * rng.randf_range(0.5, 1.5),
            sin(angle) * frag_speed * rng.randf_range(0.5, 1.5) - 80.0
        )
        frag.angular_velocity = rng.randf_range(-8.0, 8.0)

    queue_free()
```

Fragments are full `RigidBody2D` nodes constructed at runtime — no pre-built scenes needed. `get_parent().add_child(frag)` adds them to the scene at the same level as the box. `queue_free()` schedules the box for safe removal at the end of the frame.

### Radial Spread

```
angle = TAU × (i / frag_count) + jitter
```

Dividing a full circle (`TAU`) evenly by `frag_count` distributes fragments radially. Adding `randf_range(-0.4, 0.4)` jitters each angle so the spread looks organic rather than mechanical. The `-80.0` upward bias on Y velocity gives fragments a slight upward pop before gravity pulls them down.

### Why Polygon2D Instead of ColorRect

`ColorRect` is a `Control` node — it uses an anchor/offset layout system designed for UI, not for `Node2D`-based physics hierarchies. Parenting a Control to a RigidBody2D produces incorrect positioning. `Polygon2D` is a proper `Node2D` subclass and composes correctly inside any `Node2D` scene tree.

## How to Adapt This in Your Project

- **Pre-built fragment scenes**: Instantiate a `.tscn` file per fragment instead of constructing nodes in code — `frag = preload("res://scenes/fragment.tscn").instantiate()`. This lets you add particle effects and sounds per fragment.
- **Drop loot on death**: After the `_shatter()` loop, spawn a coin or item at `global_position`. The same `get_parent().add_child(item)` pattern works.
- **Health-based break thresholds**: Change `hp` export to a float and damage per click to `damage_amount`. Set cracks at `_hp < hp * 0.5` instead of `_hits >= 1`.
- **Auto-cleanup**: Connect a `Timer` in each fragment to `queue_free()` after 3–5 seconds so fragments don't accumulate forever.
- **Sound on break**: Add `AudioStreamPlayer.play()` inside `_shatter()` before `queue_free()`. Use `call_deferred` if the player is a child of the node being freed.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Area2D.input_pickable` | Enable mouse/touch input events on the Area2D |
| `Area2D.input_event` | Signal fired on mouse click or touch |
| `RigidBody2D` | Physics body that responds to gravity and impulses |
| `RigidBody2D.linear_velocity` | Set initial velocity (instant impulse at spawn) |
| `RigidBody2D.angular_velocity` | Initial spin rate in radians/second |
| `RigidBody2D.gravity_scale` | Multiplier on world gravity |
| `Polygon2D` | Filled polygon Node2D — composable in physics hierarchies |
| `RectangleShape2D` | Collision shape for box-shaped fragments |
| `Node.queue_free()` | Schedule safe removal at end of frame |
| `Node.get_parent().add_child(node)` | Add runtime-created node to the scene |

## Key Constants

```gdscript
# Exported per-box in the scene (destructible.gd):
@export var box_color  := Color.PERU
@export var box_size   := Vector2(48, 48)
@export var frag_count := 8       # number of fragments on shatter
@export var frag_speed := 200.0   # pixels/second outward impulse
@export var hp         := 2       # clicks to destroy
```

## Files

| File | Purpose |
|------|---------|
| `scripts/destructible.gd` | Click detection, flash/crack visuals, fragment spawning |
| `scenes/main.tscn` | Scene with multiple Destructible instances, each with different hp/color exports |
