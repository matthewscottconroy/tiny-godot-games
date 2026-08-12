# Visible Notifier

Demonstrates `VisibleOnScreenNotifier2D` — a node that fires `screen_entered` and `screen_exited` signals when an object crosses the camera boundary, enabling signal-driven CPU culling with zero per-frame polling.

## Purpose

A scene with hundreds of independent objects (enemies, coins, particles, debris) that all tick every frame wastes CPU time on objects the player cannot see or interact with. Naively disabling them requires checking positions against camera bounds yourself, which is polling — you pay for the check every frame regardless of whether visibility changed.

`VisibleOnScreenNotifier2D` inverts the model: Godot's renderer already tracks what is on screen. The notifier hooks into that information and emits a signal exactly once, when the status changes. Your code reacts to the event; it does not poll. This scales correctly to any object count and any camera movement speed.

Real games use this pattern for enemy AI activation (*Hollow Knight*'s entire world exists simultaneously but only simulates nearby rooms), projectile pools, ambient particle effects, and distant NPC routines. The pattern is also the foundation for object pooling — spawn objects when they enter, reclaim them when they exit.

This demo creates a 12×8 grid of 96 colored objects across a world larger than the viewport. Only objects currently on screen rotate and redraw. Panning the camera makes the effect obvious: the counter updates in real time as objects enter and leave.

## How It Works

### Node Tree

```
Main (Node2D)                     ← main.gd
├── Camera2D
├── Objects (Node2D)
│   └── [Node2D × 96]             ← one per grid cell
│       └── VisibleOnScreenNotifier2D
└── HUD (CanvasLayer)
    ├── CountLabel
    └── HintLabel
```

### Object Creation (`scripts/main.gd`)

```gdscript
func _make_object(pos: Vector2) -> void:
    var obj := Node2D.new()
    obj.position = pos
    obj.set_meta("active", true)
    obj.set_meta("angle", randf() * TAU)
    obj.set_meta("color", Color(randf(), randf(), randf()))

    var notifier := VisibleOnScreenNotifier2D.new()
    notifier.rect = Rect2(-20, -20, 40, 40)
    notifier.screen_entered.connect(func():
        obj.set_meta("active", true)
        _refresh_count())
    notifier.screen_exited.connect(func():
        obj.set_meta("active", false)
        _refresh_count())
    obj.add_child(notifier)
```

Each object carries its state (`active`, `angle`, `color`) as metadata rather than as a subclassed property, so no custom class is needed. The notifier's `rect` is sized to match the visual footprint of the object (a 36×36 circle bounding box).

### Culled Processing (`_process`)

```gdscript
func _process(delta: float) -> void:
    var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    camera.position += dir * 300 * delta

    for obj in objects.get_children():
        if obj.get_meta("active"):
            obj.set_meta("angle", obj.get_meta("angle") + delta * 1.5)
        obj.queue_redraw()
```

All 96 objects are iterated, but the hot path — the angle update — only runs for the ~20 objects currently on screen. `queue_redraw()` is called for all objects so their visual state stays correct when they come back into view, but `draw()` for off-screen nodes is skipped by Godot's renderer automatically.

### Visual State in `_draw` (connected via signal)

```gdscript
obj.draw.connect(func():
    var col: Color = obj.get_meta("color")
    var a: float   = obj.get_meta("angle")
    if obj.get_meta("active"):
        obj.draw_circle(Vector2.ZERO, 18, col)
        obj.draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 18, Color.WHITE, 2)
    else:
        obj.draw_rect(Rect2(-18, -18, 36, 36), col.darkened(0.6))
)
```

Active (on-screen) objects draw a colored circle with a rotating needle. Inactive objects draw a darkened square — a visible indicator that they exist but are paused.

## Culling Pattern Deep-Dive

### Signal-Driven vs Polling

Polling approach (avoid):
```gdscript
func _process(delta):
    for obj in objects:
        var on_screen := camera_rect.has_point(obj.position)
        obj.set_meta("active", on_screen)   # checked every frame, every object
```

Signal-driven approach (this demo):
```gdscript
notifier.screen_entered.connect(func(): obj.set_meta("active", true))
notifier.screen_exited.connect(func():  obj.set_meta("active", false))
```

The signal fires once per visibility change. With 96 objects and 20 on screen, the polling approach runs 96 checks per frame; the signal approach runs 0 checks per frame during steady state (no objects crossing the boundary).

### `VisibleOnScreenNotifier2D.rect`

The `rect` is in the notifier's local space and defines what area counts as "the object" for visibility testing. It must match the visual footprint:
- Too small: the object appears on screen before `screen_entered` fires — a one-frame pop-in.
- Too large: `screen_exited` fires while part of the object is still visible — objects disappear early.

Set `rect` to the bounding box of your sprite or collision shape with a small margin.

### Initial State

Objects start with `set_meta("active", true)`. Objects near the camera center start on screen, so this is correct for them. For objects that start off-screen, `screen_exited` will fire during the first frame if you pan away, but this demo initializes the camera near the top-left corner so most objects are off-screen at start and their initial `active = true` is quickly corrected by the first `screen_exited` signal.

For a robust implementation, initialize all objects with `active = false` and rely entirely on `screen_entered` to activate them.

## How to Adapt This in Your Project

**Enemy AI activation:** Give each enemy a `VisibleOnScreenNotifier2D`. Connect `screen_entered` to `set_process(true)` and `screen_exited` to `set_process(false)`. The enemy's `_process` and `_physics_process` pause automatically when off-screen.

**Particle systems:** Start and stop `GPUParticles2D` with `screen_entered.connect(func(): $Particles.emitting = true)`.

**Larger margin for spawning:** Size the notifier's `rect` larger than the visual so objects activate before they appear — useful for enemies that should be ready when they enter view, not snap to an idle state at the border.

**Object pooling:** Instead of creating/destroying nodes, maintain a pool. Connect `screen_exited` to return the node to the pool and `screen_entered` to check one out.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `VisibleOnScreenNotifier2D` | Emits signals when its rect enters or exits the viewport |
| `.screen_entered` signal | Fires once when the rect crosses into the visible area |
| `.screen_exited` signal | Fires once when the rect fully leaves the visible area |
| `VisibleOnScreenNotifier2D.rect` | Bounding box (local space) used for visibility testing |
| `node.set_meta(key, value)` | Attach arbitrary per-node data without subclassing |
| `node.get_meta(key, default)` | Read per-node data with a fallback for missing keys |
| `Node2D.draw` signal | Emitted when `queue_redraw()` is processed — connect to add custom drawing |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys | Pan camera across the 12×8 object grid |

## Key Constants

```gdscript
const COLS         := 12     # columns in the object grid
const ROWS         := 8      # rows in the object grid
const SPACING      := 80     # pixels between object centers
const OBJECT_COUNT := COLS * ROWS  # 96 total objects
# Camera pan speed: 300 px/s
# Object rotation speed: 1.5 rad/s (active only)
# Notifier rect: Rect2(-20, -20, 40, 40) per object
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Grid creation, notifier wiring, per-frame culled update, camera pan |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

