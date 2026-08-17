# Typed Event Bus

A publish/subscribe event bus where events are identified by string keys and carry typed `Dictionary` payloads. Click enemies to fire `"enemy_died"` events — watch three independent systems (Score, UI, Audio) react without knowing about each other.

## Purpose

As games grow, systems that used to be small become entangled. A combat system directly calls the score manager, which directly calls the UI, which directly calls the audio manager. Every system holds references to every other system. Adding a new system (say, an achievements tracker) means finding every place that deals damage and adding another call.

The event bus breaks this coupling. When an enemy dies, the combat system emits one event. Every other system that cares subscribes independently. The combat system never learns about the achievements tracker — the achievements tracker subscribes on its own. Real games that use this pattern include the *Godot* editor itself (which uses signals as a bus), *Unity* projects using ScriptableObject events, and virtually every ECS-based game.

This demo shows a plain-object event bus (not an Autoload) to keep the implementation visible. In production, the bus is typically an Autoload so systems anywhere in the scene tree can reach it.

## How It Works

### `scripts/event_bus.gd` — The Bus

```gdscript
class_name EventBus

var _listeners: Dictionary = {}

func on(event_type: String, callback: Callable) -> void:
    if not _listeners.has(event_type):
        _listeners[event_type] = []
    _listeners[event_type].append(callback)

func off(event_type: String, callback: Callable) -> void:
    if _listeners.has(event_type):
        _listeners[event_type].erase(callback)

func emit(event_type: String, data: Dictionary = {}) -> void:
    if _listeners.has(event_type):
        for cb: Callable in _listeners[event_type]:
            cb.call(data)
```

Three methods. `on` appends a callable to a per-event array. `off` removes it. `emit` iterates the array and calls each one with the data dictionary. No signals, no inheritance required.

### `scripts/main.gd` — Wiring Systems

In `_ready()`, four independent systems subscribe to two events:

```gdscript
_bus.on("enemy_died", _score_system)
_bus.on("enemy_died", _xp_system)
_bus.on("enemy_died", _ui_system)
_bus.on("enemy_died", _audio_system)
_bus.on("level_up",   _level_system)
_bus.on("level_up",   _ui_system)
_bus.on("level_up",   _audio_system)
_bus.on("score_changed", _ui_system)
```

When the player clicks an enemy, a single emit triggers all four handlers:

```gdscript
_bus.emit("enemy_died", {
    "id": enemy["id"],
    "pos": enemy["pos"],
    "xp": enemy["xp"],
})
```

### Cascading Events

The XP system can trigger a level-up event from inside an `"enemy_died"` handler:

```gdscript
func _xp_system(data: Dictionary) -> void:
    _xp += data.get("xp", 10)
    while _xp >= _xp_to_next:
        _xp -= _xp_to_next
        _level += 1
        _xp_to_next = int(_xp_to_next * 1.5)
        _bus.emit("level_up", {"level": _level})
```

`_bus.emit("level_up", ...)` fires synchronously inside the `"enemy_died"` dispatch loop. The level and audio systems respond to it before `"enemy_died"` finishes dispatching to its remaining subscribers. This is powerful but requires care — avoid circular cascades.

### Dictionary-Based Payloads

Subscribers read fields with `data.get("key", default)`, which is resilient to schema changes:

```gdscript
func _score_system(data: Dictionary) -> void:
    var xp_val: int = data.get("xp", 10)
    var pts := xp_val * 10
    _score += pts
    _bus.emit("score_changed", {"score": _score, "delta": pts})
```

Adding a new field to an event doesn't break existing subscribers. Removing one only breaks subscribers that used it.

## The Typed Event Bus Pattern

### Comparison to Godot's Native Signals

| | Godot Signals | Event Bus |
|---|---|---|
| Type safety | Strongly typed at declaration | String keys + Dictionary |
| Cross-scene | Requires `get_node` or Autoload | Bus is always available |
| Subscriber discovery | `signal.connect(...)` in code | `bus.on("event", ...)` in code |
| Circular reference risk | Source must hold target ref | Neither side references the other |
| Best for | Known, close relationships | Distant or dynamic systems |

### String Keys vs Enum Keys

Using string keys (`"enemy_died"`) makes the bus universally accessible without importing a shared enum. The trade-off is that typos in event names silently produce no-op emissions. A common mitigation is to define event name constants:

```gdscript
# In event_bus.gd or a shared constants file:
const ENEMY_DIED    := "enemy_died"
const LEVEL_UP      := "level_up"
const SCORE_CHANGED := "score_changed"
```

### Preventing Memory Leaks

Always call `bus.off(event_type, callback)` in the `_exit_tree()` of any node that subscribed. If a node is freed while still subscribed, the bus holds a reference to a dead callable and will crash when it tries to call it. A cleaner pattern is to connect only from Autoloads or long-lived managers that outlast any individual scene node.

## How to Adapt This in Your Project

1. Make `EventBus` an Autoload so all scenes share one bus without manual wiring.
2. Add event name constants to avoid string typos.
3. Call `bus.off()` from `_exit_tree()` in any node that subscribes.
4. For large games, consider domain-specific buses (`CombatBus`, `UiBus`) to group related events and limit blast radius.
5. Add an `emit_deferred` method using `call_deferred` if you need to defer dispatch past the current frame.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Dictionary.get(key, default)` | Safe field access with fallback |
| `Array.erase(value)` | Remove first occurrence from an array |
| `Callable` | First-class function reference storable in data structures |
| `Callable.call(args)` | Invoke a stored method reference |

## Controls

| Input | Action |
|-------|--------|
| Left-click on an enemy | Kill enemy and fire `"enemy_died"` event |

## Files

| File | Purpose |
|------|---------|
| `scripts/event_bus.gd` | `EventBus` class: `on`, `off`, `emit` |
| `scripts/main.gd` | System handlers, enemy data, rendering, log panels |
| `scenes/main.tscn` | Single Node2D scene |
| `tests/test_logic.gd` | Unit tests for subscribe, unsubscribe, emit, cascade |

## Use as a building block

**Copy:** `scripts/event_bus.gd` — the `EventBus` type. `scripts/main.gd` is the demo driver (it builds the scene and draws the visualisation) and is not needed.

**`EventBus` API**
- `on(event_type: String, callback: Callable) -> void`
- `off(event_type: String, callback: Callable) -> void`
- `emit(event_type: String, data: Dictionary = {}) -> void`

**Notes**
- `class_name EventBus` is global to the project — rename it if you already define that type.

## Related demos

- [event-bus](../event-bus) — An Autoload event bus so nodes broadcast/listen without direct references.
- [object-factory](../object-factory) — The factory pattern: a type registry decoupling creation from callers.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

