# Trail Effect

A `Line2D` gradient trail that follows a moving object. The newest position is inserted at the front; the oldest is removed when the trail exceeds its maximum length. Demonstrates `Line2D` with a `Gradient` for a fade effect.

## Purpose

Motion trails add visual personality to fast-moving objects — bullets, players dashing, projectiles. The technique is simpler than it looks: `Line2D` accepts an array of points, and a `Gradient` colors them from transparent at the tail to opaque at the head. Each frame, insert the current position at index 0, then trim the tail.

## Controls

- **Arrow keys / WASD**: Move, Up / W to jump
- **+ longer trail / - shorter trail**: Adjust the maximum trail length

## How It Works

### `scripts/main.gd`

**Inserting at the front:**
```gdscript
func _update_trail() -> void:
    _trail.add_point(_pos, 0)          # second arg = insert index (0 = front)
    while _trail.get_point_count() > _trail_len:
        _trail.remove_point(_trail.get_point_count() - 1)  # remove last
```
`Line2D.add_point(pos, idx)` inserts at the given index. Index 0 is the line's start — the head. Removing from the back trims the tail. The trail is always the most recent `_trail_len` positions.

**Gradient fade:**
```gdscript
var grad := Gradient.new()
grad.set_color(0, Color(1.0, 0.85, 0.1, 0.0))   # offset 0 = line start = tail → transparent
grad.set_color(1, Color(1.0, 0.85, 0.1, 1.0))   # offset 1 = line end  = head → opaque
_trail.gradient = grad
```

Wait — Line2D renders from index 0 to the last index. We insert new points at index 0 (front of array). So index 0 = newest = head of the visible trail. But the Gradient's offset 0 maps to the line's start (index 0). So to make the head opaque and the tail transparent, the gradient goes `transparent → opaque` from offset 0 to 1.

**Extending the tail further:**

To get a longer fade, use a curve on `Line2D.width_curve` to taper the width from head to tail. Combined with the opacity gradient, this gives a comet-like appearance.

### Physics note

This demo implements simple kinematic movement directly (no `CharacterBody2D`) to keep the focus on the trail. The platform collisions are visual only — they don't block the player, making the demo playspace freeform for trail exploration.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Line2D.add_point(pos, idx)` | Insert a point at `idx` (0 = front of line) |
| `Line2D.remove_point(idx)` | Remove point at `idx` |
| `Line2D.get_point_count()` | Current number of points |
| `Line2D.gradient` | `Gradient` resource controlling color along the line |
| `Gradient.set_color(offset_idx, color)` | Set color at a gradient stop |
