# SubViewport

Renders the same `World2D` through two cameras simultaneously — a close-up main camera following the player and a zoomed-out minimap camera — using `SubViewport` as an offscreen render target whose texture is displayed in the HUD.

## Purpose

A minimap requires two simultaneous views of the same world: one close-up view that the player navigates with, and one overview that reveals the full map. `SubViewport` is Godot's mechanism for offscreen rendering — it maintains its own camera, render target, and output texture. The critical technique is world sharing: by assigning the main viewport's `World2D` to the `SubViewport`, both cameras draw the same scene content with no duplication of nodes or draw calls.

This pattern appears in countless games: minimaps in RPGs (Zelda, Dark Souls), radar in racing games, security cameras in stealth games, split-screen previews in level editors, and picture-in-picture cutscenes. Understanding `SubViewport` also unlocks render-to-texture techniques: procedural textures, shader post-processing on isolated regions, and reflective surfaces.

## How It Works

### Node Tree

```
Main (Node2D)                    ← main.gd
├── MainCamera (Camera2D)        ← follows player, default zoom
├── MinimapViewport (SubViewport)
│   └── MinimapCamera (Camera2D) ← centered on world, zoomed out
└── HUD (CanvasLayer)
    ├── MinimapBorder (ColorRect)
    ├── MinimapDisplay (TextureRect)
    └── PlayerDot (ColorRect)    ← yellow dot showing player position
```

### World2D Sharing

```gdscript
_minimap_vp.world_2d = get_viewport().world_2d
```

This is the single most important line. Without it, the `SubViewport` creates its own empty `World2D` and the minimap camera sees nothing. With it, both the main camera and the minimap camera share exactly the same canvas draw calls — any `_draw()` output, sprites, and other 2D nodes are rendered by both cameras simultaneously.

### Minimap Camera Zoom

```gdscript
var zoom_x := float(MINIMAP_W) / float(WORLD_W)   # 160 / 1200 ≈ 0.133
var zoom_y := float(MINIMAP_H) / float(WORLD_H)   # 114 / 900  ≈ 0.127
var zoom   := minf(zoom_x, zoom_y)                 # use the smaller (fit-within)
_minimap_cam.zoom     = Vector2(zoom, zoom)
_minimap_cam.position = Vector2(WORLD_W / 2.0, WORLD_H / 2.0)
```

At `zoom ≈ 0.127`, the 160-pixel SubViewport width shows `160 / 0.127 ≈ 1260` world units — slightly wider than the 1200-unit world, ensuring the full world is always visible with a small margin. `minf` picks the more constraining axis so the world fits on both dimensions without cropping.

### Connecting Viewport Texture to HUD

```gdscript
$HUD/MinimapDisplay.texture = _minimap_vp.get_texture()
```

`SubViewport.get_texture()` returns a `ViewportTexture` — a special texture that live-updates every frame. Assigning it to a `TextureRect` displays the SubViewport's rendered output anywhere in the scene tree. The texture is not a snapshot; it reflects the current frame's render.

### Player Movement

```gdscript
func _process(delta: float) -> void:
    var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    _player_pos += dir * PLAYER_SPEED * delta
    _player_pos.x = clampf(_player_pos.x, 16, WORLD_W - 16)
    _player_pos.y = clampf(_player_pos.y, 16, WORLD_H - 16)
    _main_cam.position = _player_pos
    queue_redraw()
```

The player is not a scene node — it's a `Vector2` variable drawn in `_draw()`. This keeps the demo focused on the SubViewport technique. In a real game, attach the `MainCamera` as a child of the player `CharacterBody2D`.

### Player Dot on Minimap HUD

The yellow player dot is a 6×6 `ColorRect` in the HUD. Its position is mapped from world space to minimap pixel space:

```gdscript
var minimap_origin := Vector2(470, 360)   # top-left corner of MinimapDisplay in screen coords
var px := minimap_origin.x + (_player_pos.x / WORLD_W) * MINIMAP_W
var py := minimap_origin.y + (_player_pos.y / WORLD_H) * MINIMAP_H
$HUD/PlayerDot.offset_left   = px - 3
$HUD/PlayerDot.offset_top    = py - 3
$HUD/PlayerDot.offset_right  = px + 3
$HUD/PlayerDot.offset_bottom = py + 3
```

