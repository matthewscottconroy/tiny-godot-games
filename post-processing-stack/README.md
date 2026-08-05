# Post Processing Stack

Demonstrates a composable post-processing pipeline in Godot 4.2 using a canvas_item shader that reads the screen texture. An animated game scene is rendered first, then a full-screen ColorRect applies vignette, chromatic aberration, and color grading — each independently togglable at runtime.

## Controls

| Input | Action |
|-------|--------|
| 1 | Toggle vignette |
| 2 | Toggle chromatic aberration |
| 3 | Toggle color grading |

## Effects

| Effect | Technique |
|--------|-----------|
| Vignette | `1 - dot(uv - 0.5, uv - 0.5) * k` darkens screen edges |
| Chromatic aberration | R/G/B channels sampled at slightly offset UVs along the radial direction |
| Color grading | Tint multiply followed by gamma curve `pow(col, γ)` |

## Concepts

- **`hint_screen_texture`** — reads the composited scene into the shader; requires the ColorRect to render after all scene content
- **`mouse_filter = 2`** (IGNORE) — prevents the overlay from blocking input to nodes behind it
- **Additive shader stack** — each effect reads from the same source; ordering matters for correct composition
- **Uniform toggles** — `bool` shader uniforms skip effect branches at zero cost when disabled
