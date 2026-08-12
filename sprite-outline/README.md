# Sprite Outline

Implements hover and selection outlines on clickable shapes using procedural `_draw()` calls — no sprites, no shaders, no textures required.

## Purpose

Outline highlighting is one of the most common UI/game-world feedback mechanisms. It signals "this object is interactive," "this unit is selected," or "this enemy is targeted." Most implementations reach for shaders or imported art, but for prototype work — and for understanding the underlying technique — pure `_draw()` outlines are fast, flexible, and need zero assets. This demo shows a two-state system (hover + selected) that transfers directly to any convex shape: circles, rectangles, polygons.

Games that use this pattern include virtually every RTS (unit selection rings), action RPGs (target lock circles), and puzzle games (interactive object glows). Understanding how to draw concentric rings at a controlled offset from a shape boundary is the building block for all of them.

## How It Works

### Node Tree

```
Main (Node2D)    ← main.gd
```

All geometry is drawn procedurally in `_draw()`. Six colored circles are defined in `_shapes` as dictionaries containing `pos`, `radius`, `color`, `selected`, and `hovered` fields.

### Hit Detection (`scripts/main.gd`)

```gdscript
var dist: float = mouse_pos.distance_to(shape["pos"])
if dist <= shape["radius"] and dist < nearest_dist:
    nearest = i
    nearest_dist = dist
```

On every `InputEventMouseMotion`, the nearest circle whose radius contains the cursor is stored as `_hovered`. Left-click toggles `_selected`. Because the hover check always picks the nearest circle, overlapping circles handle correctly — the frontmost (smallest distance) wins.

### Outline Drawing

```gdscript
if is_selected:
    draw_arc(pos, r + 8.0, 0.0, TAU, 64, Color(1.0, 0.9, 0.0, 1.0), 4.0)
    draw_arc(pos, r + 4.0, 0.0, TAU, 64, Color(1.0, 0.9, 0.0, 0.5), 2.0)
elif is_hovered:
    draw_arc(pos, r + 6.0, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.5), 3.0)
```

The outline is drawn **before** the filled circle so the fill sits on top — this hides the inner half of the arc, giving the appearance of a true ring outline rather than a concentric circle. A second inner arc at lower alpha creates a double-ring glow on selected shapes.

Each circle also gets a subtle inner rim at `r - 2.0` with 30% white alpha, giving every shape a consistent beveled edge regardless of state.

## Concentric Arc Outline Technique

The technique works because `draw_arc` at radius `r + offset` with line width `w` draws a ring that visually appears to hug the outside of the filled shape at radius `r`. The rule of thumb:

```
outer_ring_radius = shape_radius + (ring_width / 2) + gap
```

For a gap-less flush outline, set `ring_radius = shape_radius + ring_width / 2`. For a floating glow ring, add a gap of 2–4 pixels.

Two concentric arcs at different radii and opacities simulate the double-ring "selection" aesthetic common in RTS games. The outer ring is fully opaque; the inner ring is semi-transparent, creating depth.

For non-circular shapes, replace `draw_arc` with `draw_polyline` using an expanded polygon. The principle is identical — draw the outline shape at a slightly enlarged scale centered on the same origin.

## How to Adapt This in Your Project

- **Sprite-based shapes**: Attach a `_draw()` override to the sprite's parent Node2D. Compute the outline position from the sprite's `texture.get_size() * scale * 0.5` and offset from `global_position`.
- **Selection manager**: Store a reference to the currently selected node in an autoload. In each selectable node's `_draw()`, query the autoload to decide which state to render.
- **Animated outline**: Vary the arc radius or alpha using `sin(Time.get_ticks_msec() * 0.003)` for a pulsing selection ring.
- **Partial arc**: Pass a start angle and end angle other than `0` and `TAU` for arc-of-circle indicators (health bars, cooldown rings).
- **Pitfall**: `queue_redraw()` must be called whenever the visual state changes. Forgetting it means the outline never updates.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `draw_arc(pos, radius, start, end, pts, color, width)` | Ring outline at given radius |
| `draw_circle(pos, radius, color)` | Filled circle |
| `draw_string(font, pos, text, ...)` | Procedural HUD text |
| `queue_redraw()` | Trigger `_draw()` on next frame |
| `InputEventMouseMotion` | Per-frame cursor position |
| `InputEventMouseButton` | Click events with button index |
| `ThemeDB.fallback_font` | Built-in font with no import needed |

## Controls

| Input | Action |
|-------|--------|
| Mouse move | Highlight nearest shape under cursor |
| Left click | Select / deselect a shape |
| Escape | Clear current selection |

## Key Constants

```gdscript
# Outline offsets (pixels beyond shape radius)
HOVER_RING_OFFSET    = 6.0   # single white ring
SELECTED_OUTER_OFFSET = 8.0  # bright yellow outer ring
SELECTED_INNER_OFFSET = 4.0  # dim yellow inner ring

# Arc resolution (higher = smoother)
ARC_POINTS = 64
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Shape data, input handling, hit detection, all drawing |
| `scenes/main.tscn` | Minimal scene: single Node2D with main.gd attached |
| `tests/test.tscn` | Unit tests for hit detection and state transitions |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

