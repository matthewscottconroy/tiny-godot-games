# Navigation Agent

Demonstrates `NavigationAgent2D` with a code-built `NavigationPolygon` — click anywhere to send an agent along an A*-computed path that avoids obstacles.

## Purpose

Pathfinding is a prerequisite for any enemy AI that needs to reach the player, any NPC that navigates a level, or any unit in a strategy game. Godot's navigation system handles path computation automatically once you define the walkable area. This demo shows how to build that area in code and drive an agent along the computed path.

## Controls

- **Left-click**: Set the navigation target; the agent immediately begins moving along the computed path

## How It Works

### Node Tree

```
Main (Node2D)                   ← main.gd
├── NavigationRegion2D          ← defines walkable area
├── Agent (CharacterBody2D)
│   ├── NavigationAgent2D       ← path requester
│   └── CollisionShape2D
├── TargetMarker (Node2D)       ← visual for click target
└── HUD (CanvasLayer)
```

### `scripts/main.gd`

- **`_build_navmesh()`** — Creates a `NavigationPolygon` with one outer outline (the walkable boundary) and three inner outlines (obstacle holes). Calls `poly.make_polygons_from_outlines()` to triangulate, then assigns it to `$NavigationRegion2D.navigation_polygon`.
- **`_set_target(pos)`** — Assigns `$Agent/NavigationAgent2D.target_position = pos`. The navigation server computes a new path asynchronously. Use `call_deferred("_set_target", ...)` on the first frame to ensure the NavigationServer has initialized.
- **`_physics_process()`** — Each frame: gets `agent.get_next_path_position()`, computes the direction to it, sets `velocity`, calls `move_and_slide()`.
- **`_draw()`** — Renders the walkable floor, obstacle blocks, the current navigation path as a dotted line, the target crosshair, and the agent circle with a velocity arrow.

### NavigationPolygon Outlines

```gdscript
var poly := NavigationPolygon.new()
poly.add_outline(outer_verts)   # walkable area
poly.add_outline(hole_verts)    # obstacle (inner outline = hole by even-odd rule)
poly.make_polygons_from_outlines()
region.navigation_polygon = poly
```

`make_polygons_from_outlines()` triangulates the outline set. The even-odd fill rule treats areas enclosed by an odd number of outlines as walkable. An inner outline inside the outer outline creates a hole (enclosed by 2 outlines = not walkable).

### Path Visualization

```gdscript
var path := _nav_agent.get_current_navigation_path()
for i in path.size() - 1:
    draw_line(path[i], path[i + 1], color, 2)
```

`get_current_navigation_path()` returns the full computed waypoint array for the current target. Useful for debug visualization and knowing how far the agent has to travel.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `NavigationRegion2D` | Registers a walkable polygon with the nav server |
| `NavigationPolygon.add_outline(verts)` | Add a boundary or hole outline |
| `NavigationPolygon.make_polygons_from_outlines()` | Triangulate outlines into nav data |
| `NavigationAgent2D.target_position` | World position to navigate toward |
| `NavigationAgent2D.get_next_path_position()` | Next waypoint to move toward |
| `NavigationAgent2D.is_navigation_finished()` | True when agent has reached target |
| `NavigationAgent2D.get_current_navigation_path()` | Full computed path array |
