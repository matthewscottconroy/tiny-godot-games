# noise-terrain

Demonstrates procedural 1D terrain generation using `FastNoiseLite.get_noise_1d()`. The terrain is rendered as a filled polygon and redraws live as you adjust frequency and octaves.

## Purpose

`FastNoiseLite` is the backbone of most procedural generation in Godot, and its parameters are unintuitive until you can watch them move. Frequency sets the scale of the features; octaves add finer detail on top. This demo redraws a 1D heightmap live as you sweep both, so the relationship between the numbers and the shape becomes concrete.

## Controls

Keys are polled every frame, so hold one to sweep a parameter continuously.

| Key | Action |
|-----|--------|
| R | Randomize the noise seed (new terrain shape) |
| F | Increase frequency (up to 0.2) |
| G | Decrease frequency (down to 0.001) |
| O | Increase octaves (up to 8) |
| P | Decrease octaves (down to 1) |

## How It Works

### FastNoiseLite.get_noise_1d()

`FastNoiseLite` is Godot's built-in coherent noise generator. `get_noise_1d(x)` evaluates a smooth pseudo-random function at position `x` and returns a value in `[-1, 1]`. Unlike `randf()`, adjacent x-values produce smoothly varying outputs — the essential property for natural-looking terrain:

```gdscript
var raw := _noise.get_noise_1d(float(i) * _freq)  # in [-1, 1]
var normalized := (raw + 1.0) * 0.5               # remap to [0, 1]
var screen_y := lerpf(TERRAIN_BOTTOM, TERRAIN_TOP, normalized)
```

`TERRAIN_TOP` (smaller y = higher on screen) and `TERRAIN_BOTTOM` (larger y = lower) are passed to `lerpf` in that order so that a normalized value of 1.0 maps to the peak of the terrain and 0.0 maps to the valley floor.

### Frequency vs. Octaves

**Frequency** controls how rapidly the noise changes along the x-axis. Low frequency = broad, gentle hills. High frequency = sharp, jagged peaks.

```gdscript
_noise.frequency = _freq   # default 0.02 → gentle rolling hills
```

**Octaves** (fractal layers) stack multiple noise samples at increasing frequencies and decreasing amplitudes:

```gdscript
_noise.fractal_octaves = _octaves  # 1 = smooth, 8 = very detailed
```

Each additional octave adds fine detail on top of the coarser layer. More octaves = more computation but richer, more natural-looking terrain.

**The tradeoff:** frequency determines the scale of the dominant landscape features; octaves add high-frequency detail on top. Typical usage is low-to-medium frequency with 3-5 octaves.

### Seed for Reproducibility

The noise seed determines the exact random shape of the terrain:

```gdscript
_noise.seed = 42  # always produces the same terrain
_noise.seed = randi()  # random new terrain each call
```

The same seed + frequency + octaves combination always produces identical terrain, which is essential for procedural worlds that need to be regenerated deterministically (e.g., saving/loading a game world by seed alone).

### Polygon Fill for Terrain Rendering

The terrain is rendered by building a `PackedVector2Array` that forms a closed polygon:

```gdscript
var pts := PackedVector2Array()
pts.append(Vector2(0.0, 480.0))                        # bottom-left corner
for i in COLS:
    pts.append(Vector2(float(i) / (COLS-1) * 640.0, _heights[i]))  # surface
pts.append(Vector2(640.0, 480.0))                      # bottom-right corner
draw_polygon(pts, PackedColorArray([Color(0.18, 0.52, 0.18)]))
```

The two bottom corners close the shape beneath the surface line, filling the entire ground area with a single `draw_polygon()` call — efficient and avoids column-by-column rectangle drawing.

## Files

```
noise-terrain/
  project.godot
  icon.svg
  scenes/main.tscn       — Node2D with HUD CanvasLayer (FreqLabel, OctLabel)
  scripts/main.gd        — noise generation, polygon rendering, key input
  tests/test_logic.gd    — pure GDScript unit tests
  tests/test.tscn        — minimal scene to run tests
```

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `FastNoiseLite.get_noise_1d()` | One height sample per column |
| `FastNoiseLite.frequency` | Feature scale — lower is smoother |
| `FastNoiseLite.fractal_octaves` | Layers of detail summed on top |
| `draw_polygon()` | Fill under the height curve |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [procedural-gen](../procedural-gen) — `FastNoiseLite` generating terrain, caves, islands, and moisture maps.
- [radial-menu](../radial-menu) — Hold Tab to open a six-item radial action menu.
- [vision-cone](../vision-cone) — A 120° FOV cone plus Liang-Barsky line-of-sight test against walls.
- [marching-squares](../marching-squares) — Contour line extraction from a 2D scalar field.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

