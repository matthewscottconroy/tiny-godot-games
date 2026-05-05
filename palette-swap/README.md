# Palette Swap

A fragment shader that replaces specific source colors with destination colors by RGB distance comparison. Cycle through 5 character palettes with the arrow keys — the shader changes armor and body color without touching the texture.

## Purpose

Palette swapping is the classic technique for character color variants (player 1 vs player 2, alternate costumes, team colors). The GPU approach: for each pixel, compute distance to each source color; if close enough, substitute the destination color. No extra textures or draw calls needed.

## Controls

- **Left / Right arrows or Enter**: Cycle through palettes

## Palettes

| Name | Body | Armor |
|------|------|-------|
| Original | Blue | Gold |
| Crimson | Red | Silver |
| Forest | Green | Brown |
| Void | Purple | White |
| Lava | Orange | Dark |

## How It Works

### `shaders/palette_swap.gdshader`

```glsl
void fragment() {
    vec4 col = texture(TEXTURE, UV);
    if (col.a < 0.01) { COLOR = col; return; }
    if (distance(col.rgb, body_src.rgb) < threshold) {
        COLOR = vec4(body_dst.rgb, col.a);
    } else if (distance(col.rgb, armor_src.rgb) < threshold) {
        COLOR = vec4(armor_dst.rgb, col.a);
    } else {
        COLOR = col;
    }
}
```

`distance()` in GLSL computes Euclidean distance in RGB space. `threshold` controls how precisely colors must match — higher values tolerate anti-aliasing gradients.

### Swapping at runtime (`scripts/main.gd`)

```gdscript
func _apply_palette() -> void:
    var p := PALETTES[_palette_idx]
    _mat.set_shader_parameter("body_dst",  p["body"])
    _mat.set_shader_parameter("armor_dst", p["armor"])
```

Only the destination colors change per palette — the source colors stay constant (matching the original texture). This means one shader handles all palettes.

### Procedural texture

The character texture is built at runtime using `Image.set_pixel()` — no PNG file needed. The specific colors in the image must exactly match `body_src` and `armor_src` in the shader (within `threshold`).

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ShaderMaterial.set_shader_parameter(name, value)` | Change uniform at runtime |
| `Image.create(w, h, mipmaps, format)` | Create image buffer in code |
| `ImageTexture.create_from_image(img)` | Upload image to GPU as texture |
| `distance(a.rgb, b.rgb)` | GLSL: Euclidean color distance |
