# Screen Distortion

Full-screen post-process heat-haze effect applied to the entire game world via a `SubViewport` + `ShaderMaterial`. A `canvas_item` shader displaces UV coordinates with sine/cosine waves driven by `TIME`, with four preset intensity levels switchable at runtime.

## Purpose

Per-object shaders distort individual sprites. Post-process effects distort everything on screen simultaneously — heat shimmer rising from hot pavement, the warped view through a fever hallucination, screen damage in an action game, the bent-light effect around a cloaked enemy. The technique is identical for all of them: render the entire game world into a SubViewport, then apply the distortion shader to the container that displays it.

This demo demonstrates the canonical Godot setup for any full-screen shader effect. The same pattern applies to color grading, chromatic aberration, vignette, scanlines, and CRT curvature — swap the shader, keep the SubViewport + CanvasLayer structure.

## How It Works

### Scene Structure

```
SubViewportContainer (ShaderMaterial → distort.gdshader)  [main.gd]
├── SubViewport (renders the game world)
│   ├── Player (CharacterBody2D)
│   ├── Floor (StaticBody2D)
│   └── Platforms
└── CanvasLayer (above distortion, immune to shader)
    └── StrLabel (Label showing current distortion level)
```

`SubViewportContainer` is the critical node. Its `ShaderMaterial` receives the SubViewport's output as `TEXTURE` and applies the warp before display. The `CanvasLayer` sits outside the SubViewport so its contents are drawn after the distortion shader and remain sharp.

### Distortion Shader (`shaders/distort.gdshader`)

```glsl
shader_type canvas_item;

uniform float strength  : hint_range(0.0, 0.08) = 0.025;
uniform float wave_freq : hint_range(1.0, 20.0) = 7.0;
uniform float speed     : hint_range(0.0, 5.0)  = 1.8;

void fragment() {
    vec2 uv = UV;
    uv.x += sin(uv.y * wave_freq * PI + TIME * speed) * strength;
    uv.y += cos(uv.x * wave_freq * PI + TIME * speed * 1.3) * strength * 0.6;
    uv = clamp(uv, vec2(0.0), vec2(1.0));
    COLOR = texture(TEXTURE, uv);
}
```

UV coordinates are displaced before the texture sample. The horizontal warp uses `sin` driven by the vertical UV position; the vertical warp uses `cos` driven by the horizontal UV position with a `0.7` speed multiplier relative to horizontal — this asymmetry prevents the effect from being perfectly symmetric and makes it look more like real heat shimmer.

`clamp(uv, 0.0, 1.0)` prevents the displaced UV from sampling outside the texture bounds. Without it, UV values slightly above 1.0 would wrap or stretch depending on the texture's repeat mode, producing visible artifacts at screen edges.

### Runtime Strength Control (`scripts/main.gd`)

```gdscript
const STRENGTHS := [0.0, 0.015, 0.04, 0.08]
const LABELS    := ["Off", "Subtle", "Moderate", "Heavy"]

var _strength_idx := 1

func _apply_strength() -> void:
    _mat.set_shader_parameter("strength", STRENGTHS[_strength_idx])
    _str_label.text = "Distortion: %s  (Left/Right to change)" % LABELS[_strength_idx]
```

`set_shader_parameter("strength", value)` updates the shader uniform at runtime without recompiling. Cycling through four discrete values (0.0, 0.015, 0.04, 0.08) covers the practical range from invisible to severe. At `strength = 0.0` the shader still runs but produces no visible displacement — toggling "Off" this way avoids the overhead of swapping materials.

## UV Displacement Technique

### Wave Frequency and Visual Result

`wave_freq * PI` in the sin/cos argument converts the wave count into radians across the [0,1] UV range. With `wave_freq = 7.0`:
- The horizontal warp completes `7` full sine cycles from top to bottom of the screen.
- Higher `wave_freq` = more ripples, shorter wavelength.
- Lower `wave_freq` = fewer ripples, longer, broader waves.

### Asymmetric Speed

```glsl
uv.x += sin(... + TIME * speed) * strength;
uv.y += cos(... + TIME * speed * 1.3) * strength * 0.6;
```

Horizontal and vertical waves run at different speeds (`speed` vs `speed * 1.3`) and different amplitudes (`strength` vs `strength * 0.6`). This asymmetry prevents the pattern from having obvious periodicity in time, making it look more organic. In pure heat haze, vertical shimmer is weaker than horizontal, which is why the vertical amplitude is 60% of horizontal.

### CanvasLayer Immunity

Nodes in a `CanvasLayer` are drawn directly to the screen compositing buffer, bypassing any material on the `SubViewportContainer`. The HUD label remains perfectly sharp even at "Heavy" distortion because it is never part of the distorted texture.

## How to Adapt This in Your Project

- **Color grading**: Replace the UV warp with a LUT lookup. `COLOR = texture(lut_texture, vec2(COLOR.r, 0.5))` applies a 1D color grade.
- **Chromatic aberration**: Sample `TEXTURE` three times at slightly offset UV for R, G, B channels separately.
- **Vignette**: Multiply `COLOR.rgb *= 1.0 - smoothstep(0.4, 0.8, distance(UV, vec2(0.5)))`.
- **Animated strength**: Drive `strength` from GDScript based on game state — ramp up during a heat vent encounter, ramp down over 2 seconds when the player moves away.
- **Pitfall**: SubViewport content must have `update_mode = ALWAYS` (mode 4) to render animated content every frame. Static scenes can use `ONCE` to save GPU time.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SubViewport` | Renders the game world to an offscreen texture |
| `SubViewportContainer` | Displays the SubViewport; its ShaderMaterial applies post-process |
| `TIME` (shader built-in) | Seconds since shader start, drives animation |
| `UV` (canvas_item shader built-in) | 0..1 coordinates across the container |
| `clamp(uv, vec2(0.0), vec2(1.0))` | Prevent UV from going out of bounds |
| `CanvasLayer` | Draws children after the SubViewportContainer, immune to distortion |
| `ShaderMaterial.set_shader_parameter()` | Update shader uniforms at runtime |

## Controls

| Key | Action |
|-----|--------|
| Arrow keys | Move player |
| Up / Space | Jump |
| Left / Right | Cycle distortion intensity |

## Key Constants

```glsl
// distort.gdshader
uniform float strength  : hint_range(0.0, 0.08) = 0.025;  // displacement amplitude in UV space
uniform float wave_freq : hint_range(1.0, 20.0) = 7.0;    // ripple frequency across screen
uniform float speed     : hint_range(0.0, 5.0)  = 1.8;    // animation rate

// GDScript presets
STRENGTHS = [0.0, 0.015, 0.04, 0.08]   // Off / Subtle / Moderate / Heavy
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Strength cycling, shader parameter updates, label text |
| `shaders/distort.gdshader` | UV displacement fragment shader |
| `scenes/main.tscn` | SubViewportContainer, SubViewport, Player, CanvasLayer/HUD |
| `tests/test.tscn` | Tests for shader parameter binding and strength preset values |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- The shader in `shaders/` is self-contained: assign it to a `ShaderMaterial` on any `CanvasItem` and set the uniforms.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

