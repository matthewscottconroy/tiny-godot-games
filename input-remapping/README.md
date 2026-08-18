# Input Remapping

<!-- tags: ui -->

Runtime key rebinding using Godot's `InputMap` singleton. Click any action row to enter listening mode, press a new key, and the binding updates immediately. The player square at the bottom moves with the remapped keys.

## Purpose

Configurable controls are an accessibility and quality-of-life expectation in every serious game. Left-handed players need to remap WASD. Players with non-standard keyboards can't use default shortcuts. Players who've internalized one game's controls want to match them in yours. A game that doesn't offer remapping will receive complaints; one that does earns goodwill.

Godot's `InputMap` makes runtime rebinding straightforward because all `Input.is_action_*` checks go through `InputMap` every frame. Modifying `InputMap` at runtime automatically changes what `Input.is_action_pressed("ui_left")` returns — no code needs to change elsewhere. This demo shows the complete pattern: displaying current bindings, entering listening mode, capturing the keypress, and persisting defaults for reset.

## How It Works

### Node Tree

```
Main (Node2D)                  ← main.gd
├── BindingContainer (VBox)    ← rows built dynamically in _ready()
│   └── [HBoxContainer ×5]
│       ├── Label (action name)
│       └── Button (current key)
└── ResetBtn
```

### Building Rows at Startup

`_build_row(action)` creates one `HBoxContainer` per action with a label and a button. The button's `pressed` signal calls `_start_listen(action)` with the action name bound via closure:

```gdscript
func _build_row(action: String) -> void:
    var key_btn := Button.new()
    key_btn.pressed.connect(func(): _start_listen(action))
    container.add_child(row)
    _rows[action] = key_btn   # store reference for later updates
```

The `_rows` dictionary maps action name strings to their button nodes, so `_refresh_all()` can update button text without searching the scene tree.

### Listen → Capture → Remap

Entering listen mode highlights the button gold and sets `_listening_for`:

```gdscript
func _start_listen(action: String) -> void:
    _listening_for = action
    _rows[action].text = "[ press a key… ]"
    _rows[action].modulate = Color.GOLD
```

`_unhandled_input` captures the next key press:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if _listening_for.is_empty():
        return
    if event is InputEventKey and event.pressed and not event.echo:
        _remap(_listening_for, event.keycode)
        _listening_for = ""
```

`_unhandled_input` (not `_input`) is used so key events consumed by other nodes — such as a button receiving focus — don't accidentally trigger a remap.

### Applying the Remap

```gdscript
func _remap(action: String, keycode: Key) -> void:
    InputMap.action_erase_events(action)
    var ev        := InputEventKey.new()
    ev.keycode     = keycode
    InputMap.action_add_event(action, ev)
    _refresh_all()
```

`action_erase_events` removes all existing events for the action (keyboard, mouse, gamepad). `action_add_event` adds the new one. After this, any `Input.is_action_pressed("ui_left")` call anywhere in the project will use the new binding.

### Resetting to Defaults

`DEFAULTS` stores the original key constants:

```gdscript
const DEFAULTS := {
    "ui_left":   KEY_LEFT,
    "ui_right":  KEY_RIGHT,
    "ui_up":     KEY_UP,
    "ui_down":   KEY_DOWN,
    "ui_accept": KEY_SPACE,
}
```

`_reset_all()` iterates `DEFAULTS`, erases events, and restores the original `InputEventKey` for each action.

### Displaying Current Bindings

`_refresh_all()` reads back the current events from `InputMap` and formats them as text:

```gdscript
var events := InputMap.action_get_events(action)
var names  := events.map(func(e): return e.as_text() if e is InputEventKey else str(e))
_rows[action].text = ", ".join(names)
```

`InputEventKey.as_text()` returns a human-readable string like `"Left"` or `"Ctrl+Z"`. Using `as_text()` rather than a manual keycode lookup handles modifier keys automatically.

## The InputMap Pattern

### Runtime vs. Project Settings

Actions defined in `Project > Project Settings > Input Map` are loaded into `InputMap` at startup. Runtime modifications via `InputMap.action_erase_events()` and `InputMap.action_add_event()` are in-memory changes — they do not persist across sessions. To save remappings, serialize the current bindings to a config file on quit and reload them on start.

### Persisting Remaps with ConfigFile

```gdscript
# Save
var cfg := ConfigFile.new()
for action in ACTIONS:
    var events := InputMap.action_get_events(action)
    cfg.set_value("bindings", action, events[0].keycode if events else DEFAULTS[action])
cfg.save("user://controls.cfg")

# Load
cfg.load("user://controls.cfg")
for action in ACTIONS:
    var keycode: Key = cfg.get_value("bindings", action, DEFAULTS[action])
    _remap(action, keycode)
```

### Physical vs. Logical Keycodes

`event.keycode` returns the logical character for the pressed key (layout-dependent). `event.physical_keycode` returns the hardware key position (layout-independent). For movement remapping, `physical_keycode` is usually better: WASD maps to the same physical positions on QWERTY, AZERTY, and QWERTZ keyboards. For text-based commands, `keycode` is appropriate.

This demo uses `keycode` for simplicity — replace with `physical_keycode` if targeting international players.

## How to Adapt This in Your Project

1. Load saved bindings from `user://controls.cfg` in `_ready()` before calling `_refresh_all()`.
2. Save bindings to the config file in `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` or from a settings screen "Apply" button.
3. Add gamepad support: check for `InputEventJoypadButton` alongside `InputEventKey` in `_unhandled_input`.
4. Display the default key in the button label in a lighter color so players know what to reset to.
5. Add a confirmation step before applying a remap that would conflict with another action.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `InputMap.action_erase_events(action)` | Remove all events bound to an action |
| `InputMap.action_add_event(action, event)` | Bind a new event to an action |
| `InputMap.action_get_events(action)` | Read the current event list for an action |
| `InputEventKey.keycode` | Layout-dependent key identifier |
| `InputEventKey.physical_keycode` | Layout-independent key position |
| `InputEventKey.as_text()` | Human-readable key name string |
| `Node._unhandled_input(event)` | Receives events not consumed by other nodes |
| `Input.get_vector(neg_x, pos_x, neg_y, pos_y)` | 2D axis from four actions |

## Controls

| Input | Action |
|-------|--------|
| Click any binding row | Enter listen mode for that action |
| Press any key | Bind that key to the selected action |
| Reset button | Restore all bindings to defaults |
| Remapped arrow keys | Move the player square |

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Row construction, listen mode, remap logic, player movement |
| `scenes/main.tscn` | Node2D with VBox container and Reset button |
| `tests/test_logic.gd` | Tests for remap application, reset, and display refresh |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [accessibility-options](../accessibility-options) — Colourblind-safe palettes, reduced motion, text scaling, and shape cues.
- [settings-menu](../settings-menu) — A settings panel with volume slider, fullscreen toggle, and player color.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

