# Dissolve Effect

<!-- tags: procedural, shows-its-working -->

Implements a noise-threshold dissolve/appear transition on a grid of cells using a pre-baked random noise map and a moving threshold — no shader required.

## Purpose

Dissolve transitions are a staple of game death animations, ability activations, portal effects, and scene transitions. The canonical implementation uses a fragment shader that compares a noise texture against a threshold uniform. This demo reproduces the same visual in pure GDScript using a 2D grid, making the algorithm fully transparent and easy to port to shaders once understood.

Games using dissolves include every roguelike with procedural death animations, action RPGs with ability cast VFX (Dark Souls, Hades), and any game with stylized scene fade-outs. The key insight is that dissolve and appear are the same operation — just run in opposite directions.

## How It Works

### Data Setup (`scripts/main.gd`)

```gdscript
const COLS := 20
const ROWS := 15
const CELL_W := 16.0
const CELL_H := 16.0

func _ready() -> void:
    _noise_grid.resize(COLS * ROWS)
    for i in range(COLS * ROWS):
        _noise_grid[i] = randf()
```

Each of the 300 cells is assigned a permanent random float in [0.0, 1.0] at startup. This is the noise map — it never changes after initialization, making the dissolve pattern deterministic and reproducible.

### Threshold Animation

```gdscript
func _process(delta: float) -> void:
    if _dissolving and _threshold < 1.0:
        _threshold += delta * 0.6
    if _appearing and _threshold > 0.0:
        _threshold -= delta * 0.6
```

The global threshold advances at 0.6 units/second, reaching 1.0 (fully dissolved) in ~1.67 seconds. Appearance reverses it. The rate `0.6` is the only parameter needed to control transition speed.

### Visibility Test

```gdscript
if cell_noise > _threshold:
    # draw this cell
```

A cell is visible when its noise value exceeds the current threshold. As the threshold rises, cells with lower noise values vanish first. The apparent randomness of the dissolve pattern comes entirely from the noise values — the threshold logic itself is linear.

## Noise-Threshold Dissolve

This technique maps directly to a GLSL fragment shader:

```glsl
// shader equivalent
float noise_val = texture(noise_tex, UV).r;
if (noise_val <= threshold) discard;   // dissolve this pixel
```

The GDScript version replaces the texture lookup with `_noise_grid[row * COLS + col]` and the `discard` with simply not drawing the rect.

### Edge Glow

The orange "burn edge" appears on cells close to the dissolve boundary:

```gdscript
var dist_to_edge: float = abs(cell_noise - _threshold)
if dist_to_edge < 0.1:
    var t: float = dist_to_edge / 0.1
    cell_color = edge_color.lerp(base_color, t)   # orange → blue
```

Cells within 0.1 of the current threshold are transitioning. They get a gradient from `edge_color` (orange) at `dist = 0` to `base_color` (blue) at `dist = 0.1`. In a shader this would be:

```glsl
float edge = smoothstep(0.0, edge_width, abs(noise_val - threshold));
COLOR = mix(edge_color, base_color, edge);
```

The edge band width (0.1, or 10% of the noise range) controls how wide the burn glow appears.

### Why Pre-bake the Noise?

Pre-baking the noise grid at `_ready()` means the same pattern is used for both dissolve and appear. If noise values were regenerated each frame, cells would flicker randomly rather than reversing through the same sequence. This "memory" of the noise pattern is what makes dissolve and appear feel like a seamless reversal of the same animation.

## How to Adapt This in Your Project

- **Sprite dissolve**: Port to a shader. Pass `threshold` as a uniform. Sample a `NoiseTexture2D` instead of a pre-built array.
- **Non-uniform speed**: Multiply `delta * 0.6` by a curve (e.g., `ease_out(t)`) for a fast start that slows at the end.
- **Directional dissolve**: Make noise values encode a direction (`cell_noise = col / float(COLS)` for left-to-right wipe). Same threshold logic, different visual pattern.
- **Tile-based dissolve**: Apply per-tile in a TileMap by controlling each tile's shader material individually.
- **Pitfall**: A noise grid with too few unique values (e.g., only 8 levels) creates visible banding. Use `randf()` for maximum visual variety, or a proper noise function for spatial coherence.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `randf()` | Random float in [0, 1) |
| `draw_rect(Rect2, Color)` | Draw a filled rectangle |
| `Color.lerp(other, t)` | Interpolate between two colors |
| `queue_redraw()` | Schedule `_draw()` for next frame |
| `fmod(a, b)` | Floating-point modulo |

## Controls

| Key | Action |
|-----|--------|
| D | Dissolve (threshold increases to 1.0 at 0.6/s) |
| A | Appear (threshold decreases to 0.0 at 0.6/s) |
| R | Reset (snap to 0.0, fully visible) |

## Key Constants / Parameters

```gdscript
const COLS := 20             # grid width in cells
const ROWS := 15             # grid height in cells
const CELL_W := 16.0         # pixels per cell (world space)
const CELL_H := 16.0

# In _process():
_threshold += delta * 0.6    # speed: 0.6 = 1.67s full dissolve

# In _draw():
var edge_band := 0.1         # noise range that shows burn glow
var edge_color := Color(1.0, 0.6, 0.0)   # orange burn
var base_color := Color(0.2, 0.6, 1.0)   # blue base
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Noise grid, threshold animation, edge glow, all drawing |
| `scenes/main.tscn` | Single Node2D scene |
| `tests/test.tscn` | Unit tests for threshold logic and edge color calculation |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [magnet](../magnet) — Inverse-square attraction/repulsion field from a draggable magnet.
- [noise-terrain](../noise-terrain) — 1D terrain from `get_noise_1d()`, redrawing live as you tune parameters.
- [pathfinding-astar](../pathfinding-astar) — Interactive A* on a grid, visualizing open/closed sets and the optimal path.
- [procedural-sfx](../procedural-sfx) — Real-time SFX synthesis via `AudioStreamGeneratorPlayback.push_frame()`.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

