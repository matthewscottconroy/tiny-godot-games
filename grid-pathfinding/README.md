# Grid Pathfinding

A* pathfinding on a 20×14 tile grid — implemented from scratch in GDScript without NavigationAgent2D. Left-click to place start/goal; right-click to toggle walls; the path updates automatically.

## Purpose

Godot's NavigationAgent2D is a black box. This demo shows A* directly: open set, g-score, Manhattan heuristic, and path reconstruction. Useful for understanding the algorithm before relying on the engine's implementation, and for grid-based games where the tile structure maps naturally to A*.

## Controls

- **Left-click**: Place start (first click) → goal (second click) → reset
- **Right-click**: Toggle cell between walkable and wall

## How It Works

### A* implementation (`scripts/main.gd`)

```gdscript
func _astar() -> Array:
    var open := [{"pos": _start, "f": _heuristic(_start)}]
    var g_score := {_start: 0}

    while open.size() > 0:
        # Pick lowest-f node (linear scan — fine for 300 cells)
        var cur := open.remove lowest f node
        if cur == _goal:
            return _reconstruct(came_from, cur)
        for nb in _neighbors(cur):
            var tg := g_score[cur] + 1
            if tg < g_score.get(nb, 999999):
                came_from[nb] = cur
                g_score[nb]   = tg
                open.append({"pos": nb, "f": tg + _heuristic(nb)})
```

### Manhattan heuristic

```gdscript
func _heuristic(c: Vector2i) -> int:
    return absi(c.x - _goal.x) + absi(c.y - _goal.y)
```

Manhattan distance is admissible on a 4-connected grid — never overestimates, so A* guarantees the shortest path.

### Path reconstruction

```gdscript
func _reconstruct(came_from: Dictionary, cur: Vector2i) -> Array:
    var path := [cur]
    while came_from.has(cur):
        cur = came_from[cur]
        path.push_front(cur)
    return path
```

`came_from` maps each cell to the cell that preceded it. Walking backward from goal to start reconstructs the optimal path.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2i` | Integer 2D coordinate for grid cells |
| `Dictionary.get(key, default)` | Safe score lookup with infinity default |
| `InputEventMouseButton` | Detect which mouse button and position |
| `draw_rect / draw_circle` | Immediate-mode grid and path rendering |
