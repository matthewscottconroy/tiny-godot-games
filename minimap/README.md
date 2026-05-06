# Minimap

A platformer set in a wide 2000×480 world with a real-time minimap drawn in
the top-right corner — no SubViewport required.

## Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move |
| Space / Up / W | Jump |

## How It Works

### Manual minimap drawing (no SubViewport)

The minimap is drawn entirely in `minimap.gd`'s `_draw()` method using the
Canvas2D drawing API.  A `SubViewport` would work but adds overhead; for a
simple 2D map a coordinate-scaled draw call is sufficient.

`minimap.gd` is a `Node2D` that lives inside a `CanvasLayer`.  `CanvasLayer`
renders its children in screen space — the scrolling `Camera2D` has no effect
on them — so the minimap rectangle stays fixed in the top-right corner
regardless of how far the player has walked.

### Coordinate scaling

All world positions are mapped to the minimap rectangle with one formula:

```gdscript
func _world_to_map(world_pos: Vector2) -> Vector2:
    return MAP_RECT.position + world_pos / Vector2(WORLD_W, WORLD_H) * MAP_RECT.size
```

`MAP_RECT` (top-right corner, 170×100 px) defines where the minimap sits on
screen and how large it is.  Dividing the world position by the world
dimensions gives a [0,1] normalised value; multiplying by `MAP_RECT.size`
scales that into map pixels; adding `MAP_RECT.position` offsets it to the
correct screen location.

### Data flow

`main.gd` updates two properties on the minimap node each frame before
calling `queue_redraw()`:

```gdscript
_minimap.player_world_pos = _player.global_position
_minimap.cam_world_pos    = _cam.position
_minimap.queue_redraw()
```

`minimap.gd` uses those values purely for drawing — it has no physics
involvement.

### Camera follow + clamp

```gdscript
_cam.position = Vector2(
    clampf(_player.global_position.x, 320.0, WORLD_W - 320.0),
    240.0
)
```

The camera's x position is clamped so the view never scrolls past the world
boundaries.  320 is half the 640-wide viewport.

## File Layout

```
minimap/
  project.godot
  icon.svg
  scripts/
    main.gd       # world draw, camera follow, feeds data to minimap
    player.gd     # CharacterBody2D platformer
    minimap.gd    # screen-space minimap draw (lives in CanvasLayer)
  scenes/
    main.tscn
  tests/
    test_logic.gd # coordinate scaling + clamp tests
    test.tscn
  README.md
```
