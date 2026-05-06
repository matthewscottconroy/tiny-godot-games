# Grid Pathfinding

A* pathfinding on a 20×14 tile grid — written from scratch in GDScript without `NavigationAgent2D`. Left-click to place start and goal; right-click to toggle walls; the shortest path updates instantly.

## Purpose

Godot's `NavigationAgent2D` is a black box that works on navmeshes, not tiles. Grid-based games — roguelikes, tactics games, puzzle games — often have a natural tile structure where A* on a 2D array is simpler, faster, and more controllable than any navmesh. This demo shows A* directly: open set, g-score, Manhattan heuristic, and path reconstruction. Understanding this code is a prerequisite for customizing pathfinding: adding terrain weights, diagonal movement, hierarchical path caching, or partial paths.

The implementation in this demo is deliberately minimal — a flat array-based open list, Manhattan heuristic, 4-directional movement — so every line serves the algorithm rather than infrastructure. The companion pathfinding-astar demo adds a richer interactive visualization with open/closed-set color coding.

## How It Works

### A* Implementation (`scripts/main.gd`)

```gdscript
func _astar() -> Array:
    if not _valid(_start) or not _valid(_goal):
        return []
    var open:      Array = [{"pos": _start, "f": _heuristic(_start)}]
    var came_from: Dictionary = {}
    var g_score:   Dictionary = {_start: 0}

    while open.size() > 0:
        # Pick the node with the lowest f-score (linear scan)
        var bi := 0
        for i in open.size():
            if open[i]["f"] < open[bi]["f"]: bi = i
        var cur: Vector2i = open[bi]["pos"]
        open.remove_at(bi)

        if cur == _goal:
            return _reconstruct(came_from, cur)

        for nb in _neighbors(cur):
            var tg: int = g_score.get(cur, 999999) + 1
            if tg < g_score.get(nb, 999999):
                came_from[nb] = cur
                g_score[nb]   = tg
                var ff := tg + _heuristic(nb)
                var found := false
                for n in open:
                    if n["pos"] == nb: found = true; break
                if not found:
                    open.append({"pos": nb, "f": ff})
    return []
```

### Manhattan Heuristic

```gdscript
func _heuristic(c: Vector2i) -> int:
    return absi(c.x - _goal.x) + absi(c.y - _goal.y)
```

Manhattan distance is **admissible** on a 4-connected grid: it never overestimates the true minimum step count, so A* is guaranteed to return the optimal (shortest) path.

### Path Reconstruction

```gdscript
func _reconstruct(came_from: Dictionary, cur: Vector2i) -> Array:
    var path := [cur]
    while came_from.has(cur):
        cur = came_from[cur]
        path.push_front(cur)
    return path
```

`came_from` maps each explored cell to the predecessor that reached it with the lowest cost. Walking backward from goal to start builds the optimal path. `push_front` produces the path in start-to-goal order.

### Neighbor Enumeration

```gdscript
func _neighbors(c: Vector2i) -> Array:
    var result := []
    for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
        var nb := c + d
        if _valid(nb) and _grid[nb.y][nb.x]:
            result.append(nb)
    return result
```

`_grid[y][x]` is `true` for walkable cells and `false` for walls. The order matches `[right, left, down, up]` — tie-breaking is implicit in insertion order.

### Interaction Flow

The demo uses a three-phase click workflow:
1. Left-click sets start (green circle)
2. Left-click again sets goal (red circle) and immediately runs `_astar()`
3. Left-click resets both markers

Right-click toggles a cell between walkable and wall at any time.

## Algorithm Analysis

A* with a linear-scan open list has:

| Operation | Cost |
|-----------|------|
| Find minimum f | O(|open|) per step |
| Insert neighbor | O(1) amortized |
| Total (n cells) | O(n²) worst case |

For a 20×14 grid (280 cells) this is fast enough that even the worst case (no walls, entire grid explored) is imperceptible. For grids over ~1000 cells, replace the linear scan with a binary heap (min-heap by f-score) to get O(n log n).

Godot's built-in `AStar2D` class uses a priority queue internally. The open-list structure here is identical in concept — the difference is only the data structure backing it. Use `AStar2D` in production; use this to understand its internals.

## How to Adapt This in Your Project

- For diagonal movement, add `Vector2i(1,1)`, `Vector2i(-1,1)`, `Vector2i(1,-1)`, `Vector2i(-1,-1)` to the neighbor directions and switch the heuristic to `maxf(absi(dx), absi(dy))` (Chebyshev distance).
- For weighted terrain, change `g_score.get(cur, 999999) + 1` to `+ tile_cost(nb)`. Define a cost array alongside `_grid` (e.g., 2 for mud, 5 for water, 1 for road).
- For partial paths (goal unreachable), return the path to the closest cell reached rather than an empty array. Track the cell with the minimum `h` value and reconstruct to it on failure.
- To update the path when walls change in gameplay, call `_astar()` on a debounce timer or only when a wall in the current path is toggled.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2i` | Integer 2D coordinate for grid cell addressing |
| `Dictionary.get(key, default)` | Safe score lookup with a fallback default |
| `Array.remove_at(index)` | Remove the selected minimum from the open list |
| `InputEventMouseButton` | Detect click position and left/right button |
| `draw_rect`, `draw_circle` | Immediate-mode grid and marker rendering |
| `@onready var _hint: Label` | Scene-tree label for interactive instructions |

## Controls

| Input | Action |
|-------|--------|
| Left-click | Set start → set goal → reset |
| Right-click | Toggle cell walkable / wall |

The yellow path updates immediately when a goal is placed or a wall is toggled.

## Key Constants

```gdscript
const COLS     := 20    # grid width in cells
const ROWS     := 14    # grid height in cells
const CELL     := 30    # cell size in pixels
const OFFSET_X := 10    # left margin in pixels
const OFFSET_Y := 35    # top margin (below hint label)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | A* implementation, click handling, grid rendering |
| `scenes/main.tscn` | Main scene with `HintLabel` node |
