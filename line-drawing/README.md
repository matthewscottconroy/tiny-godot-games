# Line Drawing

Freehand stroke drawing using `Line2D` nodes — demonstrates how to capture mouse drag events and render smooth multi-point lines with configurable width and color.

## Purpose

Understanding how to capture continuous mouse position data and render it as geometry is foundational for paint tools, signature capture, map drawing, and many puzzle mechanics. This demo shows how to build a complete stroke system: starting, extending, committing, and undoing strokes.

## Controls

- **Left-click drag**: Draw a stroke
- **Right-click**: Undo last stroke
- **C key**: Clear all strokes
- **Thin / Med / Thick buttons**: Set line width
- **Red / Blue / Green buttons**: Set line color

## How It Works

### Node Tree

```
Main (Node2D)       ← main.gd
└── HUD (CanvasLayer)
    └── ButtonRow (HBoxContainer)
        └── [Clear, Thin, Med, Thick, Red, Blue, Green buttons]
```

### `scripts/main.gd`

Strokes are stored as an Array of dictionaries, each with:
```gdscript
{ "points": PackedVector2Array, "color": Color, "width": float }
```

- **Mouse press** — Creates a new `_current` stroke with the clicked position.
- **Mouse drag** — Appends the current mouse position to `_current.points` and calls `queue_redraw()`.
- **Mouse release** — If the stroke has at least 2 points, appends it to `_strokes`.
- **`_draw()`** — Iterates `_strokes` and draws each as a series of connected `draw_line()` calls. A dark background rectangle is drawn first.

### Why Not Use Line2D Nodes?

This demo uses `_draw()` directly rather than instantiating `Line2D` scene nodes. This is simpler for dynamically created geometry and avoids the overhead of managing a scene tree of nodes. For production tools where you need caps, joints, or texture support, `Line2D` is the right choice.

## Stroke Representation

`PackedVector2Array` is a typed array stored as a contiguous memory block — much faster to iterate and less memory than `Array[Vector2]`. Since drawing calls every frame with potentially thousands of points, this matters.

## Minimum Point Threshold

A stroke is only committed to `_strokes` if it has `>= 2` points. A single click (no drag) produces only one point, which cannot form a line segment. Discarding it prevents empty strokes that would waste memory.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `InputEventMouseButton` | Detects press/release and which button |
| `InputEventMouseMotion.position` | Current cursor position during drag |
| `PackedVector2Array` | Compact array for stroke point storage |
| `CanvasItem.draw_line(from, to, color, width)` | Draw a line segment in `_draw()` |
| `CanvasItem.queue_redraw()` | Mark the node for redraw next frame |
