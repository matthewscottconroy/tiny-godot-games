# Circle Buttons

<!-- tags: ui, signals, component -->

A reusable GUI component (`CircleDisplay`) that renders an arbitrary set of colored circles as clickable buttons. The caller passes a data array in; clicks pass that data back out via a signal — no subclassing required.

## Purpose

Custom button shapes are needed whenever the standard rectangular button doesn't match a game's visual language: skill wheels, color pickers, radial menus, ability bars with circular slots, or card-game selection interfaces all require non-rectangular hit areas. Godot's built-in `Button` is a rectangle; circle hit detection requires a distance check, not an `intersects()` call.

This component demonstrates a clean widget design pattern that scales to any game UI: separate concerns into an *input API* (`configure()`), an *output signal* (`circle_clicked`), and *internal state* (the specs array and layout). The caller never touches the internals. The component never knows anything about the calling context. This makes the component drop-in reusable — the three demo presets exercise it without modifying a single line in `circle_display.gd`.

The data-passthrough pattern (specs in, spec copy out via signal) means the component doubles as a data picker: the index and full spec dictionary are returned on each click, so the caller can immediately act on whichever circle was selected without maintaining its own parallel state.

## How It Works

### Node Tree

```
Main (Control)                  ← main.gd
└── VBox (VBoxContainer)
    ├── CircleDisplay (Control) ← circle_display.gd  (class_name CircleDisplay)
    ├── ResultLabel (Label)
    └── PresetLabel (Label)
```

`CircleDisplay` extends `Control` — the correct base class for any GUI widget. It receives mouse input via `_gui_input()`, which delivers events in local control coordinates, making hit-testing straightforward.

### Input API — `configure()`

```gdscript
func configure(specs: Array) -> void:
    _circles = []
    for spec in specs:
        _circles.append(spec.duplicate())
    _place()
    _hovered = -1
    queue_redraw()
```

`configure()` replaces the entire circle set. `spec.duplicate()` makes a defensive copy of each spec dict so changes to the caller's original data don't affect the displayed circles. Call `configure()` again at any time to hot-swap the entire button set.

Each entry in the `specs` array may contain:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `"color"` | `Color` | `WHITE` | Fill color |
| `"radius"` | `float` | `30.0` | Radius in pixels |
| `"label"` | `String` | `""` | Text drawn inside the circle |
| *any other key* | any | — | Passed through unchanged in click signal |

### Output Signals

```gdscript
signal circle_clicked(index: int, data: Dictionary)
```

```gdscript
# In main.gd:
_display.circle_clicked.connect(_on_circle_clicked)

func _on_circle_clicked(index: int, data: Dictionary) -> void:
    _result_label.text = (
        "index: %d   label: \"%s\"   radius: %.0f   color: #%s" % [
            index,
            data.get("label", ""),
            data.get("radius", 0.0),
            (data.get("color", Color.WHITE) as Color).to_html(false),
        ]
    )
```

`index` is the zero-based position in the array passed to `configure()`. `data` is a copy of that circle's spec — including any extra keys the caller added. The caller stores all extra data in the spec and retrieves it from the click signal, eliminating parallel state.


### `hover_changed`

```gdscript
signal hover_changed(index: int)
```

Emitted when the circle under the cursor changes, with `-1` when the cursor
leaves them all. It is the *edge*, not the stream: moving the mouse within one
circle emits nothing, because a caller showing a tooltip or playing a sound
wants to be told once per circle entered.

That guard is the same shape as a setter that only emits on a real change, and
it is worth having for the same reason — a component that fires on every mouse
move pushes the "has this actually changed?" question onto every caller.

### Layout (`_place`)

```gdscript
const _GAP := 20.0

func _place() -> void:
    var total_w := 0.0
    for c in _circles:
        total_w += c.get("radius", 30.0) * 2.0
    if _circles.size() > 1:
        total_w += _GAP * (_circles.size() - 1)

    var x := -total_w * 0.5
    for c in _circles:
        var r: float = c.get("radius", 30.0)
        c["_ox"] = x + r
        c["_oy"] = 0.0
        x += r * 2.0 + _GAP
```

