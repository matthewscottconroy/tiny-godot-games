# Object Pool

<!-- tags: physics, ui, signals, component -->

Demonstrates the object pool pattern: pre-allocating a fixed number of objects at startup and recycling them instead of repeatedly creating and destroying them.

## Purpose

Instantiating and freeing nodes is expensive. In performance-critical scenarios — rapid bullet fire, particle emitters, enemy spawners — `queue_free()` and `PackedScene.instantiate()` each frame can cause frame spikes. The object pool solves this by creating all objects once, hiding unused ones, and reusing them when needed. This demo shows the pattern with a bullet pool, including statistics on pool utilization.

## Controls

- **Arrow keys**: Move and aim (facing follows movement)
- **Space / Enter** (`ui_accept`): Fire a bullet (taken from the pool)
- Watch the stats label: pool size, active bullets, reuses, and pool misses

## How It Works

### Node Tree

```
Main (Node2D)                   ← main.gd  (demo driver + stats display)
├── BulletPool (Node2D)         ← object_pool.gd  →  class_name ObjectPool
│   ├── Bullet (Node2D)         ← bullet.tscn  (×20, instanced at startup)
│   └── ...
├── Player (CharacterBody2D)    ← player.gd
└── StatsLabel (Label)
```

The pool is a **reusable component** (`ObjectPool`) with no knowledge of bullets or the demo. It pools whatever `PackedScene` you assign to its `scene` export. The demo assigns `bullet.tscn` and owns the stats label itself.

### `scripts/object_pool.gd`  (`class_name ObjectPool`)

```gdscript
@export var scene: PackedScene   # what to pool
@export var size := 20           # how many to pre-allocate

func _ready() -> void:
    assert(scene != null, "ObjectPool: `scene` is not set")
    for i in size:
        var instance := scene.instantiate()
        instance.visible = false
        add_child(instance)

func acquire() -> Node:
    for child in get_children():
        if not child.visible:
            reuse_count += 1
            acquired.emit(child)
            return child
    miss_count += 1          # pool exhausted
    exhausted.emit()
    return null
```

`_ready()` instantiates `size` copies of `scene`, all hidden. `acquire()` scans children for the first hidden one and returns it. If all are active (pool exhausted), it returns `null` and increments `miss_count`. The caller is responsible for activating (showing) and firing the returned instance. The pool emits `acquired`/`exhausted` signals and exposes `reuse_count` / `miss_count` / `active_count()` so a driver can display stats without the pool touching any UI.

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

The bullet's "lifecycle" is managed through visibility and `_lifetime`. `fire()` activates and positions it. When the lifetime expires, `_return_to_pool()` hides it — making it available for reuse on the next `acquire()` call.

### `scripts/main.gd`

The demo driver connects `player.fired` (emitted when `ui_accept` is pressed) to a handler that calls `pool.acquire()` and then `bullet.fire(from, dir)`, and each frame refreshes the stats label from the pool's public counters (`active_count()`, `reuse_count`, `miss_count`). Keeping the display here — rather than inside the pool — is what lets `ObjectPool` drop into any project unchanged.

### `scripts/player.gd`

Same as cooldown-shoot but uses a signal instead of directly instantiating bullets:
```gdscript
signal fired(from: Vector2, dir: Vector2)
if Input.is_action_just_pressed("ui_accept"):
    fired.emit(muzzle(), facing)
```

The two decisions behind that line live in their own methods, because the frame
around them reads `Input` and so cannot be driven by a test:

```gdscript
## Where the next shot starts: in front of the player, along its facing.
func muzzle() -> Vector2:
    return global_position + facing * MUZZLE_OFFSET

## The way to face given this frame's input. Released keys read as a zero
## vector, and normalising that gives (0, 0) — so the aim is left alone rather
## than overwritten, or letting go would point the player at nothing.
func aim_for(dir: Vector2, current: Vector2) -> Vector2:
    return dir.normalized() if dir.length() > 0.0 else current
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

When `acquire()` returns `null`, the caller can:
- Skip the shot (implemented here)
- Dynamically grow the pool (add more bullets)
- Force-reclaim the oldest bullet

For games where pool exhaustion is common, dynamic growth is safest. For controlled scenarios (the player has a cooldown), a fixed-size pool with early miss detection is sufficient.

### Lifetime Without Timer Nodes

`_lifetime -= delta` in `_process()` tracks duration without a `Timer` node. Since bullets return themselves to the pool when lifetime expires, no external management is needed. This is more efficient than having 20 Timer nodes (one per bullet) all running simultaneously.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `@export var scene: PackedScene` | The scene the pool pre-instantiates |
| `PackedScene.instantiate()` | Create an instance of the pooled scene |
| `Node.visible` | Show/hide node (used as pool active flag) |
| `Node.add_child(node)` | Add to scene tree |
| `Node.get_children()` | Array of direct children |
| `Array.filter(callable)` | Filter array by condition |
| `signal acquired(instance)` / `exhausted` | Report pool events without UI coupling |

## Files

| File | What it holds |
|------|---------------|
| `scripts/bullet.gd` | `bullet` behaviour |
| `scripts/main.gd` | Demo driver: wires the player's `fired` signal to the ObjectPool and shows |
| `scripts/object_pool.gd` | A fixed-size pool of reusable node instances |
| `scripts/player.gd` | `player` behaviour |
| `scenes/bullet.tscn` | Scene |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/object_pool.gd` (the `ObjectPool` class). It has no demo dependencies.

**Public API**
- `@export scene: PackedScene` — the scene pooled `size` times.
- `@export size: int` — instances pre-allocated at startup (default 20).
- `acquire() -> Node` — returns a hidden instance, or `null` if all are active.
- `active_count() -> int`, `reuse_count`, `miss_count` — stats for a HUD/debug view.
- signals `acquired(instance)`, `exhausted`.

**Integrate**
1. Add an `ObjectPool` node (a `Node2D`), set its `scene` and `size` in the Inspector.
2. To spawn: `var obj := pool.acquire()`, then activate it (`obj.show()` + reset its state).
3. To recycle: hide the instance (`obj.hide()`) — the pool treats hidden instances as available.

**Notes**
- `class_name ObjectPool` is global to the project — rename it if you already define an `ObjectPool`.
- The "hidden means available" contract assumes visual nodes. For non-visual objects, swap `visible` for a boolean flag or a free-list.
- Demo input uses the built-in `ui_*` actions for zero setup; in a real project define your own actions (e.g. `move_up`, `fire`) and use those instead.

## Related demos

- [hitbox-hurtbox](../hitbox-hurtbox) — The hitbox/hurtbox pattern — attack area separate from vulnerable area.
- [spread-shot](../spread-shot) — Fire N bullets distributed evenly across a fixed angle.
- [light-shadow](../light-shadow) — `PointLight2D` with a procedural radial gradient and `CanvasModulate`.
- [boid-flocking](../boid-flocking) — 35 agents flock via separation, alignment, and cohesion — emergent behavior.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

