# GPU Particles Custom

Fragment shader that procedurally simulates 80 particles entirely on the GPU — no CPU particle state. Each particle's position is computed analytically from a seed and time uniform, making it zero-overhead regardless of particle count.

## Purpose

Once particle counts get large, keeping per-particle state on the CPU is the bottleneck. If each particle's position is a pure function of time and its index, the fragment shader can derive every particle independently with no state at all. This demo simulates 80 particles analytically in the shader — no arrays, no per-frame updates — to show where that trade pays off and where it stops being practical.

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

## How It Works

- **Fragment-only particles** — no vertex buffers; each texel tests proximity to all 80 particles
- **Procedural position** — `hash(seed)` for initial placement, analytic position function from `time` uniform
- **Curl noise** — `∇ × F` approximation: perpendicular gradient of a scalar field gives divergence-free flow
- **Additive glow** — `brightness = k / (d² + ε)` accumulates over all particles
- **Preset switching** — `preset` uniform selects field type; GDScript resets `time` on switch

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scenes/main.tscn` | The runnable scene |
| `shaders/particles.gdshader` | Shader source |
| `tests/test_logic.gd` | Headless test suite |

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ShaderMaterial` | Carries the fragment shader that derives every particle |
| `ShaderMaterial.set_shader_parameter()` | Feed time and tuning into the shader |
| `TIME` (shader built-in) | The only per-frame state the simulation needs |
| `UV` (shader built-in) | Screen position used to test against each particle |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- The shader in `shaders/` is self-contained: assign it to a `ShaderMaterial` on any `CanvasItem` and set the uniforms.

