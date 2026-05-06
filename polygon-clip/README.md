# Polygon Clip

Interactive `Polygon2D` vertex editor — drag vertices, insert points on edges with right-click, delete vertices with middle-click, and compute convex hull via `Geometry2D`. Displays live vertex count and area.

## Purpose

Polygon editing is the foundation of in-game level editors, collision shape authoring UIs, and procedural geometry tools. Games like Baba Is You, LittleBigPlanet, and any title with a built-in level editor need polygon manipulation. The techniques here — vertex hit-testing, closest-point-on-segment for edge insertion, and convex hull computation — are the same algorithms used in professional geometry editors.

This demo also illustrates a subtlety of Godot's `Polygon2D`: its `polygon` property returns a *copy* of the internal `PackedVector2Array`. Modifying the returned copy has no effect; you must assign back. This copy-on-write pattern appears throughout Godot's typed packed arrays and catching it early prevents confusing bugs.

`Geometry2D` is Godot's built-in computational geometry module. It provides exact polygon math (area, convex hull, intersection, offsetting) that would be tedious and error-prone to implement from scratch. Knowing this API exists saves significant effort in real projects.

## How It Works

### Node Tree

```
Main (Node2D)       ← main.gd
├── Polygon2D
├── InfoLabel
└── Buttons (HBoxContainer)
    └── [Convexify, Reset buttons]
```

### Vertex Hit-Testing (`_find_vertex`)

```gdscript
const VERTEX_RADIUS := 10.0

func _find_vertex(pos: Vector2) -> int:
    for i in poly.polygon.size():
        if poly.polygon[i].distance_to(pos) <= VERTEX_RADIUS:
            return i
    return -1
```

Returns the index of the first vertex within 10 pixels of the cursor, or `-1` if none. Used for both drag initiation (left-click) and deletion (middle-click).

### Edge Insertion (`_insert_point`)

```gdscript
const EDGE_HIT_DIST := 14.0

func _insert_point(pos: Vector2) -> void:
    var pts  := poly.polygon
    var n    := pts.size()
    var best_i := -1
    var best_d := 1e9
    for i in n:
        var a := pts[i]
        var b := pts[(i + 1) % n]   # wraps last edge back to vertex 0
        var d := Geometry2D.get_closest_point_to_segment(pos, a, b).distance_to(pos)
        if d < best_d:
            best_d = d
            best_i = i
    if best_i >= 0 and best_d < EDGE_HIT_DIST:
        var new_pts := PackedVector2Array()
        for i in n:
            new_pts.append(pts[i])
            if i == best_i:
                new_pts.append(pos)   # insert after the closest edge's start vertex
        poly.polygon = new_pts
```

`Geometry2D.get_closest_point_to_segment(p, a, b)` returns the nearest point on segment `[a, b]` to point `p`. The distance from that projected point to `p` is the perpendicular distance to the edge — the right metric for "click on an edge."

### Vertex Deletion (`_delete_vertex`)

Minimum 3 vertices are enforced (a polygon with fewer is degenerate):

```gdscript
func _delete_vertex(pos: Vector2) -> void:
    if poly.polygon.size() <= 3:
        return
    var idx := _find_vertex(pos)
    if idx < 0: return
    var pts := poly.polygon
    var new_pts := PackedVector2Array()
    for i in pts.size():
        if i != idx:
            new_pts.append(pts[i])
    poly.polygon = new_pts
```

### Dragging

During drag, the selected vertex index is stored in `_drag_idx`. Every `InputEventMouseMotion` event updates that vertex:

```gdscript
elif event is InputEventMouseMotion and _drag_idx >= 0:
    var pts := poly.polygon
    pts[_drag_idx] = event.position
    poly.polygon = pts          # must reassign to apply the mutation
    queue_redraw()
```

The copy-then-reassign pattern is necessary because `poly.polygon` returns a `PackedVector2Array` copy. Direct index assignment on the returned copy (`poly.polygon[idx] = pos`) would silently do nothing.

