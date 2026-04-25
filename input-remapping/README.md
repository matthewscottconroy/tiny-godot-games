# Input Remapping

Demonstrates how to modify `InputMap` at runtime — letting players rebind keyboard actions by pressing a new key while the game is listening.

## Purpose

Configurable controls are expected in every serious game. Godot's `InputMap` singleton makes this straightforward: you can erase existing events for an action and add new ones at any time. This demo shows the full pattern: displaying current bindings, entering "listening" mode, capturing the next key press, and applying the remap.

## Controls

- **Click a binding row**: Enter listening mode for that action (button turns gold)
- **Press any key**: Rebind that action to the pressed key
- **Reset button**: Restore all bindings to defaults
- **Arrow/WASD** (remappable): Move the player square at the bottom

## How It Works

### Node Tree

```
Main (Node2D)                  ← main.gd
├── BindingContainer (VBox)    ← one row per action
│   └── [HBoxContainer rows]
│       ├── ActionLabel
│       └── KeyButton
└── ResetButton
```

### `scripts/main.gd`

- **`ACTIONS`** — Array of action name strings (e.g. `"ui_left"`, `"ui_accept"`). These are the built-in Godot actions that come pre-configured.
- **`DEFAULTS`** — Dictionary mapping action name → Key constant (e.g. `KEY_LEFT`). Used by the Reset button.
- **`_start_listen(action)`** — Sets `_listening_for` to the action name and highlights the button gold. All subsequent unhandled key events are captured.
- **`_unhandled_input(event)`** — If `_listening_for != ""` and a `InputEventKey` is pressed, calls `_remap(action, event)`.
- **`_remap(action, event)`** — Calls `InputMap.action_erase_events(action)`, then `InputMap.action_add_event(action, event)`. Updates the button text to show the new key name.

### Why `_unhandled_input`?

Using `_unhandled_input` instead of `_input` ensures the key capture only triggers if no other node consumed the event first. This prevents capturing keys that are already handled by the UI (e.g. clicking the Reset button shouldn't also remap an action).

### Displaying Key Names

```gdscript
OS.get_keycode_string(event.physical_keycode)
```

`physical_keycode` is layout-independent (QWERTY `A` and AZERTY `A` both return the same physical key). `keycode` is layout-dependent (the actual character). For remapping, physical keycode is usually correct.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `InputMap.action_erase_events(action)` | Remove all events for an action |
| `InputMap.action_add_event(action, event)` | Add a new event to an action |
| `InputMap.action_get_events(action)` | Read current events for an action |
| `InputEventKey.physical_keycode` | Layout-independent key identifier |
| `OS.get_keycode_string(keycode)` | Human-readable key name |
| `Input.is_action_pressed(action)` | Works with remapped bindings automatically |
