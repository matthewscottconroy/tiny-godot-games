# Navigation Agent

Demonstrates `NavigationAgent2D` with a code-built `NavigationPolygon` — click anywhere to send an agent along an A*-computed path that avoids obstacles.

## Purpose

Pathfinding is a prerequisite for any enemy AI that needs to reach the player, any NPC that navigates a level, or any unit in a strategy game. Without a navigation system you would need to implement A* yourself and keep it synchronized with your level geometry. Godot's navigation server handles path computation automatically once you define the walkable area, making enemy AI that avoids walls a few dozen lines of code rather than hundreds.

Real games that rely on this pattern include every top-down RPG (enemies chase the player around furniture), tower defense games (waves route around towers), and real-time strategy games (squads navigate around obstacles). The principle is identical at any scale.

This demo shows how to build the walkable region entirely in code using `NavigationPolygon` outlines, how to drive an agent along the computed path each physics frame, and how to visualize the path for debugging.

## How It Works

### Node Tree

```
Main (Node2D)                   <- main.gd
├── NavigationRegion2D          <- defines walkable area
├── Agent (CharacterBody2D)
│   ├── NavigationAgent2D       <- path requester
│   └── CollisionShape2D
├── TargetMarker (Node2D)       <- visual for click target
└── HUD (CanvasLayer)
    └── StatusLabel
```

### Building the Navigation Mesh in Code

```gdscript
func _build_navmesh() -> void:
    var poly := NavigationPolygon.new()
    poly.add_outline(PackedVector2Array([   # outer walkable boundary
        Vector2(30, 40), Vector2(610, 40),
        Vector2(610, 440), Vector2(30, 440),
    ]))
    for obs in OBSTACLES:
        var margin := 6.0
        poly.add_outline(PackedVector2Array([  # obstacle hole
            Vector2(obs.position.x - margin, obs.position.y - margin),
            Vector2(obs.end.x + margin,      obs.position.y - margin),
            Vector2(obs.end.x + margin,      obs.end.y + margin),
            Vector2(obs.position.x - margin, obs.end.y + margin),
        ]))
    poly.make_polygons_from_outlines()
    $NavigationRegion2D.navigation_polygon = poly
```

`make_polygons_from_outlines()` triangulates using the even-odd fill rule: regions enclosed by an odd number of outlines are walkable. The outer boundary is enclosed once (walkable); each obstacle hole is enclosed twice (not walkable).

### Setting the Target (Deferred)

```gdscript
func _ready() -> void:
    _build_navmesh()
    call_deferred("_set_target", _target_marker.position)

func _set_target(pos: Vector2) -> void:
    _nav_agent.target_position = pos
```

`call_deferred` delays the first target assignment by one frame. The NavigationServer processes region registration asynchronously — setting `target_position` before it has registered the region produces an empty path.

### Moving Along the Path

```gdscript
func _physics_process(_delta: float) -> void:
    if _nav_agent.is_navigation_finished():
        _agent.velocity = Vector2.ZERO
        return
    var next := _nav_agent.get_next_path_position()
    var dir  := next - _agent.global_position
    if dir.length() > 2.0:
        _agent.velocity = dir.normalized() * AGENT_SPEED
    else:
        _agent.velocity = Vector2.ZERO
    _agent.move_and_slide()
```

`get_next_path_position()` returns the next waypoint toward the target. Moving toward it each frame steps the agent along the path. The `> 2.0` guard prevents jittering when the agent is very close to a waypoint.

### Path Visualization

```gdscript
var path := _nav_agent.get_current_navigation_path()
for i in path.size() - 1:
    draw_line(path[i], path[i + 1], Color(0.3, 0.85, 0.5, 0.6), 2.0)
```

`get_current_navigation_path()` returns the full computed waypoint array. Drawing it each frame (inside `_draw()`, triggered by `queue_redraw()` in `_physics_process`) gives real-time path visualization.

## NavigationPolygon Theory

The even-odd winding rule determines walkability: count how many outlines surround a point. Odd count = walkable (inside the outer boundary, outside obstacles). Even count = blocked (inside an obstacle hole). This means obstacles are created by adding inner outlines that "subtract" from the walkable region without requiring separate boolean geometry operations.

The 6-pixel margin on each obstacle outline ensures the agent's collision radius doesn't cause it to clip corners. In production, this margin should match the agent's `radius` property.

## How to Adapt This in Your Project

- **Tile-based levels**: Generate obstacle outlines from your tilemap by reading `TileMap.get_used_cells()` and building obstacle rectangles for blocked tiles, then call `make_polygons_from_outlines()` once after level load.
- **Enemy AI**: Move target-setting into an enemy state machine — call `_nav_agent.target_position = player.global_position` each frame in a "chase" state, and check `is_navigation_finished()` to transition to an "attack" state.
- **Multiple agents**: Each `NavigationAgent2D` computes its own path independently. The NavigationServer is shared and thread-safe — hundreds of agents on the same region is fine.
- **Dynamic obstacles**: To add or remove obstacles at runtime, rebuild the `NavigationPolygon` and reassign it. For frequently changing obstacles, consider `NavigationObstacle2D` instead.

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
| `call_deferred(method, args)` | Delay a call one frame (needed for nav server init) |

## Controls

| Input | Action |
|-------|--------|
| Left-click | Set navigation target; agent moves immediately |

## Key Constants

```gdscript
const AGENT_SPEED := 120.0   # pixels per second

# Obstacle rectangles (Rect2) — used for both visuals and navmesh holes
const OBSTACLES := [
    Rect2(160, 120, 130, 180),
    Rect2(350, 180, 130, 160),
    Rect2(220, 340, 200,  60),
]
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Builds navmesh, handles click input, drives agent movement, draws debug visuals |
| `scenes/main.tscn` | Scene tree with NavigationRegion2D, Agent, TargetMarker, and HUD |
