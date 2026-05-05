# Circle Buttons

A configurable GUI component that renders colored circles as clickable buttons.
Circles are defined by external data; clicks return data back to the caller — no subclassing required.

## API

### Input — configure circles at any time

```gdscript
$CircleDisplay.configure([
    {"label": "A", "color": Color.TOMATO,          "radius": 50.0},
    {"label": "B", "color": Color.CORNFLOWER_BLUE, "radius": 35.0},
    {"label": "C", "color": Color.MEDIUM_SEA_GREEN,"radius": 60.0},
])
```

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `color` | `Color` | no | Fill color (default: `WHITE`) |
| `radius` | `float` | no | Radius in pixels (default: `30`) |
| `label` | `String` | no | Text drawn inside the circle |
| *any other key* | any | — | Passed through unchanged in click data |

Calling `configure()` again replaces the full set of circles immediately.

### Output — read clicks via signal

```gdscript
$CircleDisplay.circle_clicked.connect(func(index: int, data: Dictionary) -> void:
    print("circle %d clicked — label: %s, color: %s" % [index, data["label"], data["color"]])
)
```

`index` is the zero-based position in the array you passed to `configure()`.
`data` is a copy of that circle's spec dictionary, including any extra keys you added.

## Controls (demo)

| Key | Action |
|-----|--------|
| Mouse click | Click any circle |
| ← / → / Space | Cycle through three built-in presets |

## How it works

- `CircleDisplay` extends `Control`. It stores an array of circle specs and auto-layouts them horizontally, centered in the control's rect.
- `_draw()` calls `draw_circle()` and `draw_arc()` — no sprites or textures required.
- `_gui_input()` receives mouse events in the control's local coordinate space, making hit-testing a direct distance check: `distance(click, center) ≤ radius`.
- Hovered circles are lightened via `Color.lightened()` and the control calls `queue_redraw()` on change.
- `signal circle_clicked(index, data)` decouples the component from any specific caller.

## Files

| File | Purpose |
|------|---------|
| `scripts/circle_display.gd` | The `CircleDisplay` component — `configure()` input, `circle_clicked` signal output |
| `scripts/main.gd` | Demo: three presets, result label, keyboard cycling |
| `scenes/main.tscn` | VBoxContainer layout with `CircleDisplay` in the center |
| `tests/test_logic.gd` | Unit tests for hit detection, layout symmetry, and data passthrough |
