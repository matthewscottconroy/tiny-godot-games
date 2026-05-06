# Camera Rooms

A minimal Godot 4.2 demo showing room-based camera transitions using `Area2D`, exported properties, signals, and `Tween`.

## Controls

| Key | Action |
|-----|--------|
| Left / Right (or A / D) | Move |
| Up (or W) | Jump |

Walk right to cross into Room 2, then Room 3. The camera will smoothly pan to each room.

## How It Works

### Room Detection with Area2D

Each room is an `Area2D` node covering a 640×480 region of the world. When the player's `CharacterBody2D` enters the area, the `body_entered` signal fires.

```gdscript
# room.gd
func _ready() -> void:
    body_entered.connect(_on_body)

func _on_body(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_entered.emit(room_name, cam_target)
```

Only bodies in the `"player"` group trigger the transition — enemies or debris that wander across room boundaries are ignored.

### Exported Camera Target

Each room carries its own camera destination as an `@export`:

```gdscript
@export var room_name:  String  = "Room"
@export var cam_target: Vector2 = Vector2.ZERO
```

This means room positions can be adjusted directly in the Godot editor without touching any script. The `cam_target` is set to the room's centre: `(320, 240)`, `(960, 240)`, `(1600, 240)`.

### Signal-Based Wiring

`main.gd` connects to every room's signal in `_ready()` by querying the `"room"` group:

```gdscript
func _ready() -> void:
    for room in get_tree().get_nodes_in_group("room"):
        room.player_entered.connect(_on_room_entered)
```

This is the **event-bus via groups** pattern — `main.gd` doesn't need to know how many rooms exist or their names at edit time.

### Tween Interpolation

When a room signal fires, the camera position is interpolated over 0.5 seconds with an ease-in-out curve:

```gdscript
func _on_room_entered(name: String, target: Vector2) -> void:
    var tw := create_tween()
    tw.tween_property(_cam, "position", target, 0.5).set_ease(Tween.EASE_IN_OUT)
    _label.text = "Room: " + name
```

`create_tween()` returns a one-shot `Tween` that is automatically freed when it finishes. If the player re-enters a room before the tween completes, a new tween is created and the old one is orphaned — for a small demo this is fine. A production game would call `tw.kill()` on the previous tween first.

### World Layout

The world is 1920 px wide (three 640 px rooms side by side). The single floor `StaticBody2D` spans the full width. Room `Area2D` nodes are placed at room centres so they tile seamlessly with no gaps or overlaps.

```
|<-------- Room1 (0–640) ------->|<-------- Room2 (640–1280) ------->|<-------- Room3 (1280–1920) ------->|
         cam_target=(320,240)              cam_target=(960,240)               cam_target=(1600,240)
```

## Key APIs

| API | Purpose |
|-----|---------|
| `Area2D.body_entered` | Fires when a `PhysicsBody2D` enters the area |
| `is_in_group("player")` | Filter: only the player triggers camera changes |
| `create_tween()` | Create a one-shot scene-tree tween |
| `tween_property(obj, prop, target, dur)` | Animate a property from its current value to `target` |
| `set_ease(Tween.EASE_IN_OUT)` | Smooth acceleration/deceleration curve |
| `get_tree().get_nodes_in_group("room")` | Collect all room nodes without hard references |

## Project Structure

```
camera-rooms/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn        # 1920-wide world with 3 rooms, Camera2D, HUD
├── scripts/
│   ├── main.gd          # Signal wiring, tween logic, _draw() for geometry
│   ├── player.gd        # Simple platformer CharacterBody2D
│   └── room.gd          # Area2D with @export cam_target and player_entered signal
├── tests/
│   ├── test.tscn        # Run this scene to execute tests
│   └── test_logic.gd    # Pure-GDScript unit tests
└── README.md
```
