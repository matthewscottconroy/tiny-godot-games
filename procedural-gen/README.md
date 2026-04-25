# Procedural Generation

Uses `FastNoiseLite` to generate terrain, caves, islands, and moisture maps — demonstrating how a single noise function produces wildly different results with different parameters and post-processing.

## Purpose

Procedural generation powers infinite worlds, randomized levels, and natural-looking terrain. `FastNoiseLite` wraps several noise algorithms in a simple API: set a seed and frequency, call `get_noise_2d(x, y)`, get a float in [-1, 1]. Everything else — terrain thresholds, island masks, moisture biomes — is just math applied to that one number.

## Controls

- **Terrain button**: Heightmap with water / sand / grass / stone / snow thresholds
- **Caves button**: Cellular noise, cells above threshold = wall
- **Island button**: Heightmap biased toward edges (radial distance mask)
- **Moisture button**: Second noise layer adds biome variation to island mode
- **Regenerate button**: New random seed — same mode, different world

## How It Works

### Node Tree

```
Main (Node2D)        ← main.gd
└── HUD (CanvasLayer)
    ├── ModeLabel
    └── [5 mode buttons]
```

### `scripts/main.gd`

- **`_noise`** — A `FastNoiseLite` instance shared across all modes. `noise_type` and `fractal_octaves` are changed per mode.
- **`_generate()`** — Loops over a `MAP_W × MAP_H` grid (each cell = 8px). Calls `_noise.get_noise_2d(col, row)` for each cell and maps the result to a color based on mode.
- **Mode: Terrain** — Threshold bands: `< -0.3` = water (blue), `< -0.1` = sand (tan), `< 0.3` = grass (green), `< 0.6` = stone (gray), else snow (white).
- **Mode: Island** — Subtracts a radial distance term `d = Vector2(cx, cy).length() * 2.2` from the raw noise. This pushes the edges below water threshold, creating a natural island shape.
- **`queue_redraw()`** — `_draw()` iterates the pre-computed color array and draws `MAP_W × MAP_H` colored rectangles.

### FBM (Fractal Brownian Motion)

Setting `fractal_type = FRACTAL_FBM` stacks multiple noise "octaves" at increasing frequencies and decreasing amplitudes. Each octave adds detail:
- Octave 1: large rolling hills
- Octave 2: medium ridges
- Octave 3: small bumps
- Octave 4–5: fine texture

More octaves = more detail but slower generation.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `FastNoiseLite.new()` | Noise generator instance |
| `FastNoiseLite.noise_type` | Algorithm: Simplex, Cellular, Value, etc. |
| `FastNoiseLite.fractal_type` | Stacking mode: FBM, Ridged, Ping-Pong |
| `FastNoiseLite.fractal_octaves` | Number of stacked noise layers |
| `FastNoiseLite.frequency` | Scale of features (lower = larger features) |
| `FastNoiseLite.seed` | Integer seed for reproducible output |
| `FastNoiseLite.get_noise_2d(x, y)` | Sample noise at a 2D coordinate |
