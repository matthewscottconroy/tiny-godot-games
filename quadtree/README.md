# Quadtree Spatial Partitioning

60 bouncing balls are inserted into a quadtree every frame. Collision detection uses spatial queries instead of every-pair brute force, reducing checks from 1770 to roughly 80–200 per frame depending on clustering.

## Purpose

Spatial partitioning is one of the most important optimizations in game physics and AI. Without it, collision detection, vision checks, pathfinding queries, and enemy awareness all scale as O(n²) — 60 objects means 3600 pair checks, 600 objects means 360,000. A quadtree reduces this to O(n log n) average case by only comparing objects that share the same cell of space.

Real games use spatial partitioning constantly: Minecraft's chunk system is a spatial grid. Unity's Physics broadphase uses a dynamic AABB tree. Godot's `TileMap` cull rendering using a spatial index. The quadtree shown here is the simplest spatial structure to understand and implement: each rectangle subdivides into four equal children when it gets too full.

Use a quadtree when objects are unevenly distributed — it adapts its cell sizes to clustering. Use a uniform grid when objects are evenly spread and you want constant-time queries. For very large or streaming worlds, use a spatial hash instead.

## How It Works

### QTNode Structure (`scripts/qt_node.gd`)

```gdscript
const MAX_OBJECTS := 4   # objects per leaf before splitting
const MAX_DEPTH   := 6   # maximum recursion depth

var bounds:   Rect2        # this node's spatial region
var depth:    int
var objects:  Array = []   # items in this leaf
var children: Array = []   # 4 QTNode children when subdivided
```

### Subdivision

When a leaf holds more than `MAX_OBJECTS` items and hasn't hit `MAX_DEPTH`, it splits into four equal quadrants and redistributes its items:

```gdscript
func subdivide() -> void:
    var hw := bounds.size.x * 0.5
    var hh := bounds.size.y * 0.5
    var x := bounds.position.x; var y := bounds.position.y
    children = [
        QTNode.new(Rect2(x,      y,      hw, hh), depth + 1),  # NW
        QTNode.new(Rect2(x + hw, y,      hw, hh), depth + 1),  # NE
        QTNode.new(Rect2(x,      y + hh, hw, hh), depth + 1),  # SW
        QTNode.new(Rect2(x + hw, y + hh, hw, hh), depth + 1),  # SE
    ]
```

An item that straddles a boundary is inserted into all overlapping children. This is simpler than clipping but means dense boundary areas create duplicate insertions. The alternative — assigning each item to exactly one cell — requires a different query strategy.

### Insert

```gdscript
func insert(obj: Dictionary) -> void:
    if children.size() > 0:
        for c in _get_quadrants(obj):
            c.insert(obj)
        return
    objects.append(obj)
    if objects.size() > MAX_OBJECTS and depth < MAX_DEPTH:
        subdivide()
        for o in objects:
            for c in _get_quadrants(o):
                c.insert(o)
        objects.clear()
```

Items are always stored in leaf nodes. When a leaf overflows, it promotes all items to the new children and clears itself.

### Query

```gdscript
func query(area: Rect2) -> Array:
    var result: Array = []
    if not bounds.intersects(area):
        return result  # prune entire branch
    for o in objects:
        if area.has_point(o.pos):
            result.append(o)
    for c in children:
        result.append_array(c.query(area))
    return result
```

The `bounds.intersects(area)` check is the key optimization: any branch whose region does not overlap the query rectangle is skipped entirely.

### Per-Frame Usage (`scripts/main.gd`)

```gdscript
_qt.clear()
for ball in _balls:
    _qt.insert(ball)

for ball in _balls:
    var query_rect := Rect2(
        ball.pos - Vector2(BALL_R * 2, BALL_R * 2),
        Vector2(BALL_R * 4, BALL_R * 4)
    )
    var nearby := _qt.query(query_rect)
    for other in nearby:
        if other == ball: continue
        if ball.pos.distance_to(other.pos) < BALL_R * 2.0:
            ball.colliding = true; other.colliding = true
```

The tree is rebuilt every frame because balls move. For static geometry (walls, pickups) the tree can be built once and reused.

## Quadtree Theory

A quadtree is a spatial index: a data structure that answers "which objects are near location X?" efficiently. Its recursive structure mirrors binary search: each level halves the search space in both dimensions, giving O(log n) average-case queries.

**Performance comparison (60 balls):**

| Approach | Checks per frame |
|----------|-----------------|
| Brute force | `n*(n-1)/2 = 1770` |
| Quadtree | Typically 80–200 |
| Saved | ~88–95% |

The savings grow super-linearly with object count because brute force scales as n², while quadtree scales as n log n.

**`MAX_OBJECTS` tuning**: Smaller values create more cells and finer subdivision (faster queries, more memory, higher insert cost). Larger values create fewer cells (faster inserts, slower queries). 4–8 is a reasonable range for 2D collision.

**`MAX_DEPTH` = 6**: Limits the minimum cell size to `640 / 2^6 = 10 px`, preventing infinite subdivision around overlapping objects.

## How to Adapt This in Your Project

- For a static level, insert walls and decorations once at startup. Query the tree each frame only for dynamic objects like enemies and projectiles.
- To support object removal without a full rebuild, add a `remove(obj)` method that clears the object and collapses empty branches.
- For entity awareness queries (which enemies can see this player?), use a circular query: `Rect2(center - r, Vector2(2*r, 2*r))` as the bounding box, then filter results by `distance_to` for the exact circle test.
- This implementation stores Dictionary objects. For a typed, production version, replace `Array` with `Array[YourClass]` and the `obj.pos` lookup with a typed property.
- Consider a uniform spatial hash (`Dictionary` keyed on `Vector2i` cell) when objects cluster unevenly but are all the same size — simpler code, O(1) average query.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Rect2.intersects(other)` | AABB overlap test — the core of tree pruning |
| `Rect2.has_point(p)` | Point-in-rectangle test for query results |
| `draw_rect(rect, color, false)` | Draw quadtree cell outlines |
| `draw_arc(pos, r, ...)` | Draw ball ring indicators |
| `randf_range(min, max)` | Random initial positions and velocities |

## Key Constants

```gdscript
const BALL_COUNT  := 60
const BALL_R      := 8.0
const MAX_OBJECTS := 4   # in QTNode — leaf capacity before split
const MAX_DEPTH   := 6   # in QTNode — maximum tree depth
```

## Files

| File | Purpose |
|------|---------|
| `scripts/qt_node.gd` | `QTNode` class: `insert`, `query`, `subdivide`, `clear`, `get_all_rects` |
| `scripts/main.gd` | 60 bouncing balls, per-frame tree rebuild, collision detection, stats overlay |
| `scenes/main.tscn` | Main scene |
| `tests/test_logic.gd` | Unit tests: insert/query, miss, subdivision trigger, max-depth, clear |
| `tests/test.tscn` | Test runner scene |
