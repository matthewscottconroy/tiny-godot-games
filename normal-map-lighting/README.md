# Normal Map Lighting

Procedural bump-map lighting demo. A canvas_item shader computes per-fragment surface normals using finite differences on a multi-frequency height field, then applies Phong diffuse shading with distance attenuation from a point light driven by the mouse cursor.

## Controls

| Input | Action |
|-------|--------|
| Mouse move | Move point light |
| R | Reset light to center |

## Concepts

- **Canvas item shader** — `shader_type canvas_item` for 2D full-screen effect
- **Procedural height field** — sum of sin/cos terms at multiple frequencies
- **Finite-difference normals** — forward-backward difference `(h(u+ε) - h(u-ε)) / 2ε` in X and Y
- **Diffuse lighting** — `max(dot(N, L), 0.0)` Lambertian model
- **Distance attenuation** — `1 / (1 + d² * k)` falloff
- **Shader uniforms** — `light_uv`, `light_color`, `light_radius`, `bump_strength`, `freq`
- **GDScript → shader** — `ShaderMaterial.set_shader_parameter()` each frame
