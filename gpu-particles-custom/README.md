# GPU Particles Custom

Fragment shader that procedurally simulates 80 particles entirely on the GPU — no CPU particle state. Each particle's position is computed analytically from a seed and time uniform, making it zero-overhead regardless of particle count.

## Controls

| Input | Action |
|-------|--------|
| Space | Cycle through presets |

## Presets

| Preset | Behaviour |
|--------|-----------|
| Curl Noise | Particles flow along the curl of a 2D noise field |
| Radial Orbit | Particles orbit the center at varying radii and speeds |
| Swarm | Particles converge on a moving target with wobble |

## Concepts

- **Fragment-only particles** — no vertex buffers; each texel tests proximity to all 80 particles
- **Procedural position** — `hash(seed)` for initial placement, analytic position function from `time` uniform
- **Curl noise** — `∇ × F` approximation: perpendicular gradient of a scalar field gives divergence-free flow
- **Additive glow** — `brightness = k / (d² + ε)` accumulates over all particles
- **Preset switching** — `preset` uniform selects field type; GDScript resets `time` on switch
