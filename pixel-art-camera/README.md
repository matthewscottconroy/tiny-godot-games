# Pixel Art Camera

Renders the game world at 160×120 pixels and scales it 4× to fill a 640×480 window via a `SubViewport`, producing crisp integer-scaled pixel art without any filtering blur.

## Purpose

Low-resolution rendering is the defining visual characteristic of pixel art games. The wrong approach — scaling a 640×480 game down in an art tool — is static. The right approach renders the game at true low resolution and scales the output up at display time. This preserves the logical world coordinates (tiles are tiles, pixels are pixels) while outputting blocky screen pixels.

The critical requirement is **integer scaling with nearest-neighbor filtering**. Non-integer scaling (e.g., 2.5×) misaligns pixels and creates shimmer artifacts when objects move. Bilinear filtering blurs the hard edges that define the pixel art aesthetic. `SubViewport` + `SubViewportContainer` gives Godot developers both guarantees easily.

This technique is used by every Godot pixel art game: 16×16 or 32×32 sprites drawn at their native resolution, scaled to fill modern screens. UNDERTALE, Shovel Knight, and Celeste all use integer-scaled low-resolution viewports.

## How It Works

### Scene Structure

```
Control (Main) [main.gd]
└── SubViewportContainer (stretch=true, fills 640×480)
    └── SubViewport (size=160×120, update_mode=ALWAYS)
        └── World (Node2D) [world.gd]  ← all world content here
```

Everything visible in the game lives inside the `SubViewport`. The container stretches the viewport's 160×120 output to fill its own 640×480 bounds, applying a 4× scale.

### Pixel Mode Toggle (`scripts/main.gd`)

```gdscript
func _apply_pixel_mode() -> void:
    if _pixel_mode:
        _subviewport.size = Vector2i(160, 120)
        _container.stretch = true
    else:
        _subviewport.size = Vector2i(640, 480)
        _container.stretch = true
```

In pixel mode, the viewport renders at 160×120 then scales up. In normal mode, the viewport renders at full 640×480 — the stretch still fills the container, but the scale factor is 1× so no pixelation occurs. The comparison is dramatic and instantly demonstrates the technique.

### World Content (`scripts/world.gd`)

All world coordinates use the 160×120 space:

```gdscript
const WORLD_W := 160.0
const WORLD_H := 120.0
const TILE_SIZE := 8.0
const PLAYER_SPEED := 50.0
```

An 8×8 pixel tile at 160×120 becomes a 32×32 pixel tile on screen at 4× scale. The player character is drawn with single-pixel rects that become 4-pixel blocks — exactly the chunky pixel art aesthetic.

### Wrapping

```gdscript
_player_pos.x = fposmod(_player_pos.x, WORLD_W)
_player_pos.y = fposmod(_player_pos.y, WORLD_H)
```

`fposmod` is Godot's always-positive floating-point modulo. It wraps the player's position to stay within the 160×120 world bounds, giving the impression of a toroidal level.

## Integer Scaling and Nearest-Neighbor Filtering

### Why Nearest-Neighbor

When Godot scales the `SubViewportContainer`, it uses the texture filtering mode of the container's material. With the default project setting **Rendering > Textures > Canvas Textures > Default Texture Filter** set to `Nearest`, no interpolation is applied between source pixels — each 1×1 source pixel becomes a clean N×N block of identical pixels on screen.

Setting this to `Linear` would blur the output. Always verify `Project Settings > Rendering > Textures > Canvas Textures > Default Texture Filter = Nearest` for pixel art projects.

### Integer Scale Math

```
screen_width  / viewport_width  = 640 / 160 = 4.0  (integer)
screen_height / viewport_height = 480 / 120 = 4.0  (integer)
```

A 4× integer scale means every viewport pixel maps to a perfect 4×4 block on screen — no sub-pixel misalignment. Common integer scales for pixel art games: 2× (320×180 → 640×360), 3× (320×180 → 960×540), 4× (160×120 → 640×480).

### Subpixel Jitter

At non-integer scales, objects moving at fractional pixel speeds cause visible jitter because their screen position alternates between two renderings. At 4× integer scale, a character moving at 50 world-pixels/second moves 200 screen-pixels/second — still an integer number of screen pixels per frame at 60fps.

## How to Adapt This in Your Project

- **Camera follow in low-res**: Move the camera inside the SubViewport. Round the camera position to integer coordinates each frame: `camera.position = camera.position.round()`. This prevents sub-pixel drift.
- **HUD over pixel art**: Add a second `CanvasLayer` at normal resolution outside the SubViewport. Draw HUD elements at full resolution; the pixel art world renders underneath at low resolution.
- **Dynamic resolution**: Adjust `_subviewport.size` at runtime to simulate CRT scanline modes, handheld screens, or performance scaling.
- **Pitfall**: Placing UI nodes inside the SubViewport makes them also render at low resolution. HUDs, menus, and any text that needs to be crisp should live outside the SubViewport in a separate CanvasLayer.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SubViewport` | Renders its children to an offscreen texture at a specified size |
| `SubViewport.size` | The resolution at which the world renders |
| `SubViewportContainer.stretch` | Scales SubViewport output to fill the container |
| `fposmod(x, mod)` | Always-positive floating-point modulo for wrapping |
| `Vector2i` | Integer vector used for viewport size |

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrow keys | Move the player character |
| P | Toggle pixel mode (160×120 4×) vs normal mode (640×480 1×) |

## Key Constants

```gdscript
# main.gd
_pixel_mode viewport size  = Vector2i(160, 120)   # 4x scale
_normal_mode viewport size = Vector2i(640, 480)   # 1x scale

# world.gd
const WORLD_W      := 160.0   # logical world width (matches low-res viewport)
const WORLD_H      := 120.0   # logical world height
const TILE_SIZE    := 8.0     # checkerboard tile in world pixels
const PLAYER_SPEED := 50.0    # world pixels per second
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | SubViewport size management, pixel mode toggle |
| `scripts/world.gd` | Player movement, wrapping, all low-res world drawing |
| `scenes/main.tscn` | SubViewportContainer → SubViewport hierarchy |
| `tests/test.tscn` | Tests for viewport sizing and pixel mode logic |

## Use as a building block

**Copy:** `scripts/world.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

## Related demos

- [screen-distortion](../screen-distortion) — Full-screen heat-haze via `SubViewport` + UV-displacing shader.
- [screen-warp](../screen-warp) — Sinusoidal UV displacement of the whole world via `SubViewportContainer`.
- [subviewport](../subviewport) — Render one `World2D` through two cameras (main + minimap) via `SubViewport`.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

