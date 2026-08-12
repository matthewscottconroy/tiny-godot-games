# 2D Water

An animated water surface rendered with a `canvas_item` shader on a `ColorRect` — featuring dual sine-wave UV distortion, depth-based color gradient, noise-generated foam at the surface, and shimmer highlights. The player can walk into and swim through the water with modified physics.

## Purpose

A convincing water surface is one of the most requested visual effects in 2D games. Platformers (Hollow Knight, Shovel Knight, Celeste), adventure games, and RPGs all feature water that needs to look animated without expensive rendering. Godot's `canvas_item` shader on a `ColorRect` is the right tool: it requires no 3D rendering pipeline, costs one draw call, and gives complete control over the visual.

This demo covers the full stack: the shader with overlapping wave distortion, depth tinting, noise-based foam, and shimmer highlights; a GDScript physics simulation for swimming; and live slider controls so you can tune wave speed and amplitude in real time and immediately see how each parameter affects the look.

## How It Works

### Water Shader (`shaders/water.gdshader`)

#### Dual-Wave UV Distortion

```glsl
float wave1 = sin(UV.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
float wave2 = sin(UV.x * wave_frequency * 1.7 - TIME * wave_speed * 0.8) * wave_amplitude * 0.5;
vec2 uv_warp = UV + vec2(wave1 + wave2, wave1 * 0.5);
```

Two sine waves with different frequencies (1.0× and 1.7×) and opposite phase directions (+TIME vs −TIME) are summed. Their combined pattern has an irregular beat frequency that prevents the periodic regularity of a single wave. `uv_warp` is then used for subsequent noise lookups, creating spatially-coherent but time-varying foam and shimmer positions.

#### Depth Gradient

```glsl
float depth = UV.y;
vec4 base_color = mix(water_color, deep_color, depth * 0.7);
```

`UV.y` is 0 at the top edge of the `ColorRect` and 1 at the bottom. `mix(water_color, deep_color, depth * 0.7)` blends from the surface blue to deep navy as depth increases. The `0.7` multiplier means even at the very bottom (`depth=1.0`) only 70% deep color is reached — the deep color never fully dominates, keeping the surface tint visible.

#### Noise-Based Foam

```glsl
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);   // smoothstep curve
    return mix(
        mix(hash(i), hash(i + vec2(1,0)), f.x),
        mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x),
        f.y
    );
}

float foam_noise = noise(uv_warp * 10.0 + TIME * 0.3);
float foam_mask  = step(foam_threshold, foam_noise) * smoothstep(0.2, 0.0, UV.y);
```

A value noise implementation generates continuous random values in [0,1]. The foam threshold test (`step(foam_threshold, foam_noise)`) turns pixels white where noise exceeds the threshold — approximately `(1 - foam_threshold) * 100%` of the surface area. `smoothstep(0.2, 0.0, UV.y)` multiplies foam by 1.0 at `UV.y=0` (surface) and fades to 0.0 at `UV.y=0.2` (20% depth). Foam only appears near the surface.

#### Shimmer Highlights

```glsl
float shimmer = noise(uv_warp * 14.0 + vec2(TIME * 0.6, 0.0));
float highlight = pow(shimmer, 4.0) * 0.4 * (1.0 - depth);
final.rgb += highlight;
```

A second, higher-frequency noise pass produces the bright sunlight glint on the surface. `pow(shimmer, 4.0)` sharpens the distribution — most pixels get near-zero shimmer, but a few get bright highlights. Multiplied by `(1 - depth)`, highlights are strongest at the surface and absent at depth.

### Player Swimming Physics (`scripts/main.gd`)

```gdscript
_in_water = _player_pos.y + 14 > WATER_Y   # detect submersion

var grav := GRAVITY * (0.2 if _in_water else 1.0)   # reduced gravity in water
var speed := SPEED * (0.4 if _in_water else 1.0)    # reduced movement speed

if _in_water:
    _vel *= 0.85    # water drag: 85% velocity retained per frame (~15%/frame loss)

if _in_water and Input.is_action_just_pressed("ui_up"):
    _vel.y = JUMP_VEL * 0.55    # swim upward (weaker than land jump)
```