Layout offsets `_ox` and `_oy` are stored directly in each spec dict as private layout keys. `_center_of(c)` adds `size * 0.5` (the control's center) to these offsets, so the row of circles is always centered in the control regardless of its container size.

### Hit Testing

```gdscript
func _hit_test(local_pos: Vector2) -> int:
    for i in range(_circles.size() - 1, -1, -1):
        var c := _circles[i]
        if local_pos.distance_to(_center_of(c)) <= c.get("radius", 30.0):
            return i
    return -1
```

Iteration is reversed (highest index first) so the last-drawn circle (on top visually) gets click priority when circles overlap. The hit test is a single `distance_to` call — no AABB precheck, because circles don't have an axis-aligned bounding box that speeds things up meaningfully at this object count.

### Hover Feedback

```gdscript
func _gui_input(event: InputEvent) -> void:
    elif event is InputEventMouseMotion:
        var prev := _hovered
        _hovered = _hit_test(event.position)
        if _hovered != prev:
            queue_redraw()
```

`queue_redraw()` is only called when the hovered circle changes, not on every mouse move. In `_draw()`, the hovered circle's color is lightened by 28% using `Color.lightened(0.28)`.

## How to Adapt This in Your Project

**Radial/ring layout:** Replace `_place()` with a radial layout that positions circles evenly around a center point using `Vector2.from_angle(i * TAU / count) * ring_radius`.

**Extra data passthrough:** Add `"action": "fire"` or `"item_id": 42` to any spec dict. The value comes back in `data` via the `circle_clicked` signal — no changes to `circle_display.gd` required.

**Disabled state:** Add `"disabled": true` to a spec. In `_draw()`, skip click handling for disabled circles and darken their color. In `_gui_input()`, check `c.get("disabled", false)` before emitting the signal.

**Animated selection:** On click, store `_selected = index` and tween a scale factor from 1.0 to 1.2 and back using `create_tween()`. Draw the selected circle with `radius * _scale_factor`.

**Keyboard navigation:** Add `_focused: int` state and respond to `ui_right`/`ui_left` in `_gui_input`. Draw a white outline ring around the focused circle and emit `circle_clicked` on `ui_accept`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Control._gui_input(event)` | Receives mouse/keyboard events in control-local coordinates |
| `Control._draw()` | Custom drawing within the control's rectangle |
| `Control.size` | Current size of the control in pixels (adapts to container) |
| `draw_circle(pos, radius, color)` | Filled circle |
| `draw_arc(pos, radius, from, to, pts, color, width)` | Circle outline / arc |
| `Color.lightened(amount)` | Return a lighter copy of a color (0.0–1.0 amount) |
| `Dictionary.get(key, default)` | Safe key access with a fallback value |
| `signal circle_clicked(index, data)` | Typed signal — decouples component from caller |
| `signal hover_changed(index)` | The circle under the cursor, `-1` for none |

## Controls

| Input | Action |
|-------|--------|
| Left-click on a circle | Emit `circle_clicked` with index and spec |
| Move onto or off a circle | Emit `hover_changed` with the new index |
| Left / Right arrow, Space | Cycle through the three built-in presets |

## Key Constants

```gdscript
const _GAP := 20.0    # pixels between circle edges in the horizontal layout

# circle_display.gd defaults (used when a spec omits the key):
# "radius" default: 30.0 px
# "color"  default: Color.WHITE
# "label"  default: "" (no text)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/circle_display.gd` | The `CircleDisplay` component: `configure()` API, layout, rendering, hit testing, `circle_clicked` signal |
| `scripts/main.gd` | Demo host: three presets, keyboard cycling, result label |
| `scenes/main.tscn` | `VBoxContainer` layout with `CircleDisplay` centered |
| `tests/test_logic.gd` | Unit tests for hit detection, layout symmetry, and spec data passthrough |

## Use as a building block

**Copy:** `scripts/circle_display.gd` — the `CircleDisplay` type. `scripts/main.gd` is the demo driver (it builds the scene and draws the visualisation) and is not needed.

**`CircleDisplay` API**
- `configure(specs: Array) -> void`
- signal `circle_clicked(index: int, data: Dictionary)`

**Notes**
- `class_name CircleDisplay` is global to the project — rename it if you already define that type.

## Related demos

- [accessibility-options](../accessibility-options) — Colourblind-safe palettes, reduced motion, text scaling, and shape cues.
- [checkpoint-system](../checkpoint-system) — One-way checkpoints that update respawn position; press R to die and respawn.
- [dialogue-box](../dialogue-box) — Typewriter text reveal, speaker labels, multi-line progression, skip.
- [footstep-audio](../footstep-audio) — Surface-sensitive footsteps synthesized per surface on a step signal.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

