# Palette Swap

A fragment shader that replaces specific source colors with destination colors using RGB distance comparison. Cycle through 5 character palettes at runtime — armor and body color change instantly without extra textures or draw calls.

## Purpose

Palette swapping is the classic technique for character color variants: player 1 vs player 2, team colors, alternate costumes, and unlockable skins. The NES used it with actual hardware palette registers; modern games implement it in shaders. The GPU approach: for each pixel, measure the Euclidean distance in RGB space from the pixel color to each source color; if close enough, substitute the destination color. One shader handles unlimited palettes — only the destination color uniforms change.

This technique is used in fighting games (Street Fighter's player 1/2 color codes), action RPGs (Diablo's dye system), and any game with character customization. The shader approach is more flexible than separate textures per costume: it requires no extra texture memory, works on any sprite using the material, and allows runtime color changes in response to game events (faction changes, status effects, special modes).

The demo also shows how to build a sprite texture entirely in code with `Image.set_pixel()`, which is useful for prototyping and for tools that generate textures procedurally.

## How It Works

### Shader (`shaders/palette_swap.gdshader`)

```glsl
shader_type canvas_item;

uniform vec4 body_src   : source_color = vec4(0.12, 0.56, 1.00, 1.0);
uniform vec4 armor_src  : source_color = vec4(1.00, 0.84, 0.00, 1.0);
uniform vec4 body_dst   : source_color = vec4(0.12, 0.56, 1.00, 1.0);
uniform vec4 armor_dst  : source_color = vec4(1.00, 0.84, 0.00, 1.0);
uniform float threshold : hint_range(0.0, 0.5) = 0.18;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    if (col.a < 0.01) { COLOR = col; return; }          // skip transparent pixels
    if (distance(col.rgb, body_src.rgb) < threshold) {
        COLOR = vec4(body_dst.rgb, col.a);              // replace body color
    } else if (distance(col.rgb, armor_src.rgb) < threshold) {
        COLOR = vec4(armor_dst.rgb, col.a);             // replace armor color
    } else {
        COLOR = col;                                     // pass through unchanged
    }
}
```

`distance(a, b)` in GLSL computes Euclidean distance in 3D RGB space: `sqrt((r1-r2)² + (g1-g2)² + (b1-b2)²)`. At `threshold = 0.18`, colors within 18% of the source in RGB space are replaced. This tolerates minor anti-aliasing gradients at color boundaries while remaining tight enough to avoid false positives between visually distinct colors.

The source colors (`body_src`, `armor_src`) are set once and never change — they match the exact colors painted into the texture. Only the destination uniforms (`body_dst`, `armor_dst`) change per palette.

### Palette Definitions (`scripts/main.gd`)

```gdscript
const PALETTES := [
    {"name": "Original", "body": Color(0.12, 0.56, 1.00), "armor": Color(1.00, 0.84, 0.00)},
    {"name": "Crimson",  "body": Color(0.85, 0.12, 0.12), "armor": Color(0.75, 0.75, 0.80)},
    {"name": "Forest",   "body": Color(0.15, 0.65, 0.20), "armor": Color(0.60, 0.38, 0.15)},
    {"name": "Void",     "body": Color(0.50, 0.10, 0.80), "armor": Color(0.90, 0.90, 0.95)},
    {"name": "Lava",     "body": Color(0.90, 0.40, 0.05), "armor": Color(0.20, 0.20, 0.20)},
]
```

### Applying a Palette

```gdscript
func _apply_palette() -> void:
    var p := PALETTES[_palette_idx]
    _mat.set_shader_parameter("body_dst",  p["body"])
    _mat.set_shader_parameter("armor_dst", p["armor"])
    _pal_label.text = "Palette: %s (%d/%d)" % [p["name"], _palette_idx + 1, PALETTES.size()]
```

`ShaderMaterial.set_shader_parameter(name, value)` pushes a new uniform value to the GPU. The change takes effect on the next render frame. This is a single GPU state update per palette switch — no texture uploads, no scene changes.

### Procedural Texture (`_build_texture`)

The character texture is built entirely with `Image.set_pixel()`:

