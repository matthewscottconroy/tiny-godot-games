# Light and Shadow

Demonstrates 2D lighting using `PointLight2D` with a procedurally generated radial gradient texture, combined with `CanvasModulate` for global ambient darkness.

## Purpose

Godot's 2D lighting system requires a texture on `PointLight2D` — but you do not need image files. This demo shows how to generate a smooth light falloff texture at runtime using `Image` pixel math, and how `CanvasModulate` multiplies a base color over everything to create darkness. Understanding this system is essential for dungeon crawlers, horror games, stealth games, and any project with dynamic lighting.

## Controls

- **Arrow keys**: Move the player (the player carries a light)
- **Toggle Torch button**: Enable/disable the static torch light
- **Color button**: Randomize the player's light color
- **Ambient slider**: Adjust the global ambient brightness (darkens/brightens the whole scene)

## How It Works

### Node Tree

```
Main (Node2D)                     ← main.gd
├── CanvasModulate                 (global color multiplier)
├── Player (CharacterBody2D)      ← player.gd
│   └── PlayerLight (PointLight2D)
├── TorchLight (PointLight2D)
├── (wall rectangles via _draw())
└── HUD (CanvasLayer)
    ├── ToggleTorchBtn
    ├── ColorBtn
    └── AmbientSlider (HSlider)
```

### `scripts/main.gd` — Light Texture Generation

```gdscript
func _make_light_tex(radius: int) -> ImageTexture:
    var img := Image.create(radius * 2, radius * 2, false, Image.FORMAT_RGBA8)
    for x in radius * 2:
        for y in radius * 2:
            var d := Vector2(x - radius, y - radius).length()
            var a := pow(maxf(1.0 - d / radius, 0.0), 1.8)
            img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
    return ImageTexture.create_from_image(img)
```

For each pixel, compute the normalized distance from the center (`d / radius`). Alpha is:
```
a = max(1 - d/radius, 0)^1.8
```
- At center (d=0): `a = 1.0` (fully opaque)
- At edge (d=radius): `a = 0.0` (fully transparent)
- The `pow(..., 1.8)` exponent makes the falloff nonlinear — bright in the middle, falling off sharply near the edge, which matches how real point lights behave

The image is white with varying alpha. `PointLight2D` tints the light by multiplying this texture with its `color` property.

### CanvasModulate

```gdscript
$CanvasModulate.color = Color(v, v, v * 1.1)
```

`CanvasModulate` multiplies its color over every pixel in its canvas layer. At `Color(0.1, 0.1, 0.11)` (very dark), the world appears almost black. At `Color(1.0, 1.0, 1.0)` (white), everything is at full brightness.

`PointLight2D` adds light on top of this base color. Where the light texture is opaque, pixels get brighter. Where it is transparent, pixels remain at the ambient level.

### PointLight2D Requirements

`PointLight2D` requires:
1. A **texture** — defines the light's shape and falloff (generated here at runtime)
2. A **color** — multiplied with the texture
3. **Energy** — overall brightness multiplier
4. **Range** settings — `height`, `item_shadow_filter_smooth`, etc.

Without a texture, the light does nothing visible.

## 2D Lighting Theory

### How Godot 2D Lighting Works

Godot uses a **light map blend** approach for 2D:
1. The scene renders normally at ambient brightness (controlled by CanvasModulate)
2. Each `PointLight2D`'s texture is rendered additively on top
3. `Light2D.blend_mode = BLEND_ADD` (default) means light pixels are added to the existing color — making lit areas brighter

### Radial Falloff

Real light follows an inverse-square law: `intensity = 1 / distance²`. This demo uses a softer `pow(x, 1.8)` curve rather than `1 / d²` because:
- `1 / d²` is undefined at `d = 0`
- `1 / d²` produces a very harsh, small bright center with a dark field — less visually appealing for game lighting
- `(1 - d/r)^1.8` gives a smooth, artist-friendly gradient

### Image.FORMAT_RGBA8

Each pixel is 4 bytes: R, G, B, A each 0–255. The light texture uses `R=G=B=1.0` (white) with varying alpha. PointLight2D multiplies this texture by its `color` property, allowing the light color to be changed without regenerating the texture.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `PointLight2D` | 2D additive light source |
| `PointLight2D.texture` | Shape and falloff of the light |
| `PointLight2D.color` | Light tint color |
| `PointLight2D.enabled` | On/off toggle |
| `CanvasModulate` | Global color multiplier for a canvas layer |
| `Image.create(w, h, mipmaps, format)` | Create a blank image |
| `Image.set_pixel(x, y, color)` | Set a pixel color |
| `ImageTexture.create_from_image(img)` | Convert Image to a usable texture |
| `maxf(a, b)` | Float max |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

