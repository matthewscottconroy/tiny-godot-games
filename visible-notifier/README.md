# Visible Notifier

Demonstrates `VisibleOnScreenNotifier2D` — a node that emits signals when an object enters or exits the camera's visible area, enabling CPU-side culling without polling.

## Purpose

When a scene has hundreds of objects, processing all of them every frame is wasteful. `VisibleOnScreenNotifier2D` solves this with zero polling: it integrates with Godot's renderer to emit `screen_entered` and `screen_exited` signals exactly when visibility changes. This is the correct pattern for enemy AI activation, particle systems, and any object that should pause when off-screen.

## Controls

- **Arrow keys / WASD**: Pan the camera across the world grid
- Watch the counter: only objects inside the viewport are marked "active" and update

## How It Works

### Node Tree

```
Main (Node2D)              ← main.gd
├── Camera2D
├── Objects (Node2D)       ← 96 object nodes added here
│   └── [Node2D ×96]
│       └── VisibleOnScreenNotifier2D
└── HUD (CanvasLayer)
    ├── CountLabel
    └── HintLabel
```

### `scripts/main.gd`

- **`_ready()`** — Creates a 12×8 grid (96 objects) spread across a large world. Each object gets a `VisibleOnScreenNotifier2D` with a bounding rect matching the object's visual size. `screen_entered` connects to `set_meta("active", true)`, `screen_exited` to `set_meta("active", false)`.
- **`_process(delta)`** — Iterates all objects, but only runs logic (rotation update) for those where `get_meta("active")` is `true`. Also calls `_refresh_count()` to update the label.
- **`_draw()`** — Draws each object as a colored hexagon. Objects with `active=true` render brightly; others are dimmed.

### The Culling Pattern

```gdscript
for obj in $Objects.get_children():
    if obj.get_meta("active", false):
        obj.rotate(delta * 1.2)
        obj.queue_redraw()
```

This scales to hundreds of objects because the hot path (the `if` branch) only executes for the ~20-30 objects currently on screen. The off-screen objects still exist in the scene tree but do no work.

### VisibleOnScreenNotifier2D.rect

The `rect` property defines the bounding box in the notifier's local space that the screen-visibility check uses. It must be sized to match the visual footprint of the object. If the rect is too small, the object may appear on screen before the signal fires.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `VisibleOnScreenNotifier2D` | Emits signals on screen enter/exit |
| `.screen_entered` | Signal — fired when rect enters viewport |
| `.screen_exited` | Signal — fired when rect exits viewport |
| `VisibleOnScreenNotifier2D.rect` | Bounding rect for visibility testing |
| `node.set_meta(key, val)` | Per-node boolean flag (no subclass needed) |
| `node.get_meta(key, default)` | Read flag with a fallback default |
