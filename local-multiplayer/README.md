# Local Multiplayer

Demonstrates two-player local multiplayer on the same keyboard by assigning different input schemes to different player instances via `@export var player_id`.

## Purpose

Local multiplayer (couch co-op or versus) is one of the simplest multiplayer forms to implement in Godot: no networking required, just two separate input sources. The key design challenge is giving each player its own input bindings without duplicating the movement logic. This demo uses a single `player.gd` script with an exported `player_id` that selects the input method at runtime.

## Controls

- **Player 1 (blue hat)**: W/A/S/D keys
- **Player 2 (orange hat)**: Arrow keys
- Collect gold coins to score points; all coins are shared between players

## How It Works

### Node Tree

```
Main (Node2D)              ← main.gd
├── Player1 (CharacterBody2D)  ← player.gd  [player_id=1, blue]
├── Player2 (CharacterBody2D)  ← player.gd  [player_id=2, orange]
├── Coins (Node2D)
│   └── (Area2D ×10, spawned at runtime)
└── ScoreLabel (Label)
```

### `scripts/player.gd`

```gdscript
@export var player_id    := 1
@export var player_color := Color.CORNFLOWER_BLUE

func _get_dir() -> Vector2:
    if player_id == 1:
        return Vector2(
            float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
            float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
        )
    return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
```

The same script powers both players. The `player_id` and `player_color` exports are set per-instance in the scene editor. Player 1 reads raw key states directly; Player 2 uses the default action map (which maps to arrow keys).

**Why raw key polling for Player 1?**

Godot's default `ui_left`, `ui_right`, etc. actions are mapped to arrow keys. Two players cannot share the same actions. Player 1 uses `Input.is_key_pressed(KEY_W)` etc. to read WASD directly, bypassing the action map. Player 2 uses the default action map (arrow keys). A production game would create separate `Input Map` actions (`p1_left`, `p2_left`) but direct key polling demonstrates the concept simply.

### `scripts/coin.gd`

```gdscript
extends Area2D
signal collected(player_id: int)

func _ready() -> void:
    body_entered.connect(func(body: Node2D):
        if "player_id" in body:
            collected.emit(body.player_id)
            queue_free())
```

The coin checks `"player_id" in body` before emitting, ensuring only actual player nodes trigger collection. `body.player_id` reads the value from the colliding body and passes it to the signal, so `main.gd` knows which player scored.

### `scripts/main.gd`

Creates coins at hardcoded positions, spawning each as a dynamic `Area2D` with a `CollisionShape2D` added programmatically. Connects `coin.collected` to `_on_collected(pid)`:

```gdscript
func _on_collected(pid: int) -> void:
    scores[pid - 1] += 1
    _refresh()
    if coins_node.get_child_count() == 0:
        score_label.text += "  — All collected!"
```

`scores` is a two-element array indexed by `pid - 1` (since pid is 1 or 2).

## Design Theory

### @export for Per-Instance Configuration

The same script with `@export var player_id := 1` placed on two nodes gives each node an independent configuration. This is preferable to having `player1.gd` and `player2.gd` with duplicate code.

### duck-typing Input Check

```gdscript
if "player_id" in body:
```

GDScript's `in` operator checks if an object has a property by name. This is **duck typing**: rather than checking `body is PlayerCharacter`, we check that the body has the property we need. This means any node with a `player_id` property would work — useful for extensibility.

The alternative (`body is CharacterBody2D`) would miss the specific player type check, and `body == $Player1` would hardcode a scene reference.

### Splitting Input Between Players

In games with many players or configurable controls, the Input Map approach scales better:
1. Add actions `p1_left`, `p1_right`, `p1_up`, `p1_down`, `p2_left`, etc. in Project Settings
2. Map them to different keys
3. Player 1 calls `Input.get_vector("p1_left", "p1_right", ...)`, Player 2 calls `Input.get_vector("p2_left", "p2_right", ...)`

This enables remapping without changing code and supports gamepad assignments per player.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `@export var player_id := 1` | Per-instance configuration in Inspector |
| `Input.is_key_pressed(KEY_W)` | Poll a specific physical key |
| `Input.get_vector(neg_x, pos_x, neg_y, pos_y)` | Normalized directional input |
| `"property_name" in object` | Duck-type property check |
| `signal collected(player_id: int)` | Typed signal with argument |
| `Area2D.body_entered` | Physics body contact detection |
