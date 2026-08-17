# Shader Intro

Introduces Godot's `ShaderMaterial` and GLSL shaders for 2D: three visual effects (tint, hit-flash, outline) applied to a sprite by swapping materials at runtime.

## Purpose

Shaders are GPU programs that control how pixels are colored. Most visual effects in modern games — outlines, glows, heat distortion, color grading, dissolves — are implemented as shaders. This demo shows the minimal structure of a canvas item shader, how shader parameters are set from GDScript, and how to animate them using Tween.

## Controls

- **None button**: Remove shader (raw sprite)
- **Tint button**: Apply a red color tint
- **Flash button**: Apply a white flash (animated via Tween)
- **Outline button**: Apply a yellow pixel-art outline

## How It Works

### Node Tree

```
Main (Control)              ← main.gd
├── SpriteAnchor (Control)
│   └── Sprite2D            (displays the sprite with the current shader)
├── ModeLabel (Label)
└── Buttons (HBoxContainer)
    ├── NoneBtn, TintBtn, FlashBtn, OutlineBtn
```

### `scripts/main.gd`

Each button calls `_set_mode(ShaderMode.X)`, which loads the corresponding shader file and assigns it as a `ShaderMaterial` on the sprite:

```gdscript
func _set_mode(new_mode: ShaderMode) -> void:
    var path := SHADERS[mode]
    if path.is_empty():
        sprite.material = null
    else:
        var mat := ShaderMaterial.new()
        mat.shader = load(path)
        sprite.material = mat
```

A new `ShaderMaterial` is created each time. `ShaderMaterial` holds a reference to a `Shader` resource and stores parameter values.

**Flash animation:**
```gdscript
func _trigger_flash() -> void:
    var mat := sprite.material as ShaderMaterial
    var tween := create_tween()
    tween.tween_method(func(v: float): mat.set_shader_parameter("flash_amount", v), 1.0, 0.0, 0.4)
```

`tween_method` calls a callable with a lerped float value at each frame. Here it animates `flash_amount` from 1.0 (fully white) to 0.0 (normal) over 0.4 seconds.

## Shader Theory

### GLSL and canvas_item Shaders

Godot's shaders are written in **GLSL** (OpenGL Shading Language) with Godot-specific extensions. Every shader starts with a type declaration:
```glsl
shader_type canvas_item;
```
This tells Godot the shader is for 2D sprites, CanvasItems, and UI nodes.

### The fragment() Function

```glsl
void fragment() {
    vec4 col = texture(TEXTURE, UV);
    COLOR = col;
}
```

`fragment()` runs once per pixel of the drawn object. It has access to:
- `TEXTURE` — the sprite's texture
- `UV` — normalized texture coordinates (0,0 = top-left, 1,1 = bottom-right)
- `COLOR` — output color to write (vec4: R, G, B, A)

The default (no shader) is equivalent to `COLOR = texture(TEXTURE, UV)`.

### `shaders/tint.gdshader`

```glsl
uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float mix_amount : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    COLOR = vec4(mix(col.rgb, tint_color.rgb, mix_amount * col.a), col.a);
}
```

`uniform` variables are parameters set from GDScript. The `source_color` hint makes Godot show a color picker in the Inspector. `mix(a, b, t)` linearly interpolates from `a` to `b` by factor `t`. Multiplying by `col.a` preserves transparency — transparent pixels are not tinted.

### `shaders/flash.gdshader`

```glsl
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    COLOR = vec4(mix(col.rgb, vec3(1.0), flash_amount * col.a), col.a);
}
```

`mix(col.rgb, vec3(1.0), amount)` blends the sprite's colors toward pure white. At `flash_amount = 1.0`, the entire sprite is white. At `0.0`, it is the original color. Animating this creates the classic "hit flash" effect.

### `shaders/outline.gdshader`

```glsl
uniform vec4 outline_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_size : hint_range(0.0, 8.0) = 2.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    vec2 texel = outline_size / vec2(textureSize(TEXTURE, 0));

    float alpha = col.a;
    alpha = max(alpha, texture(TEXTURE, UV + vec2(texel.x, 0.0)).a);
    alpha = max(alpha, texture(TEXTURE, UV + vec2(-texel.x, 0.0)).a);
    alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, texel.y)).a);
    alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, -texel.y)).a);

    vec4 border = vec4(outline_color.rgb, alpha * outline_color.a);
    COLOR = mix(border, col, col.a);
}
```

The outline algorithm samples the texture at four offsets (left, right, up, down). If any neighbor pixel has nonzero alpha but the current pixel does not, this pixel is on the outline. `mix(border, col, col.a)` draws the original sprite on top of the outline.

### ShaderMaterial vs BaseMaterial3D

`ShaderMaterial` lets you write custom shader code. `StandardMaterial3D` / `CanvasItemMaterial` provide a GUI-driven shader without writing code. For custom effects, `ShaderMaterial` is required.

### set_shader_parameter()

```gdscript
mat.set_shader_parameter("flash_amount", 0.75)
```

This sets the `uniform float flash_amount` in the shader. The string must match the uniform name exactly. Type must be compatible (float for `float`, `Color` for `vec4 : source_color`).

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ShaderMaterial.new()` | Create a material for custom shaders |
| `ShaderMaterial.shader` | Assign a Shader resource |
| `ShaderMaterial.set_shader_parameter(name, value)` | Set a uniform value |
| `Sprite2D.material` | Assign a material to a sprite |
| `Tween.tween_method(callable, from, to, time)` | Animate via a function call |
| `load("res://shaders/x.gdshader")` | Load a shader resource |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scenes/main.tscn` | The runnable scene |
| `shaders/flash.gdshader` | Shader source |
| `shaders/outline.gdshader` | Shader source |
| `shaders/tint.gdshader` | Shader source |
| `assets/character.svg` | Source art, imported as a texture |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- The shaders in `shaders/` are self-contained: assign them to a `ShaderMaterial` on any `CanvasItem` and set the uniforms.

## Related demos

- [shader-effects](../shader-effects) — Applied shaders: dissolve, pixelate, and wave-warp.
- [2d-water](../2d-water) — An animated water surface shader with distortion, foam, and shimmer.
- [gpu-particles-custom](../gpu-particles-custom) — 80 particles simulated analytically in a fragment shader — no CPU state.
- [palette-swap](../palette-swap) — A shader replacing source colors with destination colors by RGB distance.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

