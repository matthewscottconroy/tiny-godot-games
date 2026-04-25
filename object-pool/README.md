# Object Pool

Demonstrates the object pool pattern: pre-allocating a fixed number of objects at startup and recycling them instead of repeatedly creating and destroying them.

## Purpose

Instantiating and freeing nodes is expensive. In performance-critical scenarios — rapid bullet fire, particle emitters, enemy spawners — `queue_free()` and `PackedScene.instantiate()` each frame can cause frame spikes. The object pool solves this by creating all objects once, hiding unused ones, and reusing them when needed. This demo shows the pattern with a bullet pool, including statistics on pool utilization.

## Controls

- **Arrow keys / WASD**: Move and aim (facing follows movement)
- **Space / Enter** (`ui_accept`): Fire a bullet (taken from the pool)
- Watch the stats label: pool size, active bullets, reuses, and pool misses

## How It Works

### Node Tree

```
Main (Node2D)                   ← main.gd
├── BulletPool (Node2D)         ← bullet_pool.gd  (contains pre-created bullets)
│   ├── Bullet0 (Node2D)        ← bullet.gd  (×20, created at startup)
│   └── ...
├── Player (CharacterBody2D)    ← player.gd
└── StatsLabel (Label)
```

### `scripts/bullet_pool.gd`

```gdscript
const POOL_SIZE := 20

func _ready() -> void:
    for i in POOL_SIZE:
        var b := Node2D.new()
        b.set_script(load("res://scripts/bullet.gd"))
        b.visible = false
        add_child(b)

func request_bullet() -> Node2D:
    for child in get_children():
        if not child.visible:
            _hits += 1
            _update_stats()
            return child
    _misses += 1
    _update_stats()
    return null
```

`_ready()` pre-creates 20 bullet nodes, all invisible. `request_bullet()` scans children for the first invisible one and returns it. If all 20 are active (pool exhausted), it returns `null` and logs a miss. The caller is responsible for activating and firing the returned bullet.

### `scripts/bullet.gd`

```gdscript
func fire(from: Vector2, dir: Vector2) -> void:
    global_position = from
    direction = dir
    _lifetime = 1.8
    visible = true

func _return_to_pool() -> void:
    visible = false
    _lifetime = 0.0

func _process(delta: float) -> void:
    if not visible: return
    global_position += direction * speed * delta
    _lifetime -= delta
    if _lifetime <= 0.0:
        _return_to_pool()
```

The bullet's "lifecycle" is managed through visibility and `_lifetime`. `fire()` activates and positions it. When the lifetime expires, `_return_to_pool()` hides it — making it available for reuse on the next `request_bullet()` call.

### `scripts/main.gd`

Connects `player.fired` (emitted when `ui_accept` is pressed) to a handler that calls `pool.request_bullet()` and then `bullet.fire(from, dir)`.

### `scripts/player.gd`

Same as cooldown-shoot but uses a signal instead of directly instantiating bullets:
```gdscript
signal fired(from: Vector2, dir: Vector2)
if Input.is_action_just_pressed("ui_accept"):
    fired.emit(global_position + facing * 20, facing)
```

## Object Pool Theory

### Why Pooling Matters

Every `Node.new()` + `add_child()` call:
1. Allocates memory
2. Registers the node with the SceneTree
3. Runs `_ready()` on the new node

Every `queue_free()` call:
1. Schedules the node for removal
2. Runs cleanup callbacks
3. Deallocates memory

These are not "free" operations. For bullets fired at 10/second across 60 fps, that is 600 alloc/free pairs per minute. Object pools amortize this cost to a one-time startup allocation.

### Visible as Active Flag

Using `visible` as the "in use" flag is a clean approach:
- `visible = false` — bullet is inactive, skips `_draw()` and rendering
- `visible = true` — bullet is active, moves and renders
- The pool scanner `if not child.visible` naturally finds available slots

The alternative is a separate `var in_use := false` flag, which works but adds an extra state variable.

### Pool Exhaustion

When `request_bullet()` returns `null`, the caller can:
- Skip the shot (implemented here)
- Dynamically grow the pool (add more bullets)
- Force-reclaim the oldest bullet

For games where pool exhaustion is common, dynamic growth is safest. For controlled scenarios (the player has a cooldown), a fixed-size pool with early miss detection is sufficient.

### Lifetime Without Timer Nodes

`_lifetime -= delta` in `_process()` tracks duration without a `Timer` node. Since bullets return themselves to the pool when lifetime expires, no external management is needed. This is more efficient than having 20 Timer nodes (one per bullet) all running simultaneously.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Node.new()` + `set_script(script)` | Create a node with a script |
| `Node.visible` | Show/hide node (used as pool active flag) |
| `Node.add_child(node)` | Add to scene tree |
| `Node.get_children()` | Array of direct children |
| `Array.filter(callable)` | Filter array by condition |
| `signal fired(from, dir)` | Decouple player from pool management |
