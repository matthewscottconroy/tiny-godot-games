# Line Drawing

<!-- tags: none -->

Freehand stroke drawing using Godot's immediate-mode `_draw()` API — captures mouse drag events, stores strokes as `PackedVector2Array` point lists, and renders them each frame with configurable width and color.

## Purpose

The ability to capture and render continuous input as geometry is foundational for a surprising range of game features: drawing puzzles (where the player traces shapes), map annotation in strategy games, signature capture for UI verification, paint minigames, and custom gesture recognition. Understanding the stroke lifecycle — press to start, drag to extend, release to commit, undo to remove — is the building block for all of these.

This demo deliberately uses `_draw()` rather than `Line2D` nodes. The `_draw()` approach keeps all strokes in a plain data array (no scene tree nodes), making the full stroke history trivially serializable for save/load and efficient for batch rendering. When strokes are data rather than nodes, features like export-to-PNG, stroke simplification, and path-following animations are all straightforward to add.

A secondary lesson here is `PackedVector2Array`: Godot's compact typed array that stores `Vector2` values in contiguous memory rather than in GDScript's generic `Array` heap. For draw calls that happen every frame across potentially thousands of points, this memory layout matters.

## How It Works

### Node Tree

```
Main (Node2D)       ← main.gd
└── Buttons (HBoxContainer)
    └── [Clear, Thin, Med, Thick, Red, Blue, Green buttons]
```

### Stroke Data Structure

Each committed stroke is a dictionary:

```gdscript
{
    "points": PackedVector2Array,  # ordered screen positions
    "color":  Color,               # color at time of drawing
    "width":  float                # line width at time of drawing
}
```

The active stroke (`_current`) uses the same structure, built up during the drag and appended to `_strokes` on mouse release.

### Input Handling

```gdscript
if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _drawing = true
            _current = {points = PackedVector2Array(), color = _color, width = _width}
            _current.points.append(event.position)
        else:
            if _drawing and _current.points.size() > 1:
                _strokes.append(_current)   # commit only if 2+ points
            _drawing = false
            _current = {}
            queue_redraw()
    elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        if not _strokes.is_empty():
            _strokes.pop_back()             # undo last stroke
            queue_redraw()

if event is InputEventMouseMotion and _drawing:
    _current.points.append(event.position)  # extend active stroke
    queue_redraw()
```

The minimum 2-point threshold prevents single-click artifacts: a click with no drag produces one point, which can't form a line segment.

### Rendering

`_draw()` iterates all committed strokes and the in-progress stroke, drawing each as a sequence of line segments:

```gdscript
func _draw() -> void:
    draw_rect(Rect2(0, 62, 640, 370), Color(0.08, 0.08, 0.1))  # canvas background
    for s in _strokes:
        if s.points.size() > 1:
            for i in s.points.size() - 1:
                draw_line(s.points[i], s.points[i + 1], s.color, s.width, true)
    if _drawing and _current.has("points") and _current.points.size() > 1:
        var pts: PackedVector2Array = _current.points
        for i in pts.size() - 1:
            draw_line(pts[i], pts[i + 1], _current.color, _current.width, true)
```

The fifth argument to `draw_line` (`true`) enables antialiasing on the line segment — this smooths diagonal edges at the cost of a small performance overhead.

## Stroke Rendering: _draw() vs Line2D Nodes

| Approach | Pros | Cons |
|----------|------|------|
| `_draw()` + data array | No scene tree overhead, data is serializable, trivial undo/redo | Must redraw all strokes every frame |
| `Line2D` nodes per stroke | Supports texture fills, joint styles, caps | Scene tree grows with stroke count; harder to serialize |

For real paint tools, `_draw()` is usually the right choice up to a few hundred strokes. If stroke counts grow very large, consider rasterizing completed strokes to a `RenderingServer` canvas item or `Image` to avoid re-drawing old strokes every frame.

## PackedVector2Array vs Array[Vector2]

`PackedVector2Array` stores floats in a contiguous C++ memory block. Iteration and draw calls access it with no boxing overhead. `Array[Vector2]` stores GDScript `Variant` objects on the heap, which are individually heap-allocated. For a stroke with 500 sampled points processed 60 times per second, the difference is measurable. GDScript's `draw_line` call also accepts `PackedVector2Array` parameters in bulk APIs like `draw_polyline` — useful when upgrading this demo to handle very long strokes.

## How to Adapt This in Your Project

- **Stroke simplification**: apply the Ramer-Douglas-Peucker algorithm before committing a stroke to `_strokes` — removes redundant collinear points without visible quality loss, reducing memory and draw cost.
- **Path following**: a committed `PackedVector2Array` is already a path. Pass it to a `PathFollow2D`-style script to animate objects along drawn paths.
- **Gesture recognition**: compare a normalized stroke against template shapes (circle, triangle, line) with point-to-point distance sums to detect player gestures.
- **Save/load**: `PackedVector2Array` serializes directly via `var_to_bytes()` / `bytes_to_var()`, making stroke persistence straightforward.
- **Canvas texture**: use a `SubViewport` rendering only the drawing node, then read back `get_texture()` to export strokes as images or use them as procedural textures.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `InputEventMouseButton` | Detects press/release and which button |
| `InputEventMouseButton.position` | Cursor position at the click |
| `InputEventMouseMotion.position` | Cursor position during drag |
| `PackedVector2Array` | Compact, cache-friendly array of Vector2 points |
| `PackedVector2Array.append(v)` | Add a point to the end |
| `PackedVector2Array.pop_back()` | Remove the last point |
| `CanvasItem.draw_line(from, to, color, width, antialias)` | Draw one line segment |
| `CanvasItem.draw_rect(rect, color)` | Draw a filled rectangle (used for canvas background) |
| `CanvasItem.queue_redraw()` | Schedule a `_draw()` call for next frame |

## Controls

| Input | Action |
|-------|--------|
| **Left-click drag** | Draw a stroke |
| **Right-click** | Undo last stroke |
| **C key** | Clear all strokes |
| **Thin / Med / Thick buttons** | Set line width (1.5 / 3.0 / 7.0 px) |
| **Red / Blue / Green buttons** | Set stroke color |

## Key Constants

```gdscript
var _color := Color.WHITE   # default stroke color
var _width := 3.0           # default stroke width in pixels

# canvas area
Rect2(0, 62, 640, 370)      # drawable region below the button bar
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | All input handling, stroke storage, and `_draw()` rendering |
| `scenes/main.tscn` | Root Node2D with button bar |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [parallax-scroll](../parallax-scroll) — Multiple background layers scrolling at different speeds for depth.
- [polygon-clip](../polygon-clip) — An interactive `Polygon2D` vertex editor with convex hull via `Geometry2D`.
- [scene-transition](../scene-transition) — Fade-to-black scene changes via a persistent Autoload `CanvasLayer`.
- [thread-loading](../thread-loading) — `load_threaded_request()` background loading with a progress UI.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

