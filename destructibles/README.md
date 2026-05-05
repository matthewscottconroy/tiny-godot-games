# Destructibles

Click a box to break it. Each box shatters into `RigidBody2D` fragments with `Polygon2D` visuals, scattered outward with random velocities. Multi-hit boxes show crack lines before breaking.

## Purpose

Destructible objects are common in action games — crates, barrels, breakable walls. The Godot approach is: remove the original static body, spawn a set of physics fragments with outward impulses. This demo shows the complete pattern including visual feedback (flash + cracks), fragment spawning with `Polygon2D` visuals, and collision shapes created in code.

## Controls

- **Click any box** to deal a hit
- Boxes with `hp > 1` show crack lines before shattering
- Fragments fall and tumble with gravity

## How It Works

### `scripts/destructible.gd`

**Click detection via `input_event`:**
```gdscript
func _ready() -> void:
    input_pickable = true            # must enable for Area2D to receive clicks
    input_event.connect(_on_click)
```

**Shattering:**
```gdscript
func _shatter() -> void:
    _destroyed = true
    for i in frag_count:
        var frag := RigidBody2D.new()

        # Polygon2D visual (works as child of RigidBody2D)
        var poly := Polygon2D.new()
        poly.polygon = PackedVector2Array([...])
        poly.color = box_color.darkened(rng.randf_range(0, 0.35))
        frag.add_child(poly)

        # Collision shape created in code
        var cshape := CollisionShape2D.new()
        var rect   := RectangleShape2D.new()
        rect.size  = frag_size
        cshape.shape = rect
        frag.add_child(cshape)

        get_parent().add_child(frag)

        # Outward impulse
        var angle := TAU * i / frag_count + rng.randf_range(-0.4, 0.4)
        frag.linear_velocity = Vector2(cos(angle), sin(angle)) * frag_speed * rng.randf_range(0.5, 1.5)
        frag.angular_velocity = rng.randf_range(-8.0, 8.0)

    queue_free()
```

**Why `Polygon2D` instead of `ColorRect`?**
`ColorRect` is a `Control` node — it uses an anchor/offset layout system that doesn't compose correctly inside `Node2D`-based physics bodies. `Polygon2D` is a proper `Node2D` subclass and renders correctly as a child of `RigidBody2D`.

**Even spread:**
```
angle = TAU × (i / frag_count)
```
Distributing angles evenly across `TAU` (a full circle) ensures fragments fly in all directions. Adding `randf_range(-0.4, 0.4)` jitters the angle so the spread looks organic.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Area2D.input_pickable` | Enable click detection on Area2D |
| `RigidBody2D` | Physics body that responds to gravity and impulses |
| `RigidBody2D.linear_velocity` | Set initial velocity (acts as an impulse at spawn) |
| `RigidBody2D.angular_velocity` | Initial spin |
| `Polygon2D` | Renders a filled polygon — composable in Node2D hierarchies |
| `Node.queue_free()` | Schedule safe removal at end of frame |
