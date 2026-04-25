# Pause Menu

Demonstrates Godot's pause system: `get_tree().paused` halts all pausable nodes while a `CanvasLayer` with `PROCESS_MODE_ALWAYS` continues processing, enabling a functional pause menu.

## Purpose

Every game needs a pause function. The naive approach (setting a global variable and checking it everywhere) is error-prone and requires modifying every script. Godot's built-in pause system handles this automatically: one flag pauses the entire scene tree, and you opt specific nodes out using `process_mode`.

## Controls

- **Arrow keys / WASD**: Move the player (not while paused)
- **Escape** (`ui_cancel`): Toggle pause
- **Resume button**: Un-pause
- **Quit button**: Exit the application

## How It Works

### Node Tree

```
Main (Node2D)
├── Player (CharacterBody2D)    ← player.gd  (PROCESS_MODE_PAUSABLE — stops when paused)
├── PauseMenu (CanvasLayer)     ← pause_menu.gd  (PROCESS_MODE_ALWAYS — runs while paused)
│   ├── DimRect (ColorRect)     (dark overlay)
│   └── Panel
│       └── VBox
│           ├── ResumeBtn
│           └── QuitBtn
└── (world geometry)
```

### `scripts/pause_menu.gd`

```gdscript
extends CanvasLayer

func _ready() -> void:
    hide()
    $Panel/VBox/ResumeBtn.pressed.connect(_resume)
    $Panel/VBox/QuitBtn.pressed.connect(get_tree().quit)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_just_pressed("ui_cancel"):
        if get_tree().paused:
            _resume()
        else:
            _pause()

func _pause() -> void:
    get_tree().paused = true
    show()

func _resume() -> void:
    get_tree().paused = false
    hide()
```

The pause menu starts hidden. `_unhandled_input` catches Escape anywhere in the scene (because it is on a `CanvasLayer` which processes input). Toggling the pause state is one line; showing/hiding the menu is the other.

`get_tree().quit` is passed directly as a `Callable` to the button's `pressed` signal connection — no wrapper function needed.

### The `process_mode` Property

Every node has a `process_mode` property:

| Mode | Behavior when tree is paused |
|---|---|
| `PROCESS_MODE_PAUSABLE` (default) | Stops processing |
| `PROCESS_MODE_ALWAYS` | Continues processing |
| `PROCESS_MODE_WHEN_PAUSED` | Only processes when paused |
| `PROCESS_MODE_INHERITED` | Inherits from parent |
| `PROCESS_MODE_DISABLED` | Never processes |

The `PauseMenu` CanvasLayer has `process_mode = PROCESS_MODE_ALWAYS` (value 3 in the `.tscn`), so its `_unhandled_input` and button callbacks fire even when the tree is paused.

### `scripts/player.gd`

Uses `_physics_process(delta)`. Since `CharacterBody2D` has the default `PROCESS_MODE_PAUSABLE`, calling `get_tree().paused = true` automatically stops `_physics_process` from being called. The player freezes mid-air, mid-jump — no extra code required.

### Visual Pause Indicator

A semi-transparent `ColorRect` (`DimRect`) covers the screen inside the `CanvasLayer`, darkening the scene to visually signal the paused state. The pause menu panel appears on top of it.

## Pause Theory

### Why CanvasLayer for the Menu

UI nodes in the game world scene would also pause when `get_tree().paused = true` (if they have the default process mode). The pause menu must remain responsive while paused — using a `CanvasLayer` with `PROCESS_MODE_ALWAYS` is the cleanest way to guarantee this.

### _unhandled_input vs _input

`_unhandled_input` only fires if no other node consumed the event via `_input`. This prevents the pause/unpause from triggering when typing in a text field or when another node already handled the event. For global hotkeys like Escape, `_unhandled_input` is the correct override.

### SceneTree.paused

`get_tree().paused = true` sets the pause flag on the `SceneTree`. This is a global state — there is no per-scene pause. All pausable nodes everywhere in the tree stop. This simplicity is usually correct; for more complex scenarios (pause only a specific sub-scene) you would set `process_mode` on individual subtree roots rather than using the global flag.

### get_tree().quit()

Calling `quit()` immediately exits the application. For production games, you would typically save game state here first. Passing it directly to a signal connection is equivalent to:
```gdscript
QuitBtn.pressed.connect(func(): get_tree().quit())
```

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `get_tree().paused` | Global pause flag |
| `Node.process_mode` | How a node responds to pause |
| `PROCESS_MODE_ALWAYS` | Run even when paused |
| `PROCESS_MODE_PAUSABLE` | Stop when paused (default) |
| `_unhandled_input(event)` | Input not consumed by other nodes |
| `event.is_action_just_pressed(action)` | Edge-triggered input test |
| `get_tree().quit()` | Exit the application |
