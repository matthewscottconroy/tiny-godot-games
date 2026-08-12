# Interaction System

A reusable "press E to interact" system using Area2D proximity detection. The player automatically sees prompts when near interactable objects and can trigger them without explicit raycast logic.

## Purpose

Most games need a consistent way to interact with objects — chests, signs, doors, NPCs. A common mistake is hard-coding interaction per-object with raycasts or distance checks. This demo shows the cleaner approach: each interactable object owns a detection Area2D, manages its own prompt visibility, and exposes a single `interact()` method. The player just calls that method when the player presses the interact key. Adding a new interactable object requires zero changes to the player.

## Controls

- **Arrow keys**: Move left and right, Up to jump
- **Space / Enter**: Interact with nearby object
- Walk near the chest, sign, or door and watch the prompt appear

## How It Works

### Node Tree

```
Chest (Area2D)                ← interactable.gd
├── CollisionShape2D          ← detection radius
├── Prompt (Label)            ← "[E] Open Chest"
└── ResponseLabel (Label)     ← shown after interacting
```

### `scripts/interactable.gd`

The interactable owns all interaction state. When a body enters the detection Area2D:
```gdscript
func _on_enter(body: Node) -> void:
    if body.is_in_group("player"):
        body.set_nearby(self)   # tells player "I'm the active interactable"
        _prompt.visible = true
```

When the body exits:
```gdscript
func _on_exit(body: Node) -> void:
    if body.is_in_group("player"):
        body.set_nearby(null)
        _prompt.visible = false
```

### `scripts/player.gd`

The player holds a reference to the nearest interactable and calls it on key press:
```gdscript
var _nearby: Interactable = null

func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        if _nearby:
            _nearby.interact()

func set_nearby(i: Interactable) -> void:
    _nearby = i
```

The player doesn't care what `interact()` does — it's the interactable's responsibility to respond.

## Design Decisions

### Area2D over Raycast

A raycast fires in one direction from the player. To interact with a chest to the left, the player has to face left. Area2D proximity has no directional requirement — walk into range from any direction.

### Interactable Owns the Prompt

The prompt Label is a child of the Interactable, not the player's HUD. This means each object can have its own prompt text and position without any central UI manager.

### `set_nearby` vs Signal

The player calls `set_nearby(self)` on the player directly. An alternative is to use signals: interactable emits `player_entered` and some manager listens. The direct reference is simpler for a single-player game. If you need multiple interactables at once (priorities, queuing), switch to signals.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Area2D.body_entered` | Signal fired when a PhysicsBody enters the area |
| `Area2D.body_exited` | Signal fired when a PhysicsBody leaves the area |
| `Node.is_in_group(name)` | Check if a node belongs to a named group |
| `Node.add_to_group(name)` | Add a node to a group (done in player `_ready`) |
| `Input.is_action_just_pressed(a)` | Edge-triggered action check |

## Files

| File | What it holds |
|------|---------------|
| `scripts/interactable.gd` | The `Interactable` component |
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/interactable.gd` — the `Interactable` type. `scripts/main.gd` is the demo driver (it builds the scene and draws the visualisation) and is not needed.

**`Interactable` API**
- `@export label_text  :`
- `@export response    :`
- `@export icon_color  :`
- `interact() -> void`

**Notes**
- `class_name Interactable` is global to the project — rename it if you already define that type.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.
