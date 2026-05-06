# Procedural Generation

Uses `FastNoiseLite` to generate terrain, caves, islands, and moisture maps — demonstrating how one noise function produces wildly different biome results through thresholds, masks, and parameter tuning.

## Purpose

Procedural generation lets games create infinite or randomized content without hand-crafting every room, level, or world. From Minecraft's terrain to Spelunky's caves, noise-based generation powers countless titles because it produces organic-looking variation that would be impractical to author by hand. The central insight is that a single function — `get_noise_2d(x, y)` — returns a float in `[-1, 1]` for any coordinate, and everything interesting happens in how you interpret that float: threshold it into biome bands, subtract a distance mask to create islands, or treat it as a binary wall/floor decision for caves.

`FastNoiseLite` wraps several underlying noise algorithms (Simplex, Cellular, Value) behind a unified API. Changing `noise_type` switches algorithms entirely; adjusting `frequency` zooms the feature scale in or out; stacking octaves via FBM adds detail at multiple scales simultaneously. Understanding these knobs is the foundation for any procedural content system.

This demo makes all four modes share the same `FastNoiseLite` instance and re-parameterize it per mode. That structure is a clean pattern for real projects: one noise object, swapped configurations, same `get_noise_2d` call.

## How It Works

The core loop lives in `_regenerate()` and `_draw()`:

```gdscript
func _regenerate() -> void:
    _seed = randi()
    _noise.seed = _seed
    _map.clear()
    for y in MAP_H:
        for x in MAP_W:
            _map.append(_noise.get_noise_2d(x, y))
    queue_redraw()
```

The 78×52 grid (each cell = 8 px) is sampled once and stored in a flat `Array[float]`. On each `queue_redraw()`, `_draw()` iterates the array and calls `_sample_color()` to map each float to a `Color`, then draws one rectangle per cell.

### Mode: Terrain

Seven threshold bands from deep water to snow:

```gdscript
if n < -0.35: return Color(0.1, 0.2, 0.7)   # deep water
if n < -0.1:  return Color(0.2, 0.4, 0.85)  # shallow water
if n < 0.0:   return Color(0.75, 0.7, 0.4)  # sand
if n < 0.25:  return Color(0.2, 0.55, 0.2)  # grass
if n < 0.5:   return Color(0.3, 0.45, 0.2)  # forest
if n < 0.7:   return Color(0.5, 0.45, 0.35) # mountain
return Color(0.9, 0.9, 0.9)                  # snow
```

The threshold values are tunable constants — shifting them left or right changes how much of the map is water vs land.

### Mode: Caves

Binary threshold: cells above `0.05` are walls (black), below are floor (tan). Cellular noise (`TYPE_CELLULAR`) is switched in for caves — it naturally clusters into voronoi-like cell shapes that read as cavern chambers.

### Mode: Island

Subtracts a radial falloff from the noise value before thresholding:

```gdscript
var cx := float(x) / MAP_W - 0.5
var cy := float(y) / MAP_H - 0.5
var d   := Vector2(cx, cy).length() * 2.2
var v   := n - d
```

At the edges, `d` approaches `√2 × 1.1 ≈ 1.56`, which pushes any positive noise value well below the water threshold. The center of the map has `d ≈ 0`, so noise values appear unmodified. Result: land only exists near the center, surrounded by water at the borders.

### Mode: Moisture

Remaps `[-1, 1]` to `[0, 1]` and linearly interpolates through a blue-to-green color gradient:

```gdscript
var t := (n + 1.0) * 0.5
return Color(0.1 + t * 0.1, 0.3 + t * 0.5, 0.8 - t * 0.6)
```

At `t=0` (dry) the color is cool blue; at `t=1` (wet) it shifts to warm green. This shows how the same noise data can encode a secondary game variable (moisture, temperature, elevation as color ramp).

## Fractal Brownian Motion (FBM)

Setting `fractal_type = FRACTAL_FBM` stacks multiple noise "octaves" at increasing frequencies and decreasing amplitudes:

| Octave | Frequency multiplier | Amplitude |
|--------|---------------------|-----------|
| 1 | 1× | 0.5 |
| 2 | 2× | 0.25 |
| 3 | 4× | 0.125 |
| 4 | 8× | 0.0625 |
| 5 | 16× | 0.03125 |

Octave 1 provides large rolling hills; each subsequent octave adds finer detail. The `frequency = 0.035` base means feature sizes are approximately `1/0.035 ≈ 28` cells wide — large enough to see coherent landmasses at the demo's 78×52 grid scale.

## How to Adapt This in Your Project

- **Change `frequency`** to zoom features in or out. `0.01` = continent-scale; `0.1` = small rocky patches.
- **Change `fractal_octaves`** (1–8) to trade detail for performance. 3 octaves is a good balance.
- **Stack two noise instances** for combined effects: use one for elevation, a second for moisture, and select biome by 2D lookup table.
- **Seed persistence**: save `_noise.seed` to a file — the same seed always regenerates the same world. Feed it with a player-chosen world name via `hash("my world name")`.
- **Incremental generation**: sample `get_noise_2d(chunk_x * CHUNK_W + local_x, ...)` for any chunk offset. The noise function is stateless — calling it for distant coordinates works without generating intermediate cells.
- **Replace `_draw()` with TileMap.set_cell()**: index the noise value into a tile ID to drive a real TileMap rather than colored rects.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `FastNoiseLite.new()` | Create a noise generator instance |
| `FastNoiseLite.noise_type` | Algorithm: `TYPE_SIMPLEX_SMOOTH`, `TYPE_CELLULAR`, `TYPE_VALUE`, etc. |
| `FastNoiseLite.fractal_type` | Stacking mode: `FRACTAL_FBM`, `FRACTAL_RIDGED`, `FRACTAL_PING_PONG` |
| `FastNoiseLite.fractal_octaves` | Number of stacked noise layers (1–10) |
| `FastNoiseLite.frequency` | Feature scale — lower = larger features |
| `FastNoiseLite.seed` | Integer seed; same seed always produces the same output |
| `FastNoiseLite.get_noise_2d(x, y)` | Sample noise at a 2D coordinate, returns `[-1, 1]` |
| `CanvasItem.queue_redraw()` | Request a `_draw()` call next frame |
| `CanvasItem.draw_rect(rect, color)` | Draw a filled rectangle in `_draw()` |

## Controls

| Input | Action |
|-------|--------|
| **Terrain button** | Heightmap with 7 biome bands |
| **Caves button** | Cellular binary wall/floor |
| **Island button** | Heightmap with radial distance mask |
| **Moisture button** | Noise value as color gradient |
| **Regenerate button** | New random seed, same mode |
| **R key** | Also regenerates |

## Key Constants

```gdscript
const MAP_W := 78    # grid width in cells
const MAP_H := 52    # grid height in cells
const CELL  := 8     # pixel size of each cell

_noise.fractal_octaves = 5
_noise.frequency       = 0.035
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | All generation logic, mode switching, drawing |
| `scenes/main.tscn` | Root Node2D with mode buttons |
