# Radial Menu

Hold **Tab** to open a radial menu with six action items arranged in a circle.
Move the mouse to highlight a wedge; release **Tab** to select it (or move to
the dead-zone in the centre to cancel).

## Controls

| Input | Action |
|-------|--------|
| Hold Tab | Open menu |
| Mouse move | Highlight item |
| Release Tab | Confirm selection |
| Mouse inside centre circle | No selection (cancel) |

## How It Works

### Angle-to-index mapping

```gdscript
func _update_hover() -> void:
    var mouse := get_global_mouse_position() - CENTER
    if mouse.length() < INNER_R:
        _hovered = -1
        return
    var angle := fmod(mouse.angle() + TAU, TAU)
    _hovered = int(angle / (TAU / float(ITEMS.size())))
```

`Vector2.angle()` returns values in `[-PI, PI]`.  Adding `TAU` and wrapping
with `fmod` normalises to `[0, TAU)`.  Dividing by `TAU / n` converts the
angle to a zero-based item index.

### Wedge polygon construction

Each wedge is built as a `PackedVector2Array` polygon:

1. Start point on the inner arc at `start_angle`.
2. Ten interpolated points along the outer arc from `start_angle` to
   `end_angle`.
3. End point on the inner arc at `end_angle`.

`draw_polygon` fills the shape; `draw_polyline` adds a subtle border.

### Hold-to-open interaction

`_open` is set each frame from `Input.is_key_pressed(KEY_TAB)` (not
`is_key_just_pressed`).  A `was_open` snapshot detects the rising and falling
edges so selection fires exactly once on release:

```gdscript
var was_open := _open
_open = Input.is_key_pressed(KEY_TAB)
if _open:       _update_hover()
if was_open and not _open:  _select()
```

### Signal

`item_selected(index: int, label: String)` is emitted on confirm.  `main.gd`
connects it to update a result label.

## File Layout

```
radial-menu/
  project.godot
  icon.svg
  scripts/
    radial_menu.gd    # wedge draw, angle mapping, signal
    main.gd           # signal connection, background draw
  scenes/
    main.tscn
  tests/
    test_logic.gd     # angle→index mapping, inner-radius dead-zone
    test.tscn
  README.md
```
