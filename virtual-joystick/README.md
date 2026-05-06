# Virtual Joystick

An on-screen joystick in the bottom-left corner.  Click and drag to move the
player around the arena.  The joystick outputs a normalised `direction`
Vector2 that is read each physics frame.

## Controls

| Input | Action |
|-------|--------|
| Left-click + drag on joystick | Move player |
| Release | Stop |

## How It Works

### Direction output as normalised Vector2

```gdscript
func _update_knob(pos: Vector2) -> void:
    var delta := pos - _origin
    var clamped := delta.limit_length(BASE_RADIUS)
    _knob_pos = _origin + clamped
    direction = clamped / BASE_RADIUS
```

`direction` is always in `[-1, 1]` on each axis (length ≤ 1.0).  At full
deflection it is a unit vector; at rest it is `Vector2.ZERO`.  The player
multiplies this by `SPEED` each physics frame:

```gdscript
velocity = joystick.direction * SPEED
```

### _gui_input for click+drag

The joystick `Control` uses `_gui_input` (not `_input`) so it only receives
events when the mouse is inside its rect (which covers the full viewport).
`mouse_filter = MOUSE_FILTER_PASS` lets events fall through to nodes below.

```gdscript
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton ...:
        _active = event.pressed
        ...
    elif event is InputEventMouseMotion and _active:
        _update_knob(event.position)
```

### Mobile use

Replace `_gui_input` with `_input` and use `InputEventScreenTouch` /
`InputEventScreenDrag` for touch input.  The `direction` output API is
identical so `player.gd` requires no changes.

### MOTION_MODE_FLOATING

The player uses `MOTION_MODE_FLOATING` (no gravity) so it can move freely in
all directions inside the arena — appropriate for a top-down or demo context.

## File Layout

```
virtual-joystick/
  project.godot
  icon.svg
  scripts/
    joystick.gd   # _gui_input, direction output, _draw
    player.gd     # CharacterBody2D, reads joystick.direction
    main.gd       # wires joystick to player, arena draw
  scenes/
    main.tscn
  tests/
    test_logic.gd # direction maths, clamp, inactive reset
    test.tscn
  README.md
```
