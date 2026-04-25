# Camera Zoom

Demonstrates how to zoom a `Camera2D` smoothly using the scroll wheel, with lerp-based interpolation and configurable min/max limits.

## Purpose

Every game with a scrolling or zoomable view needs camera zoom. This demo shows the canonical approach: maintain a `_target_zoom` float, adjust it on input, then lerp the camera's actual zoom toward the target each frame. The result is buttery-smooth zoom that never snaps or overshoots.

## Controls

- **Scroll wheel up/down**: Zoom in / out
- **In / Out buttons**: Same as scroll wheel
- **Reset button**: Return to 1× zoom

## How It Works

### Node Tree

```
Main (Node2D)          ← main.gd
├── Camera2D
└── HUD (CanvasLayer)
    ├── ZoomLabel
    ├── HintLabel
    └── ButtonRow (HBoxContainer)
        ├── InBtn, OutBtn, ResetBtn
```

### `scripts/main.gd`

- **`_target_zoom`** — A float tracking the desired zoom level. Camera2D.zoom is always driven toward this value, never set directly.
- **`_adjust(delta)`** — Multiplies `_target_zoom` by a step factor and clamps it to `[ZOOM_MIN, ZOOM_MAX]`.
- **`_process(delta)`** — Calls `lerpf(current_zoom, _target_zoom, ZOOM_SPEED * delta)` on both axes of `camera.zoom`. `lerpf` with a rate tied to delta gives an exponential approach that feels responsive at any frame rate.
- **`_draw()`** — Draws a reference grid and colored shapes so the zoom effect is clearly visible.

## Smooth Lerp Theory

`lerpf(a, b, t)` returns `a + (b - a) * t`. When `t = ZOOM_SPEED * delta`:

- Large t (fast rate): snappier response, less smooth
- Small t (slow rate): very smooth, feels sluggish

At ZOOM_SPEED = 8 and delta = 0.016 (60 fps): t ≈ 0.128, meaning ~12% of the remaining gap is closed each frame. This converges quickly without overshooting.

## Camera2D.zoom

`Camera2D.zoom` is a `Vector2`. Larger values zoom IN (world appears larger), smaller values zoom OUT. A zoom of `(2, 2)` makes the viewport show half as much world; `(0.5, 0.5)` shows twice as much. Setting both axes equally maintains the aspect ratio.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Camera2D.zoom` | `Vector2` — scale of the camera view |
| `lerpf(a, b, t)` | Linear interpolation between two floats |
| `InputEventMouseButton.button_index` | `MOUSE_BUTTON_WHEEL_UP/DOWN` for scroll |
| `clampf(x, min, max)` | Constrain zoom to valid range |
