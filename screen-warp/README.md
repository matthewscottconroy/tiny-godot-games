# Screen Warp

Applies a sinusoidal UV displacement shader to the entire rendered game world by compositing it through a `SubViewport` and attaching a `canvas_item` shader to the `SubViewportContainer`.

## Purpose

Screen-space warp effects — heat haze, underwater ripple, psychic distortion, portal edges — require displacing the entire rendered image, not individual sprites. A per-sprite shader only distorts that sprite's pixels. A SubViewport-based post-process shader distorts the complete composited scene.

This technique appears in almost every modern 2D game with environmental atmosphere: heat shimmer rising from desert floors, the screen bending around a shockwave, the visual echo of a speed-boost dash, or the warped appearance of a magical barrier. This demo shows the minimal viable setup: a world rendered into a SubViewport, with a runtime-compiled GDScript shader distorting the container.

## How It Works

### Scene Structure

```
Main (Control) [warp_control.gd]
└── WarpContainer (SubViewportContainer) ← ShaderMaterial here
    └── WorldViewport (SubViewport, 640×480, update_mode=ALWAYS)
        └── World (Node2D) [main.gd]    ← bouncing balls, checkerboard
```

The world renders normally inside `WorldViewport`. `WarpContainer` displays it and applies the shader.

### World Content (`scripts/main.gd`)

Five bouncing balls with independent velocities, wall reflection, a checkerboard background, animated decorative rings, and a grid overlay. The grid lines are essential — they make the UV displacement clearly visible because straight lines become wavy curves under the warp.

```gdscript
for x in range(0, 641, 80):
    draw_line(Vector2(x, 0), Vector2(x, 480), Color(0.35, 0.35, 0.45, 0.5), 1.0)
for y in range(0, 481, 60):
    draw_line(Vector2(0, y), Vector2(640, y), Color(0.35, 0.35, 0.45, 0.5), 1.0)
```

### Shader Construction at Runtime (`scripts/warp_control.gd`)

```gdscript
func _ready() -> void:
    var shader := Shader.new()
    shader.code = """
shader_type canvas_item;
uniform float time = 0.0;
uniform float strength = 0.02;
uniform float speed = 2.0;
void fragment() {
    vec2 uv = UV;
    uv.x += sin(uv.y * 20.0 + time * speed) * strength;
    uv.y += cos(uv.x * 20.0 + time * speed * 0.7) * strength;
    COLOR = texture(TEXTURE, uv);
}
"""
    _material = ShaderMaterial.new()
    _material.shader = shader
    _container.material = _material
```

The shader is compiled from a string — no `.gdshader` file required. `TEXTURE` in a `canvas_item` shader is automatically bound to the CanvasItem's texture, which for a `SubViewportContainer` is the SubViewport's render output.

### Uniform Update Each Frame

```gdscript
func _process(delta: float) -> void:
    _time += delta
    _material.set_shader_parameter("time", _time)
    _material.set_shader_parameter("strength", _warp_strength if _warp_enabled else 0.0)
    _material.set_shader_parameter("speed", _warp_speed)
```

Godot's built-in `TIME` shader uniform resets on shader recompile and cannot be paused. A manually accumulated `_time` variable gives full control over animation state, including the ability to pause or slow it independently of real time.

## UV Displacement Technique

### Math

The shader displaces UV coordinates before sampling:

```glsl
uv.x += sin(uv.y * 20.0 + time * speed) * strength;
uv.y += cos(uv.x * 20.0 + time * speed * 0.7) * strength;
```

`uv.y * 20.0` controls horizontal wave frequency — higher values create more ripples vertically. `time * speed` advances the wave phase over time, making it animate. `strength` is the amplitude of the displacement in UV space (0.02 = 2% of the texture width per wave peak).

Using the **original** UV in the sin/cos arguments (not the displaced UV) keeps the displacement independent on each axis. If you used `uv.x` after the x-displacement in the y-displacement formula, you'd get a feedback loop that distorts non-linearly.

### No Edge Clamping

Unlike `distort.gdshader` (screen-distortion demo), this shader does not `clamp(uv, 0.0, 1.0)`. UV coordinates outside [0,1] will sample the edge pixels of the SubViewport texture (edge wrap behavior depends on the texture's repeat mode). This can produce a subtle border artifact at high strength values, which is usually acceptable for heat haze effects.

### Strength Range

| `strength` | Visual effect |
|------------|---------------|
| 0.000 | Off — no distortion |
| 0.010 | Barely perceptible shimmer |
| 0.020 | Default — subtle heat haze |
| 0.060 | Obvious liquid distortion |
| 0.150 | Maximum — severe warp |

## How to Adapt This in Your Project

- **Heat haze over ground**: Apply the shader only to the bottom third of the screen by masking `strength *= step(0.6, UV.y)` inside the shader.
- **Radial warp from explosion**: Replace the sin/cos with a radial formula: offset toward or away from a UV center point based on `distance(UV, center)`.
- **Portal/bubble distortion**: Apply the shader to a `ColorRect` sized to the portal area instead of the full-screen container.
- **Pause warp on freeze**: Stop advancing `_time` while the game is paused. The warp freezes in place.
- **Pitfall**: Setting `strength` above ~0.08 with `speed` above 3.0 causes chaotic, illegible distortion. The human eye resolves warp as intentional texture up to about ±5% UV displacement; beyond that it reads as glitch.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SubViewport` | Renders world to an offscreen texture |
| `SubViewportContainer` | Displays SubViewport texture; accepts ShaderMaterial |
| `Shader.new()` + `shader.code = "..."` | Compile a shader from a string at runtime |
| `ShaderMaterial.set_shader_parameter(name, value)` | Update a uniform each frame |
| `TEXTURE` (canvas_item shader built-in) | The CanvasItem's texture (SubViewport output) |
| `UV` (canvas_item shader built-in) | 0..1 coordinates across the container |

## Controls

| Key | Action |
|-----|--------|
| W | Toggle warp on / off |
| + / = | Increase warp strength (+0.005) |
| - | Decrease warp strength (min 0.0) |
| Up Arrow | Increase warp speed (+0.5) |
| Down Arrow | Decrease warp speed (min 0.1) |

## Key Constants / Shader Parameters

```glsl
// Shader uniforms (set via set_shader_parameter):
uniform float time     = 0.0;   // manually accumulated, not Godot's TIME
uniform float strength = 0.02;  // UV displacement amplitude (0.0–0.15)
uniform float speed    = 2.0;   // phase advance rate (radians/sec equivalent)

// GDScript defaults:
_warp_strength: float = 0.02
_warp_speed:    float = 2.0
min_strength    = 0.0
max_strength    = 0.15   (min(0.15, ...))
min_speed       = 0.1
max_speed       = 10.0
```

## Files

| File | Purpose |
|------|---------|
| `scripts/warp_control.gd` | Shader construction, uniform updates, strength/speed controls, HUD |
| `scripts/main.gd` | Animated world: bouncing balls, checkerboard, grid lines |
| `scenes/main.tscn` | SubViewportContainer → WorldViewport → World hierarchy |
| `tests/test.tscn` | Tests for UV displacement math and warp parameter bounds |
