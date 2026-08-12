# Gamepad Input

Demonstrates joystick connection detection, analog axis reading with deadzone filtering, button state polling, and vibration — all via Godot's `Input` singleton.

## Purpose

Gamepad support requires handling hardware events that don't exist until a controller is plugged in, reading continuous analog values that need filtering, and triggering force feedback. Players expect plug-and-play behavior: connect a controller mid-game and it works immediately. Fail to handle that and controller users get a broken experience.

Real games expose every aspect of this demo: fighting games use raw axis values for precise directional inputs, racing games use trigger axes for throttle and brake, and action games use rumble to reinforce impacts. Getting each piece right — especially deadzone filtering and startup detection — is what separates a polished gamepad feel from a janky one.

This demo covers the complete gamepad loop: detecting connections at startup and dynamically, reading all six standard axes with deadzone filtering, polling all buttons, and triggering motor vibration.

## How It Works

### Node Tree

```
Main (Node2D)          <- main.gd
├── ConnectedLabel     (Label — shows connected device names)
├── AxisLabel          (Label — shows live axis values)
├── ButtonLabel        (Label — shows pressed button names)
└── VibrateBtn         (Button — triggers rumble)
```

### Connection Detection

```gdscript
func _ready() -> void:
    Input.joy_connection_changed.connect(_on_joy_connection)
    _refresh_devices()   # catch controllers already plugged in at launch

func _on_joy_connection(_device: int, _connected: bool) -> void:
    _refresh_devices()

func _refresh_devices() -> void:
    var pads := Input.get_connected_joypads()
    if pads.is_empty():
        connected_label.text  = "No gamepad connected — plug one in"
        connected_label.modulate = Color.TOMATO
    else:
        var names := pads.map(func(id): return "#%d: %s" % [id, Input.get_joy_name(id)])
        connected_label.text  = "Connected: " + ", ".join(names)
        connected_label.modulate = Color.SEA_GREEN
```

`joy_connection_changed` fires when a controller is plugged or unplugged at runtime. Calling `_refresh_devices()` in `_ready()` also covers controllers that were already connected when the game launched — those never fire the signal.

### Deadzone Filtering

```gdscript
const DEADZONE := 0.12

# In _process:
var raw := Input.get_joy_axis(id, ax)
var val := 0.0 if abs(raw) < DEADZONE else raw
```

Joystick hardware produces small non-zero values even when untouched due to electrical noise and mechanical wear. Without the deadzone guard, a resting stick would register tiny movements and drift the player character. A threshold of 0.12 is typical; competitive games often expose this as a user-adjustable setting.

### Reading All Axes

```gdscript
for ax in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y,
           JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y,
           JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
    var raw := Input.get_joy_axis(id, ax)
    var val := 0.0 if abs(raw) < DEADZONE else raw
```

Stick axes range from -1.0 to 1.0. Trigger axes range from 0.0 to 1.0 (fully released to fully pressed). All six axes are polled each `_process` frame.

### Vibration

```gdscript
func _vibrate() -> void:
    var pads := Input.get_connected_joypads()
    if not pads.is_empty():
        Input.start_joy_vibration(pads[0], 0.6, 0.6, 0.5)
```

`start_joy_vibration(device, weak_motor, strong_motor, duration)`. The weak motor is a high-frequency buzz (fine detail); the strong motor is a low-frequency rumble (impact weight). Using both at full intensity for 0.5 seconds gives a solid, noticeable response.

## Analog Input Theory

Deadzone filtering discards values below a threshold but leaves the remaining range as `[DEADZONE, 1.0]` rather than `[0.0, 1.0]`. This causes a jump from 0 to DEADZONE the moment the stick moves. Production games remap the post-deadzone range back to `[0.0, 1.0]`:

```gdscript
func _apply_deadzone_remapped(raw: float) -> float:
    if abs(raw) < DEADZONE:
        return 0.0
    return sign(raw) * (abs(raw) - DEADZONE) / (1.0 - DEADZONE)
```

This ensures full analog range with no sudden jump. The simpler threshold-only approach (used here) is sufficient for UIs and digital movement but can feel imprecise for analog aiming or throttle.

## How to Adapt This in Your Project

- **Player movement**: Replace `Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")` with direct axis reads via `Input.get_joy_axis()` and apply your own deadzone — the built-in action deadzone is not always sufficient.
- **Multiple controllers**: Loop over `Input.get_connected_joypads()` and assign each device ID to a player slot. Pass the device ID to all `Input.get_joy_axis()` and `Input.is_joy_button_pressed()` calls.
- **Trigger as analog**: Use `Input.get_joy_axis(id, JOY_AXIS_TRIGGER_RIGHT)` as a `[0, 1]` value for acceleration, camera zoom, or analog attack strength.
- **Remapping**: Store a `Dictionary` of action → `{device, axis_or_button}` and route reads through it to support user-configurable bindings.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.get_connected_joypads()` | Returns Array of connected device IDs |
| `Input.joy_connection_changed` | Signal fired on connect/disconnect |
| `Input.get_joy_name(device)` | Human-readable controller name |
| `Input.get_joy_axis(device, axis)` | Read analog axis value [-1, 1] |
| `Input.is_joy_button_pressed(device, button)` | Read digital button state |
| `Input.start_joy_vibration(device, weak, strong, duration)` | Trigger rumble |
| `Input.stop_joy_vibration(device)` | Stop rumble early |
| `JOY_AXIS_LEFT_X`, `JOY_BUTTON_A`, etc. | Axis/button enum constants |

## Controls

| Input | Action |
|-------|--------|
| Connect a gamepad | Display updates automatically |
| Move sticks / press triggers | See real-time axis values and visual indicators |
| Press any button | Name appears in button list |
| Vibrate button (on screen) | Triggers 0.5-second rumble |

## Key Constants

```gdscript
const DEADZONE := 0.12   # axis values below this are treated as zero
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Connection detection, axis/button polling, deadzone, vibration, visual rendering |
| `scenes/main.tscn` | Scene tree with labels and vibrate button |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