```gdscript
func _build_texture() -> ImageTexture:
    var img := Image.create(32, 56, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    var body_c  := Color(0.12, 0.56, 1.00)   # must exactly match body_src in shader
    var armor_c := Color(1.00, 0.84, 0.00)   # must exactly match armor_src in shader
    var skin_c  := Color(0.90, 0.75, 0.60)   # not replaced by shader

    # Head (skin colored, rows 0-15)
    for y in range(0, 16):
        for x in range(8, 24):
            img.set_pixel(x, y, skin_c)
    # Armor collar (rows 16-17)
    for x in range(8, 24):
        img.set_pixel(x, 16, armor_c)
        img.set_pixel(x, 17, armor_c)
    # Body (rows 18-45)
    for y in range(18, 46):
        for x in range(8, 24):
            img.set_pixel(x, y, body_c)
    # Belt (rows 34-35 of body, overwritten with armor)
    for x in range(8, 24):
        img.set_pixel(x, 34, armor_c)
        img.set_pixel(x, 35, armor_c)
    return ImageTexture.create_from_image(img)
```

The key constraint: pixel colors in the texture **must exactly match** `body_src` and `armor_src` in the shader. If there is a mismatch — even by floating-point rounding — the shader's distance test may fail. In production, use a color-indexed or hand-painted texture with exact flat colors (no anti-aliasing, no gradients near swap regions).

## RGB Distance vs Palette Index

An alternative technique is palette-index swapping: the texture stores index values (0–255) rather than colors, and a palette texture maps indices to colors. This allows unlimited palette entries with no distance tolerance issues, but requires a different texture format and a slightly more complex shader.

| Technique | Pros | Cons |
|-----------|------|------|
| RGB distance (this demo) | Works with any flat-color texture | Threshold tuning; fails on gradients |
| Palette index | Exact replacement; scales to many colors | Special texture format required |

For pixel art with flat colors and no anti-aliasing, the RGB distance approach is sufficient and simpler to set up. Use palette-index for detailed sprites with many replacement regions.

## How to Adapt This in Your Project

- **More regions**: add `uniform vec4 hair_src`/`hair_dst` pairs for additional swap regions. Each additional check costs a small GPU instruction count — negligible for a handful of regions.
- **Runtime customization**: expose `body_dst` and `armor_dst` in your character creation screen. Let players pick colors from a palette picker and call `set_shader_parameter` directly.
- **Status effects**: briefly swap to a red tint (damage flash) or white tint (invincibility) by temporarily changing `body_dst` and restoring it after a timer.
- **Team colors**: store faction palettes in a resource array. Apply the correct palette when a unit changes faction.
- **Animated palette**: change `body_dst` each frame using `Color.from_hsv(fmod(Time.get_ticks_msec() * 0.001, 1.0), 1.0, 1.0)` for a rainbow cycling effect.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ShaderMaterial.set_shader_parameter(name, value)` | Update a shader uniform at runtime |
| `Image.create(w, h, mipmaps, format)` | Create an image buffer in memory |
| `Image.fill(color)` | Fill all pixels with a color |
| `Image.set_pixel(x, y, color)` | Set a specific pixel |
| `ImageTexture.create_from_image(img)` | Upload an `Image` to the GPU as a texture |
| `distance(a, b)` | GLSL: Euclidean distance in RGB space |
| `texture(TEXTURE, UV)` | GLSL: sample the sprite's texture |

## Controls

| Input | Action |
|-------|--------|
| **Right arrow / Enter** | Next palette |
| **Left arrow** | Previous palette |

## Palettes

| Name | Body | Armor |
|------|------|-------|
| Original | Blue | Gold |
| Crimson | Red | Silver |
| Forest | Green | Brown |
| Void | Purple | White |
| Lava | Orange | Dark gray |

## Key Constants

```gdscript
# In shader:
uniform float threshold : hint_range(0.0, 0.5) = 0.18;
# 0.18 = tolerate colors within 18% Euclidean RGB distance of source

# In script — source colors must exactly match shader body_src / armor_src:
var body_c  := Color(0.12, 0.56, 1.00)
var armor_c := Color(1.00, 0.84, 0.00)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Palette definitions, texture construction, shader parameter updates |
| `shaders/palette_swap.gdshader` | Fragment shader with RGB distance color replacement |
| `scenes/main.tscn` | Root with TextureRect (ShaderMaterial applied), CanvasLayer HUD |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- The shader in `shaders/` is self-contained: assign it to a `ShaderMaterial` on any `CanvasItem` and set the uniforms.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

