# Custom Resource

Demonstrates how to define `class_name` resources with `@export` variables to create typed, reusable data containers — and how a visual node reacts automatically when its data changes.

## Purpose

In real games, enemy types, items, spells, and dialogue lines are often defined as data structures shared across many scenes. Godot's `Resource` system provides a typed, serializable container for this kind of data. Custom resources can be created in code, saved to `.tres` files, and assigned in the Inspector. This demo shows how to define a resource, create instances, and wire a node's visual to update automatically whenever the resource data changes.

## Controls

- **Goblin / Dragon / Random buttons**: Assign a different `EnemyStats` resource to the enemy
- Watch the enemy circle change size and color to reflect the new stats

## How It Works

### Node Tree

```
Main (Node2D)             ← main.gd
├── Enemy (Node2D)        ← enemy.gd
├── StatsLabel (Label)
└── Buttons (HBoxContainer)
    ├── GoblinBtn
    ├── DragonBtn
    └── RandomBtn
```

### `scripts/enemy_stats.gd` — The Resource

```gdscript
class_name EnemyStats
extends Resource

@export var enemy_name  := "Unknown"
@export var max_hp      := 100
@export var speed       := 80.0
@export var attack      := 10
@export var color       := Color.TOMATO
```

`class_name EnemyStats` registers this type globally. Any script can write `EnemyStats.new()` without importing. `extends Resource` gives it serialization (save/load to disk), Inspector support, and reference semantics.

`@export` on each field makes them editable in the Inspector when the resource is assigned to a node, and lets you save them in `.tres` resource files.

### `scripts/enemy.gd` — Property Setter Pattern

```gdscript
var stats : EnemyStats :
    set(value):
        stats = value
        queue_redraw()
```

The `stats` property uses a **setter**: any assignment to `enemy.stats` automatically triggers `queue_redraw()`, causing `_draw()` to run immediately. The enemy's visual always reflects the current stats without needing manual update calls.

`_draw()` reads `stats.max_hp` to compute the circle's radius (clamped between 12 and 40 pixels), and `stats.color` for the fill color. A Dragon (500 HP) draws a large red circle; a Goblin (30 HP) draws a small green one.

### `scripts/main.gd`

Creates fresh `EnemyStats` instances and assigns them to `enemy.stats`. The Goblin, Dragon, and Random presets each build a new resource with different field values:

```gdscript
func _apply_goblin() -> void:
    var s        := EnemyStats.new()
    s.enemy_name  = "Goblin"
    s.max_hp      = 30
    s.speed       = 140.0
    s.attack      = 5
    s.color       = Color.SEA_GREEN
    _apply(s)
```

## Custom Resource Theory

### Resource vs Node

| | Resource | Node |
|---|---|---|
| Lives in the scene tree | No | Yes |
| Serializable to disk | Yes (.tres) | Via .tscn |
| Reference semantics | Yes (shared) | No (scene-owned) |
| Has _process()/_ready() | No | Yes |
| Best for | Data, config, stats | Behavior, visuals |

### Reference Semantics

Resources are reference-counted. If two enemies share the same `EnemyStats` instance, changing one enemy's stats through the shared reference changes both. In this demo each button creates a `new()` instance, so stats are independent.

### class_name Global Registration

`class_name EnemyStats` registers the class with Godot's type system. This enables:
- Static typing: `var stats: EnemyStats`
- Type checks: `if x is EnemyStats`
- Inspector dropdowns that list `EnemyStats` as a valid type
- `EnemyStats.new()` from any script without imports

### Setter-Driven Reactivity

The pattern `var x: T: set(v): x = v; queue_redraw()` creates a **reactive property**. This is preferable to requiring callers to manually call `refresh()` after every change — callers only need to set the property. The node is responsible for knowing when to update its visual.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `class_name Foo` | Register type globally |
| `extends Resource` | Base class for data containers |
| `@export var name := value` | Editable field in Inspector |
| `var x: T: set(v):` | Property setter |
| `queue_redraw()` | Schedule _draw() for next frame |
| `Resource.new()` | Create a new resource instance |
| `clamp(value, min, max)` | Constrain to a range |