The `PlayerDot` is a separate HUD element overlaid on top of the `MinimapDisplay` TextureRect — it is not rendered inside the SubViewport. This approach is flexible: you can add icons, enemy blips, and waypoints as separate HUD nodes without modifying the SubViewport rendering.

### World Content

The world is drawn entirely in `_draw()`: a dark background, a grid, 35 randomly positioned shapes (deterministic with `rng.seed = 12345`), the player circle, and a semi-transparent rectangle showing the main camera's current viewport frame. Because `_draw()` runs for the `Main` node, both the main camera and the minimap camera receive these draw calls via the shared `World2D`.

```gdscript
# Camera viewport frame — visible in the minimap as a blue rectangle
var half_w := 320.0
var half_h := 240.0
var frame  := Rect2(_player_pos - Vector2(half_w, half_h), Vector2(640, 480))
draw_rect(frame, Color(0.5, 0.8, 1.0, 0.25))
draw_rect(frame, Color(0.5, 0.8, 1.0, 0.6), false, 1.5)
```

## SubViewport Configuration

Key properties to set for correct minimap behavior:

| Property | Value | Why |
|----------|-------|-----|
| `SubViewport.size` | `Vector2i(160, 114)` | Resolution of the offscreen render |
| `SubViewport.render_target_update_mode` | `UPDATE_ALWAYS` | Render every frame (default; use `UPDATE_ONCE` for static captures) |
| `SubViewport.world_2d` | `get_viewport().world_2d` | Share the main scene content |
| `Camera2D.enabled` | `true` | Must be enabled to render from this camera |

## How to Adapt This in Your Project

- **Radar with icons**: instead of rendering the full scene in the minimap, render only lightweight markers (enemy dots, objective icons) in the SubViewport by using a separate `Node2D` layer visible only to the minimap camera via `VisualInstance2D.layers`.
- **Picture-in-picture**: add a second `SubViewport` showing a fixed camera position (e.g. a security camera feed). Display it in a `TextureRect` inside the main HUD.
- **Render to texture**: assign `SubViewport.get_texture()` as the `albedo_texture` of a 3D `StandardMaterial3D` to create a 2D scene displayed on a 3D surface.
- **Snapshot / screenshot**: set `render_target_update_mode = UPDATE_ONCE` and call `render_target_update_mode = UPDATE_ONCE` again to capture a fresh frame, then read pixels from the texture with `get_image().get_pixel()`.
- **Zoom**: change `MinimapCamera.zoom` dynamically for a zoomable minimap. Clamp to prevent extreme zoom levels.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SubViewport` | Offscreen render target with its own camera and render pipeline |
| `SubViewport.world_2d` | Assign to share scene content with another viewport |
| `SubViewport.size` | Pixel resolution of the offscreen render buffer |
| `SubViewport.get_texture()` | Returns a live `ViewportTexture` updated every frame |
| `ViewportTexture` | Texture that mirrors a SubViewport's rendered output |
| `TextureRect.texture` | Display a `ViewportTexture` in the UI |
| `Camera2D.zoom` | Scale factor for world-to-viewport mapping (Vector2) |
| `Camera2D.position` | World-space position the camera is centered on |

## Controls

| Input | Action |
|-------|--------|
| **Arrow keys** | Move the player through the world |

## Key Constants

```gdscript
const WORLD_W    := 1200    # world width in pixels
const WORLD_H    := 900     # world height in pixels
const PLAYER_SPEED := 200.0 # pixels per second
const MINIMAP_W  := 160     # SubViewport width in pixels
const MINIMAP_H  := 114     # SubViewport height in pixels
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | World2D sharing, camera setup, player movement, world drawing |
| `scenes/main.tscn` | Node tree with SubViewport, HUD, cameras, and player dot |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

