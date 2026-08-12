# Drag and Drop

Implements mouse-driven drag-and-drop with snap-back animation when dropped outside a valid target zone.

## Purpose

Drag-and-drop is a common interaction pattern in inventory systems, puzzle games, card games, and UI builders. This demo covers the full lifecycle: detecting a click on a draggable item, tracking mouse position during drag, detecting valid drop targets via overlap, snapping the item into the target, and animating the item back to its origin when dropped on empty space.

## Controls

- **Click and drag** any colored square to move it
- **Release** over a grey drop slot to snap it in
- **Release** elsewhere to bounce the item back to its start position

## How It Works

### Node Tree

```
Main (Node2D)             ← main.gd  (assigns colors, tracks fill count)
├── Zones (Node2D)
│   ├── Zone1 (Area2D)   ← drop_zone.gd  (×3)
│   └── ...
├── Items (Node2D)
│   ├── Item1 (Area2D)   ← draggable.gd  (×3, colored squares)
│   └── ...
└── StatusLabel (Label)
```

Both draggables and drop zones are `Area2D` nodes — this enables overlap detection using `get_overlapping_areas()`.

### `scripts/draggable.gd`

**Setup:**
```gdscript
func _ready() -> void:
    start_pos = position
    input_event.connect(_on_input)
    monitoring = true
```

`input_event` is a signal on `Area2D` that fires when a mouse event occurs within the area's collision shape. This is the recommended way to detect clicks on specific in-game objects (rather than checking mouse position globally in `_input()`).

**Click detection:**
```gdscript
func _on_input(_viewport, event: InputEvent, _shape: int) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            dragging = true
            drag_offset = position - get_global_mouse_position()
```

`drag_offset` captures the vector from the mouse to the item's center. This keeps the item anchored to where you clicked it, rather than jumping its center to the cursor.

**During drag (`_process`):**
```gdscript
position = get_global_mouse_position() + drag_offset
```

**On release — `_try_drop()`:**
```gdscript
for area in get_overlapping_areas():
    if area.is_in_group("drop_zones"):
        area.accept_drop(self)
        return
# No zone found — snap back
var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
tween.tween_property(self, "position", start_pos, 0.35)
```

`get_overlapping_areas()` returns all areas currently overlapping this draggable. If any is a drop zone (checked via group membership), it calls `accept_drop()`. Otherwise a tween animates the item back to `start_pos` with `TRANS_BACK` (overshoot).

### `scripts/drop_zone.gd`

```gdscript
func accept_drop(item: Node2D) -> void:
    item.position  = position
    item.start_pos = position
    has_item = true
    queue_redraw()
    get_parent().on_drop()
```

When an item is accepted, its `position` and `start_pos` are updated to the zone's center. Updating `start_pos` ensures that if the item is picked up and dropped on empty space later, it snaps back to the zone rather than its original position.

### `scripts/main.gd`

Assigns colors to items at startup and counts filled zones in `on_drop()`.

## Design Theory

### Area2D.input_event vs _input()

`_input()` receives all mouse events and requires you to test whether the mouse is within the item's bounds. `Area2D.input_event` only fires when the mouse event occurs inside the collision shape — the physics server does the hit-test. This is cleaner, more accurate (handles rotated/scaled shapes), and cheaper for many objects.

### drag_offset Anchoring

Without `drag_offset`, clicking anywhere on the item would jump the center to the cursor — jarring for the player. Storing the mouse-to-center offset and applying it each frame keeps the click point fixed relative to the item throughout the drag.

### get_overlapping_areas() for Drop Detection

The alternative is to check distance to each zone's position every frame. `get_overlapping_areas()` uses the physics engine's broad-phase and narrow-phase detection, which handles any shape and is already computed by the engine. It also naturally handles multiple overlapping zones by returning all of them.

### TRANS_BACK for Snap-Back

```gdscript
create_tween().set_trans(Tween.TRANS_BACK)
```

`TRANS_BACK` produces an **overshoot**: the item moves past its target briefly before settling. This gives the snap-back a physical, springy feel — as if the item is elastically returning to its slot. Compared to `TRANS_LINEAR`, which feels mechanical, or `TRANS_BOUNCE`, which oscillates, `TRANS_BACK` with `EASE_OUT` is a good default for playful UI.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Area2D.input_event` | Mouse event within the area's collision shape |
| `Area2D.get_overlapping_areas()` | All Area2D nodes currently overlapping |
| `Area2D.monitoring` | Must be true to detect overlaps |
| `Node.is_in_group(name)` | Check group membership |
| `get_global_mouse_position()` | Mouse in world coordinates |
| `Tween.TRANS_BACK` | Overshoot easing for springy feel |
| `Tween.EASE_OUT` | Fast start, slow finish |

## Files

| File | What it holds |
|------|---------------|
| `scripts/draggable.gd` | `draggable` behaviour |
| `scripts/drop_zone.gd` | `drop zone` behaviour |
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/draggable.gd`, `scripts/drop_zone.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/drop_zone.gd`**
- `accept_drop(item: Node2D) -> void`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

