# Polygon Clip

Demonstrates interactive `Polygon2D` manipulation — dragging vertices, inserting new points on edges, deleting points, and computing convex hull and area via `Geometry2D`.

## Purpose

Polygon editing is the foundation of level editors, shape tools, and collision setup UIs. This demo shows how to hit-test a polygon's vertices and edges, how to insert points at the closest edge position, and how Godot's `Geometry2D` class provides ready-made polygon math (convex hull, area).

## Controls

- **Left-click drag on a vertex**: Move the vertex
- **Left-click on an edge** (no nearby vertex): Insert a new vertex
- **Right-click on a vertex**: Delete it (minimum 3 vertices)
- **Convexify button**: Replace polygon with its convex hull
- **Reset button**: Restore to default pentagon

## How It Works

### Node Tree

```
Main (Node2D)       ← main.gd
├── Polygon2D
└── HUD (CanvasLayer)
    ├── InfoLabel
    └── [Convexify, Reset buttons]
```

### `scripts/main.gd`

- **`_find_vertex(pos)`** — Iterates `Polygon2D.polygon` and returns the index of the vertex closest to `pos` if within `VERTEX_RADIUS = 10` pixels.
- **`_insert_point(pos)`** — For each edge, calls `Geometry2D.get_closest_point_to_segment(pos, a, b)` and checks if the distance is < `14` pixels. If so, inserts the closest point between the two edge vertices.
- **`_delete_vertex(idx)`** — Removes the vertex at `idx` from the `PackedVector2Array` only if `polygon.size() > 3`.
- **`_convexify()`** — Calls `Geometry2D.convex_hull(polygon.polygon)` which returns the minimal enclosing convex polygon (vertices in counter-clockwise order).
- **InfoLabel** — Shows vertex count and `Geometry2D.polygon_area(polygon.polygon)` (signed; negative for clockwise winding).

### PackedVector2Array Mutation

`Polygon2D.polygon` returns a copy of the internal `PackedVector2Array`. To modify it:
```gdscript
var verts := poly.polygon
verts.insert(idx, new_point)  # or remove_at(idx)
poly.polygon = verts           # assign back to apply
```

The copy-on-write semantics mean you must explicitly reassign — mutating the returned array in place has no effect on the polygon.

### Convex Hull

`Geometry2D.convex_hull(points)` implements the Quickhull algorithm. It accepts any `PackedVector2Array` and returns the smallest convex polygon enclosing all points. Points inside the hull are discarded. Use this to enforce convexity constraints (required for physics collision shapes).

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Polygon2D.polygon` | `PackedVector2Array` of vertex positions |
| `Geometry2D.get_closest_point_to_segment(p, a, b)` | Nearest point on a line segment |
| `Geometry2D.convex_hull(points)` | Minimal convex enclosing polygon |
| `Geometry2D.polygon_area(points)` | Signed area (positive = CCW) |
| `PackedVector2Array.insert(idx, pt)` | Insert point at index |
| `PackedVector2Array.remove_at(idx)` | Remove point at index |
