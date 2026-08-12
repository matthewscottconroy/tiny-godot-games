# Area Trigger

Demonstrates how `Area2D` nodes act as invisible trigger zones that fire signals when a physics body enters or exits them.

## Purpose

Area triggers are one of the most fundamental tools in game design: spawn zones, damage fields, win conditions, dialogue activation, sound triggers, and checkpoint systems all depend on this pattern. Understanding `Area2D` and its `body_entered` / `body_exited` signals is a prerequisite for almost any non-trivial Godot project.

## Controls

- **Arrow keys**: Move the player through the colored zones
- Watch the status label change color and text as you enter each zone

## How It Works

### Node Tree

```
Main (Node2D)               ← main.gd
├── Zones (Node2D)
│   ├── SafeZone (Area2D)   ← CollisionShape2D inside
│   ├── DangerZone (Area2D)
│   └── WinZone (Area2D)
├── Player (CharacterBody2D) ← player.gd
└── StatusLabel (Label)
```

### `scripts/main.gd`

Sets up all signal connections and draws the zone outlines visually.

- **`_ready()`** — Connects `body_entered` and `body_exited` on each of the three `Area2D` nodes to lambda functions that call `_set_status()`. Lambdas are used here to pass the zone's specific text and color without needing separate handler methods.
- **`_set_status(text, color)`** — Updates `StatusLabel.text` and `StatusLabel.modulate` to reflect which zone the player is in. When the player exits a zone without entering another, it resets to `"—"`.
- **`_draw()`** — Draws filled semi-transparent rectangles and solid outlines matching each zone's shape and position. Since `Area2D` nodes have no built-in visual, this makes the zones visible during play without needing sprites.

### `scripts/player.gd`

A standard top-down `CharacterBody2D`. Uses `Input.get_vector()` for 8-directional movement and `move_and_slide()` for collision.

## Area2D Theory

### What Area2D Does

`Area2D` is a non-physics body — it does not push or block other objects. Instead it monitors an overlapping region and emits signals when physics bodies (or other areas) enter or leave. Internally, Godot's physics server tracks which shapes overlap each frame.

### body_entered vs body_exited

- `body_entered(body: Node2D)` fires once when a `PhysicsBody2D` (e.g. `CharacterBody2D`, `RigidBody2D`) first overlaps the area's collision shape.
- `body_exited(body: Node2D)` fires once when the body stops overlapping.

These are **edge signals** — they fire exactly once per transition, not every frame. This is critical: you do not need to poll overlap every `_process()` tick.

### Collision Layers and Masks

`Area2D` only detects bodies on its **collision mask** layers. In this demo all nodes use the default layer/mask (layer 1), so everything detects everything. In a real game you would:
- Put enemies on layer 2, player on layer 1
- Set the damage zone's mask to include layer 1 (player) only
- This prevents enemies from accidentally triggering player-only zones

### Lambda Connections

```gdscript
$Zones/SafeZone.body_entered.connect(func(_b): _set_status("SAFE ZONE", Color.SEA_GREEN))
```

The body argument `_b` is prefixed with `_` to signal it is intentionally unused. The underscore prefix suppresses the GDScript "unused variable" warning.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Area2D.body_entered` | Signal — fired when a PhysicsBody2D enters |
| `Area2D.body_exited` | Signal — fired when a PhysicsBody2D exits |
| `Area2D.monitoring` | Enable/disable overlap detection |
| `signal.connect(callable)` | Attach a handler; callable can be a lambda |
| `Input.get_vector(neg_x, pos_x, neg_y, pos_y)` | Normalized 2D input from 4 actions |
| `move_and_slide()` | Move with collision response |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

