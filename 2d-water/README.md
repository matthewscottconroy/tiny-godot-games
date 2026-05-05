# 2D Water

An animated water surface using a `canvas_item` shader on a `ColorRect`. Features UV-distorted waves, depth-based color gradient, foam at the surface, and shimmer highlights. The player can swim through the water with reduced gravity and drag.

## Purpose

Water is one of the most visually impactful environmental effects in 2D games. The Godot approach uses a `canvas_item` shader on a `ColorRect` (or any CanvasItem) — no separate rendering pipeline needed. This demo shows the full technique: wave distortion via UV offset, `TIME`-driven animation, depth tinting, and noise-based foam. Sliders let you tweak wave speed and amplitude in real time.

## Controls

- **Arrow keys / WASD**: Move, Up to jump
- **Jump into the water**: Player slows down (drag), reduced gravity, swim up with Up key
- **Sliders**: Adjust wave speed and amplitude live

## How It Works

### `shaders/water.gdshader`

**Wave distortion:**
```glsl
float wave1 = sin(UV.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
float wave2 = sin(UV.x * wave_frequency * 1.7 - TIME * wave_speed * 0.8) * wave_amplitude * 0.5;
vec2 uv_warp = UV + vec2(wave1 + wave2, wave1 * 0.5);
```
Two sine waves at different frequencies are combined to avoid the regular look of a single wave. `TIME` advances the phase so the pattern animates continuously.

**Depth gradient:**
```glsl
float depth = UV.y;
vec4 base_color = mix(water_color, deep_color, depth * 0.7);
```
`UV.y` runs from 0 at the top of the `ColorRect` to 1 at the bottom. Lerping between surface blue and deep navy creates the underwater depth effect.

**Foam:**
```glsl
float foam_mask = step(foam_threshold, foam_noise) * smoothstep(0.2, 0.0, UV.y);
```
Noise values above `foam_threshold` become foam. `smoothstep(0.2, 0.0, UV.y)` masks foam to the top 20% of the water surface — deeper water has no foam.

### Inline shader in `.tscn`

The shader is embedded directly in the scene file as a `Shader` sub-resource and assigned to a `ShaderMaterial`. This avoids a separate `.gdshader` file while keeping the scene self-contained. The `.gdshader` file in `shaders/` has the same code for readability.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ColorRect` with `ShaderMaterial` | Renders shader over a rectangular area |
| `TIME` (GLSL built-in) | Seconds since render start — drives animation |
| `UV` (GLSL built-in) | 0..1 texture coordinates across the CanvasItem |
| `smoothstep(edge0, edge1, x)` | Smooth transition between 0 and 1 |
| `ShaderMaterial.set_shader_parameter()` | Update uniforms at runtime |
