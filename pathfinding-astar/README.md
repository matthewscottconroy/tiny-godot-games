# A* Pathfinding

An interactive A* pathfinder on a 20×15 grid. Paint walls, drag start and goal positions, and watch the algorithm highlight its open set, closed set, and optimal path in real time.

## Purpose

A* is the standard algorithm for shortest-path navigation in games, used in everything from strategy games (StarCraft's unit pathfinding) to RPGs (Diablo's dungeon traversal). It improves on Dijkstra's algorithm by adding a heuristic that biases exploration toward the goal, dramatically reducing the number of cells evaluated on typical game maps.

Understanding A* at this level — before reaching for Godot's NavigationAgent2D — gives you the ability to customize it: add terrain costs, restrict movement to specific tiles, implement hierarchical pathfinding for large worlds, or port it to non-Euclidean spaces like hex grids. The visual open/closed set display in this demo is a direct window into the algorithm's decision-making process.

For simple navigation needs, `NavigationAgent2D` is faster to set up. Use a hand-rolled A* when tile structure matters, when you need full control over movement costs, or when you want path data as an array of grid cells rather than a navmesh polygon path.

## How It Works

### Algorithm Implementation (`scripts/main.gd`)

```gdscript
func _run_astar() -> void:
    var open_list: Array[Vector2i] = [_start]
    var came_from: Dictionary = {}
    var g_score: Dictionary = {_start: 0}
    var f_score: Dictionary = {_start: _heuristic(_start, _goal)}

    while open_list.size() > 0:
        # Find node with lowest f_score (linear scan)
        var current := open_list[0]
        for node in open_list:
            if f_score.get(node, INF) < f_score.get(current, INF):
                current = node

        if current == _goal:
            # Reconstruct path by walking came_from backward
            var node := current
            while came_from.has(node):
                _path.push_front(node)
                node = came_from[node]
            _path.push_front(_start)
            return

        open_list.erase(current)
        closed_set_dict[current] = true

        for neighbor in _get_neighbors(current):
            if closed_set_dict.has(neighbor): continue
            var tentative_g: float = g_score.get(current, INF) + 1.0
            if tentative_g < g_score.get(neighbor, INF):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + _heuristic(neighbor, _goal)
                if not neighbor in open_list:
                    open_list.append(neighbor)
```

### Heuristic

```gdscript
func _heuristic(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x - b.x) + abs(a.y - b.y)
```

Manhattan distance is **admissible** for 4-directional movement: it never overestimates the true path length, guaranteeing that A* returns the optimal path. Using a heuristic that overestimates (inadmissible) can produce shorter-seeming paths that are actually longer in step count.

### Neighbor Enumeration

```gdscript
func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
    var dirs: Array[Vector2i] = [
        Vector2i(1, 0), Vector2i(-1, 0),
        Vector2i(0, 1), Vector2i(0, -1)
    ]
    var result: Array[Vector2i] = []
    for d in dirs:
        var n := cell + d
        if n.x >= 0 and n.x < COLS and n.y >= 0 and n.y < ROWS:
            if not _walls[n.y][n.x]:
                result.append(n)
    return result
```

Only 4-directional movement (no diagonals). To enable 8-directional movement, add the four diagonal directions and use Chebyshev distance (`max(|dx|, |dy|)`) as the heuristic.

### Visualization

Cells are color-coded by their A* status:

```gdscript
if _walls[r][c]:            col = Color(0.25, 0.25, 0.28)  # dark gray
elif path_set.has(cell):    col = Color(0.2, 0.85, 0.3)    # green
elif closed_set_dict.has(cell): col = Color(0.3, 0.5, 0.75, 0.55)  # blue
elif open_set_dict.has(cell):   col = Color(0.85, 0.82, 0.2, 0.55) # yellow
```

## A* Theory

A* maintains three data structures:

| Structure | Contents | Role |
|-----------|----------|------|
| Open set (yellow) | Discovered, not yet evaluated | Candidates for next expansion |
| Closed set (blue) | Fully evaluated | Shortest path from start confirmed |
| `came_from` | node → predecessor | Used to reconstruct the path |

The f-score `f = g + h` combines actual cost from start (`g`) with estimated cost to goal (`h`). By always expanding the lowest-f node, A* explores the most promising paths first. When the heuristic is admissible, the first time A* reaches the goal it has found the optimal path.

**Complexity**: O(b^d) in the worst case where b is the branching factor and d is the depth, but with a good admissible heuristic, typically much better in practice. For a 20×15 grid (300 cells) with no walls, the algorithm evaluates most cells once. A priority queue (binary heap) would reduce the node selection from O(n) per step to O(log n); the linear scan here is fine for grids under ~1000 cells.

## How to Adapt This in Your Project

- For weighted terrain (mud costs 2, road costs 0.5), change `tentative_g = g_score[current] + tile_cost(neighbor)` in the main loop. The heuristic remains the same; A* automatically prefers cheaper paths.
- To add diagonal movement, include the four diagonal directions in `_get_neighbors` and switch the heuristic to `maxf(abs(dx), abs(dy))` (Chebyshev) or `sqrt(dx*dx + dy*dy) * 0.9` (octile) to maintain admissibility.
- For very large maps, replace the open list linear scan with a `priority queue` class (a binary heap). The scan is O(n) per step; a heap is O(log n).
- To support dynamic obstacles (moving enemies), re-run `_run_astar()` on a timer or only when the environment changes — avoid running every frame on large grids.
- Godot's built-in `AStar2D` class implements the same algorithm with a priority queue. Use it for production; use this demo to understand what it does internally.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2i` | Integer 2D coordinate — ideal for grid cell addressing |
| `Dictionary.get(key, INF)` | Safe score lookup returning infinity as default |
| `Array[Vector2i].push_front(v)` | Prepend during path reconstruction |
| `draw_rect(Rect2, color)` | Draw each grid cell |
| `draw_polyline(pts, color, width)` | Draw the path as a connected line |
| `InputEventMouseButton` | Detect click position and button index |

## Controls

| Input | Action |
|-------|--------|
| Left click | Toggle wall (in Wall mode) |
| Right click | Set start (green circle) |
| Middle click | Set goal (red circle) |
| Shift + Left click | Set goal (alternate shortcut) |
| Tab | Cycle click mode: Wall → Start → Goal |
| C | Clear all walls |
| R | Randomize walls at 30% density |

## Key Constants

```gdscript
const COLS := 20   # grid width in cells
const ROWS := 15   # grid height in cells
const CELL := 32   # cell size in pixels
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Full A* implementation, interactive input, grid rendering |
| `scenes/main.tscn` | Main scene |
| `tests/test_logic.gd` | Unit tests: straight path, wall avoidance, no-path, heuristic, start=goal |
| `tests/test.tscn` | Test runner scene |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [input-recording](../input-recording) — Capturing input per frame and replaying it deterministically.
- [procedural-animation](../procedural-animation) — FABRIK inverse kinematics on an 8-joint chain following the mouse.
- [radial-menu](../radial-menu) — Hold Tab to open a six-item radial action menu.
- [steering-behaviors](../steering-behaviors) — Reynolds' Seek/Arrive, Flee, and Wander force-based steering.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