The transition from air to water physics is immediate when the player's center (plus 14px body offset) crosses `WATER_Y = 260.0`. Three changes apply: gravity drops to 20% (buoyancy effect), movement speed drops to 40%, and per-frame drag of 0.85 prevents sustained high speed. The player turns blue while submerged.

### Live Parameter Control (`scripts/main.gd`)

```gdscript
$HUD/SpeedSlider.value_changed.connect(func(v: float) -> void:
    _water_mat.set_shader_parameter("wave_speed", v)
)
$HUD/AmpSlider.value_changed.connect(func(v: float) -> void:
    _water_mat.set_shader_parameter("wave_amplitude", v)
)
```

Sliders in a `CanvasLayer` HUD connect directly to shader uniform updates via lambda functions. This keeps the binding code local to `_ready()` and avoids separate callback functions for each slider.

## How to Adapt This in Your Project

- **Moving water surface**: Place the `ColorRect` at the water surface level in your scene. Adjust `WATER_Y` in GDScript to match its y-position.
- **Transparent water**: Reduce `water_color.a` and `deep_color.a` in the shader uniforms. Set the ColorRect's `modulate.a` or use a semi-transparent shader color to see the sea floor beneath.
- **Multiple water depths**: Layer two `ColorRect` water nodes at different y positions with different `deep_color` values. A shallow rock pool looks different from a deep ocean.
- **Underwater tint**: Use a second full-screen `ColorRect` with a blue-tinted semi-transparent material as an overlay when `_in_water` is true. Tween its alpha on entry/exit.
- **Pitfall**: `TIME` in Godot shaders resets when the shader is recompiled during development. Use the Godot editor's "Reload Saved Shaders" if waves appear to freeze after editing the shader file.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ColorRect` with `ShaderMaterial` | Renders shader across a rectangular region |
| `TIME` (GLSL built-in) | Seconds since render start — drives all animation |
| `UV` (canvas_item GLSL built-in) | 0..1 coordinates across the ColorRect |
| `smoothstep(edge0, edge1, x)` | Smooth 0-to-1 transition, used for foam depth mask |
| `step(threshold, x)` | Hard 0/1 threshold, used for foam presence |
| `mix(a, b, t)` | Linear interpolation, used for depth gradient |
| `ShaderMaterial.set_shader_parameter()` | Update uniforms at runtime from slider callbacks |

## Controls

| Key / Input | Action |
|-------------|--------|
| Arrow keys | Move player |
| Up / W | Jump (on ground) or swim up (in water) |
| Wave Speed slider | Adjusts `wave_speed` uniform (0.1–5.0) |
| Wave Amplitude slider | Adjusts `wave_amplitude` uniform (0–0.05) |

## Key Constants

```glsl
// water.gdshader — tunable uniforms
uniform float wave_speed     : hint_range(0.1, 5.0)  = 1.2;   // phase advance rate
uniform float wave_amplitude : hint_range(0.0, 0.05) = 0.018; // UV displacement per wave
uniform float wave_frequency : hint_range(1.0, 20.0) = 6.0;   // cycles per screen width
uniform float foam_threshold : hint_range(0.0, 1.0)  = 0.85;  // noise threshold for foam
uniform vec4  water_color    = vec4(0.05, 0.35, 0.75, 0.88);  // surface blue
uniform vec4  deep_color     = vec4(0.02, 0.15, 0.45, 1.0);   // deep navy
uniform vec4  foam_color     = vec4(0.8,  0.9,  1.0,  0.95);  // foam white
```

```gdscript
// main.gd — physics constants
const WATER_Y   := 260.0   # Y position of water surface
const GRAVITY   := 900.0   # normal gravity (px/s²)
const SPEED     := 180.0   # normal horizontal speed
# In water: gravity * 0.2, speed * 0.4, vel *= 0.85 drag per frame
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Player physics, water detection, slider signal connections, world drawing |
| `shaders/water.gdshader` | Wave distortion, depth gradient, foam noise, shimmer highlights |
| `scenes/main.tscn` | Water ColorRect with embedded ShaderMaterial, player, HUD sliders |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- The shader in `shaders/` is self-contained: assign it to a `ShaderMaterial` on any `CanvasItem` and set the uniforms.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

