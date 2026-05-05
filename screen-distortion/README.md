# Screen Distortion

Full-screen post-process warp (heat haze) applied to the entire game world via a SubViewport + ShaderMaterial. The distortion shader offsets UV coordinates using sine/cosine waves driven by `TIME`.

## Purpose

Per-sprite shaders affect individual objects. Post-process effects affect everything rendered on screen — heat shimmer, underwater distortion, screen damage. The technique: render the game world into a SubViewport (which creates a Texture2D), then apply a full-screen shader to the SubViewportContainer that displays that texture.

## Controls

- **Arrow keys / WASD**: Move
- **Up**: Jump
- **Left / Right**: Cycle distortion intensity (Off / Subtle / Moderate / Heavy)

## How It Works

### Scene structure

```
SubViewportContainer (ShaderMaterial → distort.gdshader)
  SubViewport (renders the game world as a texture)
    Player, Floor, Platforms...
CanvasLayer
  HUD labels (immune to distortion)
```

The ShaderMaterial on `SubViewportContainer` receives the SubViewport's output as `TEXTURE` and warps its UVs before display.

### `shaders/distort.gdshader`

```glsl
void fragment() {
    vec2 uv = UV;
    uv.x += sin(uv.y * wave_freq * PI + TIME * speed) * strength;
    uv.y += cos(uv.x * wave_freq * PI + TIME * speed * 1.3) * strength * 0.6;
    uv = clamp(uv, vec2(0.0), vec2(1.0));
    COLOR = texture(TEXTURE, uv);
}
```

`TIME` is a built-in Godot shader uniform that increases each frame — the sine/cosine arguments change over time, creating the wave motion. `clamp` prevents UV from sampling outside [0,1] (which would wrap or stretch).

### Runtime control (`scripts/main.gd`)

```gdscript
_mat.set_shader_parameter("strength", STRENGTHS[_strength_idx])
```

Changing `strength` to 0.0 effectively disables the distortion.

### CanvasLayer immunity

Labels on a `CanvasLayer` are drawn after the SubViewportContainer and are not affected by the distortion shader. This is how HUDs stay readable while the game world warps.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SubViewport` | Renders scene to an offscreen texture |
| `SubViewportContainer` | Displays SubViewport; ShaderMaterial applies post-process |
| `TIME` (shader built-in) | Seconds since shader start — drives animation |
| `CanvasLayer` | Render layer immune to world-space effects |
