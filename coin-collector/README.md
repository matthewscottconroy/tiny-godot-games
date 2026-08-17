# Coin Collector

Demonstrates scene instancing, custom signals, and Area2D pickup detection to implement a simple collect-all objective.

## Purpose

A coin pickup system is a recurring pattern in nearly every game genre. This demo shows how to use a custom signal on the collectible (rather than checking collisions in a manager) to decouple the coin's behavior from the score system. It also shows how to count pre-placed children and track completion.

## Controls

- **Arrow keys**: Move the player

## How It Works

### Node Tree

```
Main (Node2D)               ← main.gd
├── Coins (Node2D)
│   ├── Coin (Area2D)       ← coin.gd  (×N, pre-placed in editor)
│   └── ...
├── Player (CharacterBody2D) ← player.gd
└── ScoreLabel (Label)
```

### `scripts/coin.gd` — Area2D

```gdscript
extends Area2D
signal collected

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    queue_redraw()

func _on_body_entered(_body: Node2D) -> void:
    collected.emit()
    queue_free()
```

Each coin:
1. Declares a custom `collected` signal.
2. In `_ready()`, connects `body_entered` (fired by the physics engine when a `PhysicsBody2D` overlaps) to a local handler.
3. When any body enters, emits `collected` then calls `queue_free()` to remove itself.

The coin does not care who collected it or what the score is. It only announces that it was collected and deletes itself.

### `scripts/main.gd`

```gdscript
func _ready() -> void:
    total = $Coins.get_child_count()
    for coin in $Coins.get_children():
        coin.collected.connect(_on_coin_collected)
    _update_label()

func _on_coin_collected() -> void:
    score += 1
    _update_label()
```

Main counts the total number of coins before any are collected, then connects every coin's `collected` signal to a shared handler. When all coins are collected (`score == total`), the label announces completion.

### `scripts/player.gd`

Top-down `CharacterBody2D` with `move_and_slide()`. The player needs a `PhysicsBody2D` class (which `CharacterBody2D` is) to trigger `body_entered` on the coin's `Area2D`.

## Design Theory

### Signal Ownership

The `collected` signal belongs to the coin. This is the correct direction: the coin knows when it is collected; the score manager knows how many were collected. Neither needs to know the other's internal structure.

If instead `main.gd` directly detected the collision and then called `coin.queue_free()`, the coin would have no agency and `main.gd` would need to manage both detection and removal — a violation of the single-responsibility principle.

### queue_free() After Emission

`queue_free()` schedules the node for deletion at the end of the current frame — it does not delete immediately. This ensures the signal is fully processed (all connected handlers run) before the coin node disappears. Calling `free()` (immediate) here would be unsafe because connected handlers might still reference the node.

### get_child_count() vs Children Signals

`total = $Coins.get_child_count()` is called in `_ready()` before any coins are collected. After coins start calling `queue_free()`, `get_child_count()` would return a decreasing number. Saving `total` upfront avoids having to track deletions separately.

### Area2D + CharacterBody2D Detection

`Area2D.body_entered` fires when a `PhysicsBody2D` (including `CharacterBody2D`) enters the area's collision shape. The area's collision **mask** must include the physics layer the player is on (both default to layer 1 in this demo).

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `signal collected` | Custom signal on the coin node |
| `Area2D.body_entered` | Fires when a physics body enters |
| `collected.emit()` | Fire the signal to all connected handlers |
| `queue_free()` | Schedule node for end-of-frame deletion |
| `Node.get_child_count()` | Number of direct children |
| `Node.get_children()` | Array of direct child nodes |

## Files

| File | What it holds |
|------|---------------|
| `scripts/coin.gd` | `coin` behaviour |
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/coin.gd`, `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/coin.gd`**
- signal `collected`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [cooldown-shoot](../cooldown-shoot) — Projectile instantiation with a cooldown timer and `ProgressBar` indicator.
- [event-bus](../event-bus) — An Autoload event bus so nodes broadcast/listen without direct references.
- [local-multiplayer](../local-multiplayer) — Two players on one keyboard via per-instance input schemes.
- [destructibles](../destructibles) — Click boxes to shatter them into scattered `RigidBody2D` fragments.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