### Convexify

```gdscript
func _convexify() -> void:
    poly.polygon = Geometry2D.convex_hull(poly.polygon)
```

`Geometry2D.convex_hull(points)` implements the Quickhull algorithm. It accepts any set of points (including concave or self-intersecting configurations) and returns the minimal convex polygon enclosing all of them. Interior points are discarded — the returned array has fewer or equal vertices. Vertices are in counter-clockwise order.

### Area Display

```gdscript
info.text = "Vertices: %d   |   Area: %.0f px²" % [n, abs(Geometry2D.polygon_area(pts))]
```

`Geometry2D.polygon_area` returns a signed area: positive for counter-clockwise winding, negative for clockwise. `abs()` gives the geometric area regardless of winding order.

## PackedVector2Array Mutation Pattern

This pattern appears whenever you need to modify polygon vertices:

```gdscript
# WRONG: modifying the copy has no effect
poly.polygon[0] = Vector2(100, 200)  # silent no-op

# CORRECT: copy, modify, reassign
var verts := poly.polygon
verts[0] = Vector2(100, 200)
poly.polygon = verts
```

The same pattern applies to `NavigationPolygon`, `CollisionPolygon2D`, and any node that exposes a `PackedVector2Array` property.

## Convex Hull in Game Development

Convex hull has several practical uses beyond this demo:

- **Physics collision shapes**: `ConvexPolygonShape2D` requires convex points — use `convex_hull()` to sanitize user-drawn shapes before assigning them to a `CollisionShape2D`.
- **Quick containment test**: `Geometry2D.is_point_in_polygon(point, convex_hull_pts)` is faster when the polygon is convex.
- **Bounding volume**: a convex hull is tighter than an axis-aligned bounding box, useful for broad-phase collision culling.

## How to Adapt This in Your Project

- **Collision shape editing**: read `CollisionPolygon2D.polygon`, let the user edit, write back. Combine with `convex_hull()` before assigning to `ConvexPolygonShape2D`.
- **Terrain deformation**: store terrain cross-sections as polygons and use `Geometry2D.clip_polygons()` to subtract explosion shapes in real time.
- **Trigger zones**: a polygon-shaped `Area2D` trigger can be edited at runtime with the same vertex manipulation shown here.
- **Level editor**: save `PackedVector2Array` as a JSON array of `[x, y]` pairs via `Array(poly.polygon)`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Polygon2D.polygon` | Get/set the `PackedVector2Array` of vertex positions |
| `Geometry2D.get_closest_point_to_segment(p, a, b)` | Nearest point on segment `[a,b]` to point `p` |
| `Geometry2D.convex_hull(points)` | Minimal convex polygon enclosing all points (Quickhull) |
| `Geometry2D.polygon_area(points)` | Signed area: positive = CCW winding |
| `PackedVector2Array.insert(idx, pt)` | Insert a point at index (shifts subsequent elements) |
| `PackedVector2Array.remove_at(idx)` | Remove point at index |
| `Vector2.distance_to(other)` | Euclidean distance between two points |
| `CanvasItem.draw_line(from, to, color, width)` | Draw edge lines in `_draw()` |
| `CanvasItem.draw_circle(center, radius, color)` | Draw vertex handles in `_draw()` |

## Controls

| Input | Action |
|-------|--------|
| **Left-click drag on vertex** | Move the vertex |
| **Right-click** | Insert a new vertex on the nearest edge |
| **Middle-click on vertex** | Delete vertex (minimum 3) |
| **Convexify button** | Replace with convex hull |
| **Reset button** | Restore default hexagon |

## Key Constants

```gdscript
const VERTEX_RADIUS := 10.0  # pixels — click radius for vertex selection
const EDGE_HIT_DIST := 14.0  # pixels — click distance for edge insertion
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Vertex editing, `Geometry2D` calls, `_draw()` rendering |
| `scenes/main.tscn` | Root with Polygon2D, InfoLabel, and buttons |
