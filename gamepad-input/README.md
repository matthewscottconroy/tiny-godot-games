# Gamepad Input

Demonstrates joystick connection detection, analog axis reading with deadzone filtering, button state polling, and vibration — all via Godot's `Input` singleton.

## Purpose

Gamepad support requires handling hardware events that don't exist until a controller is plugged in, reading continuous analog values that need filtering, and triggering force feedback. This demo shows all three: dynamic connection handling, deadzone-cleaned axis display, and the vibration API.

## Controls

- **Connect a gamepad**: The display updates automatically via `joy_connection_changed`
- **Move sticks / press triggers**: See real-time axis values and visual indicators
- **Press any button**: Lights up in the button grid
- **Vibrate button**: Triggers 0.5-second rumble on the connected gamepad

## How It Works

### Node Tree

```
Main (Node2D)          ← main.gd
└── HUD (CanvasLayer)
    ├── ConnectedLabel
    ├── AxisLabel
    ├── ButtonLabel
    └── VibrateBtn
```

### `scripts/main.gd`

- **`_ready()`** — Connects `Input.joy_connection_changed` to update the connected label when a controller is plugged or unplugged.
- **`_process(delta)`** — Each frame, reads all six standard axes (`JOY_AXIS_LEFT_X/Y`, `JOY_AXIS_RIGHT_X/Y`, `JOY_AXIS_TRIGGER_LEFT/RIGHT`) and applies deadzone filtering. Reads all 18 standard buttons via `Input.is_joy_button_pressed()`.
- **`_draw()`** — Renders the left and right sticks as circles with a moving dot, triggers as horizontal bars, and buttons as a grid of colored indicators.

### Deadzone Filtering

```gdscript
const DEADZONE := 0.15

func _apply_deadzone(raw: float) -> float:
    return 0.0 if abs(raw) < DEADZONE else raw
```

Without deadzone filtering, joysticks produce small non-zero values even when untouched (electrical noise, wear). The deadzone discards values below a threshold. More sophisticated implementations remap the remaining range `[DEADZONE, 1.0]` to `[0.0, 1.0]` to restore full range after the deadzone.

### Connection Handling

```gdscript
Input.joy_connection_changed.connect(_on_joy_connection)

func _on_joy_connection(device_id: int, connected: bool) -> void:
    _active_joypad = device_id if connected else -1
```

`joy_connection_changed` fires on the main thread when a controller is connected or disconnected. Always check `Input.get_connected_joypads()` on startup too, since controllers connected before the game launches won't fire this signal.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.get_connected_joypads()` | Returns Array of connected device IDs |
| `Input.joy_connection_changed` | Signal — fired on connect/disconnect |
| `Input.get_joy_axis(device, axis)` | Read analog axis value [-1, 1] |
| `Input.is_joy_button_pressed(device, button)` | Read digital button state |
| `Input.start_joy_vibration(device, weak, strong, duration)` | Trigger rumble |
| `Input.stop_joy_vibration(device)` | Stop rumble early |
| `JOY_AXIS_LEFT_X`, `JOY_BUTTON_A`, etc. | Axis/button constants |
