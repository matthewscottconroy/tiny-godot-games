# Marching Squares

A minimal Godot 4.2 demo showing the marching squares algorithm: contour line extraction from a 2D scalar field.

## Controls

| Key | Action |
|-----|--------|
| Space | Regenerate with a new noise seed |

## How It Works

### Scalar Field

`FastNoiseLite` fills each grid cell with a float in `[0, 1]`. The contour algorithm finds where this field crosses a threshold of 0.5.

### The 16 Cases

For each 2×2 square of grid cells, each corner is classified as above (1) or below (0) the threshold. The four bits form a 4-bit index (0–15):

```
TL (bit 0) | TR (bit 1)
-----------+-----------
BL (bit 3) | BR (bit 2)
```

- Index 0: all below — no contour
- Index 15: all above — no contour
- Indices 1–14: contour crosses one or two edges of the square

### Edge Interpolation

The exact crossing point on each edge is interpolated rather than placed at the midpoint:

```gdscript
func _t(a: float, b: float) -> float:
    return clampf((THRESHOLD - a) / (b - a), 0.0, 1.0)
```

This produces smooth contours aligned with the actual field values.

### Ambiguous Cases (5 and 10)

Cases 5 (TL+BR) and 10 (TR+BL) have two opposing corners above threshold. This demo draws two separate line segments for each, one of the two valid interpretations.

## Key Constants

```gdscript
const GRID_W    := 64     # columns (64 × 10 = 640px)
const GRID_H    := 48     # rows    (48 × 10 = 480px)
const CELL      := 10     # pixels per cell
const THRESHOLD := 0.5    # contour iso-value
```

## Project Structure

```
marching-squares/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd         # noise generation + marching squares + _draw()
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
