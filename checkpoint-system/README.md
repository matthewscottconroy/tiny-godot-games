# Checkpoint System

<!-- tags: physics, ui, signals, component -->

A one-way checkpoint system for a platformer: walking through a flag permanently updates the player's respawn position, turning the flag green. Press R to die and respawn at the last reached checkpoint.

## Purpose

Checkpoints are a fundamental game design tool for managing player frustration. Without them, a long level becomes a punishment loop — every mistake sends the player back to the very start. By placing checkpoints at meaningful milestones you let players bank their progress, turning failure into a learning opportunity rather than a time tax.

Real-world examples are everywhere: the flags in *Super Mario Bros.* midpoints, the benches in *Hollow Knight*, the bonfires in *Dark Souls*, the doors in *Celeste*. All of these share the same mechanical core: a trigger zone, a one-time activation, and a stored respawn position. This demo implements that core in ~80 lines of GDScript.

The "one-way, one-shot" constraint is the key design decision. Checkpoints that can be re-triggered or un-triggered introduce edge cases — what happens if the player re-enters a checkpoint from a later point in the level? The `_activated` flag enforces the rule cleanly.

## How It Works

### Node Tree

```
Main (Node2D)               ← main.gd
├── Player (CharacterBody2D) ← player.gd
├── Checkpoint (Area2D ×3)  ← checkpoint.gd (each with checkpoint_id 0/1/2)
└── StaticBody2D (floor + platforms)
```

### `scripts/checkpoint.gd` — The Flag

Each checkpoint is an `Area2D` with a one-shot signal:

```gdscript
class_name Checkpoint
extends Area2D

@export var checkpoint_id: int = 0
var _activated := false
signal activated(id: int)

func _on_body_entered(body: Node2D) -> void:
    if _activated:
        return
    if body.is_in_group("player"):
        _activated = true
        activated.emit(checkpoint_id)
        queue_redraw()
```

The guard `if _activated: return` is the entire one-shot mechanic. After the first trigger the signal never fires again, and `queue_redraw()` redraws the flag green.

### `scripts/main.gd` — Wiring Checkpoints to the Player

`main.gd` connects every checkpoint's signal at startup:

```gdscript
func _ready() -> void:
    for cp in get_tree().get_nodes_in_group("checkpoint"):
        cp.activated.connect(_on_checkpoint.bind(cp))

func _on_checkpoint(cp: Area2D) -> void:
    _player.set_checkpoint(cp.global_position + Vector2(0, -30))
```

`signal.bind(cp)` passes the checkpoint node as an extra argument so the handler knows which node activated. The spawn position is offset 30 pixels upward so the player respawns above the flag base, not inside it.

### `scripts/player.gd` — Spawn Point Storage

The player stores its current respawn position and applies it on R:

```gdscript
var _spawn_point: Vector2

func _ready() -> void:
    _spawn_point = global_position   # initial spawn

func set_checkpoint(pos: Vector2) -> void:
    _spawn_point = pos

func respawn() -> void:
    global_position = _spawn_point
    velocity = Vector2.ZERO
```

`velocity = Vector2.ZERO` on respawn is easy to miss but important: without it the player carries their death velocity into the new spawn, which can immediately knock them off the platform.

## The Checkpoint Pattern

### One-Shot Signals

The `_activated` boolean is the canonical guard for one-shot behavior. An alternative is to disconnect the signal after the first trigger:

```gdscript
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        activated.emit(checkpoint_id)
        body_entered.disconnect(_on_body_entered)
```

The boolean flag approach is preferred here because it also controls the visual state (`_draw()` reads `_activated` to pick the flag color), so the flag and the trigger share one source of truth.

### Group-Based Discovery

`get_tree().get_nodes_in_group("checkpoint")` lets `main.gd` connect all checkpoints without knowing how many there are or where they live in the tree. Adding a new checkpoint to the scene requires only placing the node and adding it to the `"checkpoint"` group — no code changes.

### Save/Load Integration

In a real game, checkpoint state persists across sessions. The `checkpoint_id` export variable exists for this: serialize a set of activated IDs to disk, and on load, re-activate the matching checkpoints without triggering their signals again (call `_activated = true` and `queue_redraw()` directly).

## How to Adapt This in Your Project

1. Give every checkpoint node a unique `checkpoint_id` — sequential integers work fine.
2. Add checkpoints to the `"checkpoint"` group in the editor.
3. In your main/level script, use the group discovery pattern to connect signals.
4. Store the current checkpoint in a save file using `FileAccess` or a `Resource`.
5. On scene load, find the matching checkpoint by ID and call `player.set_checkpoint()` before the first frame.
6. For richer feedback, tween a visual effect (color flash, particle burst) inside `checkpoint.gd` when `_activated` becomes true.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Area2D.body_entered` | Signal fires when a physics body enters the area's collision shape |
| `signal activated(id: int)` | Typed signal emitted exactly once per checkpoint |
| `Callable.bind(value)` | Partially applies an extra argument to a signal connection |
| `get_tree().get_nodes_in_group(name)` | Returns all nodes in a named group |
| `add_to_group(name)` | Registers a node so group queries can find it |
| `queue_redraw()` | Marks a node dirty so `_draw()` runs again next frame |

## Controls

| Key | Action |
|-----|--------|
| Arrow keys | Move and jump |
| R | Respawn at last checkpoint |

## Key Constants

```gdscript
# In player.gd:
const SPEED    := 200.0   # horizontal movement speed (px/s)
const JUMP_VEL := -400.0  # initial vertical velocity on jump
const GRAVITY  := 900.0   # downward acceleration (px/s²)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/checkpoint.gd` | One-shot Area2D: activation guard, signal, flag drawing |
| `scripts/player.gd` | Movement, jump, spawn-point storage and respawn |
| `scripts/main.gd` | Connects all checkpoint signals, draws terrain |
| `scenes/main.tscn` | Player, three checkpoints, floor, two platforms |
| `tests/test_logic.gd` | Unit tests for spawn/respawn logic |

## Use as a building block

**Copy:** `scripts/checkpoint.gd` — the `Checkpoint` type. `scripts/main.gd` is the demo driver (it builds the scene and draws the visualisation) and is not needed.

**`Checkpoint` API**
- `@export checkpoint_id: int`
- signal `activated(id: int)`

**Notes**
- `class_name Checkpoint` is global to the project — rename it if you already define that type.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [camera-deadzone](../camera-deadzone) — Camera stays still until the player exits a rectangular dead zone, then catches up.
- [save-load](../save-load) — Persist structured game state to JSON in the user data dir, across sessions.
- [boid-flocking](../boid-flocking) — 35 agents flock via separation, alignment, and cohesion — emergent behavior.
- [noise-terrain](../noise-terrain) — 1D terrain from `get_noise_1d()`, redrawing live as you tune parameters.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

