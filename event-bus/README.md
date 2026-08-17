# Event Bus

Implements the Event Bus (or Message Broker) pattern: a globally-accessible Autoload that holds signals, allowing any node to broadcast or listen without direct references between senders and receivers.

## Purpose

As games grow, nodes need to communicate across scene boundaries without being aware of each other. Direct signal connections require one node to hold a reference to another — impossible when they live in different scenes. The Event Bus places signals on a shared Autoload so any node can emit or connect without knowing who else is listening.

## Controls

- **Arrow keys**: Move the player
- **Space / Enter** (`ui_accept`): Trigger `player_hurt` event (−10 HP)
- **Shift**: Trigger `player_healed` event (+10 HP)
- Walk over gold circles to collect them (triggers `item_collected`)

## How It Works

### Node Tree

```
Main (Node2D)              ← main.gd  (listens to all events, shows log)
├── Player (CharacterBody2D) ← player.gd  (emits hurt/heal events)
├── Coins (Node2D)
│   └── (Area2D ×6, created at runtime)
└── LogLabel (Label)

[Autoload] EventBus       ← event_bus.gd
```

### `scripts/event_bus.gd` — The Bus

```gdscript
extends Node
signal item_collected(item_name: String)
signal player_hurt(damage: int)
signal player_healed(amount: int)
signal enemy_died(enemy_name: String)
```

Nothing else. The bus has no logic — it is only a signal registry. Every signal is typed so callers know what arguments to pass.

### Project Configuration

```
[autoload]
EventBus="*res://scripts/event_bus.gd"
```

`EventBus` is accessible by name from any script in any scene.

### `scripts/player.gd` — Emitter

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_just_pressed("ui_accept"):
        EventBus.player_hurt.emit(10)
```

The player never imports `main.gd` or `score_manager.gd`. It only knows about `EventBus`.

### `scripts/main.gd` — Listener

```gdscript
func _ready() -> void:
    EventBus.item_collected.connect(func(name): _log("[item_collected] " + name))
    EventBus.player_hurt.connect(func(dmg): _log("[player_hurt] -%d HP" % dmg))
    EventBus.player_healed.connect(func(amt): _log("[player_healed] +%d HP" % amt))
    EventBus.enemy_died.connect(func(name): _log("[enemy_died] " + name))
```

Main connects to all events and logs them in a rolling history. Main does not know about `player.gd`'s implementation, and `player.gd` does not know about `main.gd`.

### Coin Spawning

Coins are created entirely at runtime to demonstrate that dynamically spawned nodes can also use the bus:

```gdscript
coin.body_entered.connect(func(_b):
    EventBus.item_collected.emit("Gold Coin")
    coin.queue_free())
```

## Event Bus Theory

### The Problem It Solves

Standard signal connections require a reference to the source node:
```gdscript
$Player.hurt.connect($HUD._on_player_hurt)
```
This breaks when Player and HUD live in different scenes loaded at different times. One workaround is to use `get_tree().get_first_node_in_group("player")`, but this couples the HUD to the game's node naming conventions.

### How the Event Bus Decouples Nodes

With an Event Bus:
- The Player emits `EventBus.player_hurt.emit(10)` — no reference to any listener needed.
- The HUD connects `EventBus.player_hurt.connect(...)` — no reference to the Player needed.

Both sides only reference `EventBus`, which is always available as an Autoload. Nodes can be loaded, unloaded, or replaced without breaking each other's connections.

### Trade-offs

**Advantages:**
- Complete decoupling between emitter and listener
- Works across scene boundaries
- Easy to add new listeners without modifying emitters

**Disadvantages:**
- Harder to trace signal flow (no direct `source.signal.connect(target.method)` to follow)
- Type safety depends on documentation — any node can emit any event
- Can become a "god object" if too many unrelated signals pile up

A common mitigation is to split signals into domain-specific buses (`CombatBus`, `UiBus`) instead of one global bus.

### Comparison to Direct Signals

| | Direct Signal | Event Bus |
|---|---|---|
| Coupling | Source holds reference to target | Neither holds reference to the other |
| Cross-scene | Requires careful timing | Always works |
| Traceability | Explicit connection in code | Implicit — must search for `.emit()` calls |
| Best for | Close, known relationships | Distant or dynamic relationships |

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `[autoload]` in project.godot | Global node accessible by name |
| `signal name(arg: Type)` | Typed signal declaration |
| `EventBus.signal_name.emit(value)` | Fire the signal |
| `EventBus.signal_name.connect(callable)` | Register a listener |

## Files

| File | What it holds |
|------|---------------|
| `scripts/event_bus.gd` | `event bus` behaviour |
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/event_bus.gd`, `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/event_bus.gd`**
- signal `item_collected(item_name: String)`
- signal `player_hurt(damage: int)`
- signal `player_healed(amount: int)`
- signal `enemy_died(enemy_name: String)`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- `EventBus` is registered as an autoload (Project Settings → Globals). Copy the autoload script and register it there under a name that does not collide with anything in your project.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [autoload-score](../autoload-score) — The Autoload/Singleton pattern: global state that emits change signals.
- [typed-event-bus](../typed-event-bus) — A pub/sub bus with string-keyed events carrying typed `Dictionary` payloads.
- [coin-collector](../coin-collector) — Scene instancing, custom signals, and `Area2D` pickups for a collect-all goal.
- [cooldown-shoot](../cooldown-shoot) — Projectile instantiation with a cooldown timer and `ProgressBar` indicator.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

