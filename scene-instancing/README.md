# Scene Instancing

Demonstrates how to instantiate a scene at runtime using `preload()` and a `Timer`, creating independent copies that each self-destruct after a fixed duration.

## Purpose

Scene instancing is Godot's fundamental code reuse mechanism. A `.tscn` file is a template. `PackedScene.instantiate()` creates a new, independent copy of that template — with its own node tree, scripts, and state. This demo shows the complete pattern: defining a reusable scene, preloading it as a resource, spawning copies on a timer, and having each instance manage its own lifetime.

## Controls

No player controls. Watch coins appear and disappear automatically.

## How It Works

### Node Tree

```
Main (Node2D)                ← spawner.gd
├── CountLabel (Label)
└── (Coin Area2D ×N — added at runtime)
```

### `scenes/coin.tscn`

The coin is its own scene:
```
Coin (Area2D)          ← coin.gd
└── CollisionShape2D
```

### `scripts/coin.gd`

```gdscript
extends Area2D

func _ready() -> void:
    queue_redraw()
    get_tree().create_timer(4.0).timeout.connect(queue_free)

func _draw() -> void:
    draw_circle(Vector2.ZERO, 14, Color.GOLD)
    draw_arc(Vector2.ZERO, 14, 0, TAU, 32, Color.DARK_GOLDENROD, 2.0)
```

The coin's `_ready()` does two things:
1. `queue_redraw()` — triggers `_draw()` on the first frame
2. `get_tree().create_timer(4.0).timeout.connect(queue_free)` — after 4 seconds, `queue_free` is called, destroying the coin

`queue_free` is passed directly as a `Callable` without parentheses. This is method reference syntax — the method itself is passed, not its return value.

### `scripts/spawner.gd`

```gdscript
const Coin = preload("res://scenes/coin.tscn")

var count := 0

func _ready() -> void:
    var timer := Timer.new()
    add_child(timer)
    timer.wait_time = 1.0
    timer.timeout.connect(_spawn)
    timer.start()
    _spawn()   # spawn one immediately

func _spawn() -> void:
    var coin := Coin.instantiate()
    coin.position = Vector2(randf_range(30, 610), randf_range(50, 440))
    add_child(coin)
    count += 1
    $CountLabel.text = "Coins spawned: %d  (each lives 4 seconds)" % count
```

`preload("path")` loads the `PackedScene` resource at **compile time** (before the game runs). This is more efficient than `load()` (runtime loading) for resources you know you will need.

`Coin.instantiate()` creates a new `Node` tree from the template. The returned node is the root of the new tree (an `Area2D` in this case). It must be `add_child()`'ed to enter the scene tree and have `_ready()` called.

## Scene Instancing Theory

### PackedScene as a Blueprint

A `PackedScene` (`.tscn` file) is a data structure describing a node tree: node types, property values, child relationships, and attached scripts. `instantiate()` reads this description and constructs a live node tree. Think of it as a class definition (the `.tscn`) and an object (the instantiated tree).

### preload vs load

```gdscript
const Coin = preload("res://scenes/coin.tscn")   # compile-time, fails fast
var  coin  = load("res://scenes/coin.tscn")       # runtime, lazy
```

`preload()` validates the path and loads the resource when the script is compiled. If the path is wrong, the error appears immediately in the editor. `load()` loads at the moment it is called — useful for optional or conditional resources.

### Lifecycle of an Instance

1. `Coin.instantiate()` — tree is built, `_init()` called on each node
2. `add_child(coin)` — node enters the scene tree
3. `_ready()` called — node is fully initialized, parent and children are set
4. `_process()`/`_physics_process()` — runs each frame
5. `queue_free()` — scheduled for deletion
6. End of frame: node removed from tree, freed from memory

### Timer as a Node Child

The Timer is created programmatically and added as a child. This ensures:
- Its lifetime is tied to the spawner (freed when Main is freed)
- It is accessible via `$Timer` or the reference `timer`
- It uses the scene tree's pause system (stops when paused)

`timer.autostart = false` (default) requires `timer.start()` to begin. Setting `timer.one_shot = false` (default) makes it repeat — needed here for continuous spawning.

### create_timer() vs Timer Node

```gdscript
get_tree().create_timer(4.0).timeout.connect(queue_free)
```

`SceneTree.create_timer()` creates a lightweight timer not attached to any node. It does not pause when the scene tree is paused (unless `process_callback` is set). Good for fire-and-forget delays. For timers that need to pause with the game, use a Timer node.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `preload("res://scenes/x.tscn")` | Load PackedScene at compile time |
| `PackedScene.instantiate()` | Create a node tree copy |
| `add_child(node)` | Add to scene tree (triggers _ready) |
| `Timer.timeout` signal | Fires when wait_time elapses |
| `get_tree().create_timer(seconds)` | Lightweight fire-and-forget timer |
| `queue_free` (as Callable) | Method reference, not a call |
| `randf_range(min, max)` | Random float in range |
