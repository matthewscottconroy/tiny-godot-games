# Camera Zoom

Demonstrates smooth `Camera2D` zoom driven by the scroll wheel or buttons, with a lerp-based target system, configurable min/max limits, and a one-key reset.

## Purpose

Camera zoom is required in any game that needs to show different amounts of the world — strategy games zooming out to the battlefield, action games zooming in for tension, puzzle games fitting the full board on screen. Done naively (setting `camera.zoom` directly on input), zoom snaps and feels mechanical. The target-zoom pattern separates the *desired* zoom from the *current* zoom, letting the camera glide smoothly between levels.

Games like *Into the Breach*, *Stardew Valley*, and virtually every RTS use this exact two-variable approach: player input writes to `target_zoom`, `_process` drives actual zoom toward it with a lerp. The lerp rate determines the feel — fast lerp is responsive, slow lerp is cinematic. Neither is objectively correct; it depends on the game's pacing.

An explicit `[ZOOM_MIN, ZOOM_MAX]` range prevents the camera from reaching nonsensical values (negative zoom inverts the world; zoom beyond 8× loses all spatial context). `clampf` on the target ensures the lerp always converges inside the valid range.

## How It Works

### Node Tree

```
Main (Node2D)          ← main.gd
├── Camera2D
└── HUD (CanvasLayer)
    ├── ZoomLabel
    ├── HintLabel
    └── Buttons (HBoxContainer)
        ├── InBtn
        ├── OutBtn
        └── ResetBtn
```

The `Camera2D` is a direct child of `Main`, not a child of any moving node, so it stays centered on the scene origin.

### Target-Zoom Pattern (`scripts/main.gd`)

```gdscript
const ZOOM_MIN   := 0.25
const ZOOM_MAX   := 4.0
const ZOOM_STEP  := 0.15
const ZOOM_SPEED := 6.0

var _target_zoom := 1.0

func _process(delta: float) -> void:
    var current := camera.zoom.x
    var new_z   := lerpf(current, _target_zoom, ZOOM_SPEED * delta)
    camera.zoom  = Vector2(new_z, new_z)
    zoom_label.text = "Zoom: %.2fx" % new_z

func _adjust(delta_zoom: float) -> void:
    _target_zoom = clampf(_target_zoom + delta_zoom, ZOOM_MIN, ZOOM_MAX)
```

`_adjust` modifies the target; `_process` drives the camera. Input never touches `camera.zoom` directly.

### Input Handling

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            _adjust(ZOOM_STEP)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            _adjust(-ZOOM_STEP)
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            _target_zoom = 1.0
        elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
            _adjust(ZOOM_STEP)
        elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
            _adjust(-ZOOM_STEP)
```

`_unhandled_input` (not `_input`) means buttons in the HUD consume their own click events first, preventing accidental zoom on button press. `not event.echo` prevents key-repeat from triggering many steps per hold.

## Smooth Zoom Theory

### `lerpf` as an Exponential Approach

`lerpf(a, b, t)` computes `a + (b - a) * t`. When `t = ZOOM_SPEED * delta`:

- Each frame closes a fixed *fraction* of the remaining gap.
- Convergence is exponential: fast when far, slow when near.
- At `ZOOM_SPEED = 6.0`, 60 fps: `t ≈ 0.10` per frame — 10% of the gap closed, reaching 99% in ~44 frames (~0.73 seconds).

This is frame-rate-independent: faster machines take smaller steps but more of them, slower machines take larger steps but fewer — the end time is the same.

### `Camera2D.zoom` is a Vector2

Godot represents zoom as `Vector2(x_scale, y_scale)`. Setting both axes equally (`Vector2(new_z, new_z)`) maintains the aspect ratio. Setting them differently produces a stretch effect (useful for screen distortion, not typical zoom). Larger values zoom IN (the world appears bigger on screen); smaller values zoom OUT (more world visible).

### Why Store Only `zoom.x` for Comparison

`camera.zoom.x` and `camera.zoom.y` are always equal in this demo, so reading one is sufficient. If your game ever applies non-uniform zoom, compare both axes independently.

## How to Adapt This in Your Project

**Zoom to cursor:** When zooming in, shift `camera.position` toward the mouse position so the point under the cursor stays under the cursor. Compute `offset = mouse_world_pos - camera.position` and apply a fraction of it on each zoom step.

**Context-triggered zoom:** Drive `_target_zoom` from game state rather than input — zoom out when the player is falling, zoom in for a boss encounter, return to 1× during normal gameplay.

**Scroll-to-fit:** Compute the zoom that fits all relevant objects in the viewport: `zoom = viewport_size / world_bounding_box_size`. Assign this to `_target_zoom` and the camera lerps to fit automatically.

**Snap steps:** Replace `_target_zoom += ZOOM_STEP` with `round(_target_zoom / ZOOM_STEP) * ZOOM_STEP + ZOOM_STEP` to snap to discrete levels (0.5×, 1×, 1.5×, 2×) instead of continuous zoom.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Camera2D.zoom` | `Vector2` scale — larger = zoomed in, smaller = zoomed out |
| `lerpf(a, b, t)` | Smooth float interpolation; use with `delta` for frame-rate independence |
| `clampf(x, min, max)` | Constrain target zoom to the valid range |
| `InputEventMouseButton.button_index` | `MOUSE_BUTTON_WHEEL_UP/DOWN` for scroll wheel |
| `_unhandled_input(event)` | Receives input not consumed by UI controls |
| `InputEventKey.echo` | `true` for key-repeat events (suppress to avoid rapid-fire) |

## Controls

| Input | Action |
|-------|--------|
| Scroll wheel up | Zoom in |
| Scroll wheel down | Zoom out |
| `+` / `=` / numpad `+` | Zoom in |
| `-` / numpad `-` | Zoom out |
| `R` | Reset to 1× zoom |
| In / Out / Reset buttons | Same actions via UI |

## Key Constants

```gdscript
const ZOOM_MIN   := 0.25   # minimum zoom (shows 4× more world than 1×)
const ZOOM_MAX   := 4.0    # maximum zoom (shows 4× less world than 1×)
const ZOOM_STEP  := 0.15   # zoom increment per scroll tick or button press
const ZOOM_SPEED := 6.0    # lerp convergence rate (higher = snappier response)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Target zoom tracking, input handling, lerp-driven camera, reference grid drawing |
