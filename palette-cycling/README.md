# Palette Cycling

Animates a 40×30 grid of colored tiles using classic indexed-color palette rotation — each cell stores a palette index, and a floating-point offset shifts all lookups simultaneously each frame to create animated water, lava, and rainbow effects.

## Purpose

Palette cycling is an 8/16-bit era technique where animated effects were achieved with zero pixel redraws. Old hardware had a single writable color table. By rotating values in the palette rather than updating frame buffers, developers produced flowing water, lava, and fire for almost no CPU cost.

Modern games rarely need the CPU savings, but palette cycling is still useful: it animates large areas uniformly without per-pixel shader math, it produces clean stylized looks that resonate with retro aesthetics, and it makes color animation as simple as changing one float. This demo shows the technique applied to three visually distinct patterns — waves, lava, and rainbow — using only GDScript and `_draw()`.

## How It Works

### Indexed Color Map (`scripts/main.gd`)

```gdscript
const COLS := 40
const ROWS := 30
const CELL := 16        # pixels per cell on screen

var _index_map: PackedByteArray   # one byte per cell, value 0..15
var _palette: Array[Color]        # 16 colors, changes per pattern
var _palette_offset: float = 0.0  # advances each frame
```

Each cell stores a **palette index** (0–15), not a color. The actual color is resolved at draw time by offsetting into the palette array.

### Index Map Patterns

```gdscript
match _pattern:
    0:  # water: diagonal wave bands
        idx = int((col + row * 0.5) * 16.0 / COLS) % 16
    1:  # lava: sin-product noise blobs
        idx = int(sin(col * 0.4) * sin(row * 0.3) * 8.0 + 8.0) % 16
    2:  # rainbow: vertical bands
        idx = (col * 16 / COLS) % 16
```

The index map is static — it is built once when the pattern changes and never updated again. All animation comes from the palette offset, not from recomputing cells.

### Palette Offset Cycling

```gdscript
func _process(delta: float) -> void:
    _palette_offset = fmod(_palette_offset + _cycle_speed * delta, 16.0)
    queue_redraw()
```

Each frame, `_palette_offset` advances by `_cycle_speed * delta`. In `_draw()`:

```gdscript
var raw_idx: int = _index_map[row * COLS + col]
var shifted_idx: int = int(raw_idx + _palette_offset) % 16
draw_rect(Rect2(col * CELL, row * CELL, CELL, CELL), _palette[shifted_idx])
```

Adding `_palette_offset` to `raw_idx` before the modulo lookup effectively rotates which palette entry each cell displays. Cells with adjacent index values display adjacent palette colors — and since the palette wraps cyclically, the animation loops seamlessly.

## Palette Offset Cycling Technique

The key requirement is that the palette be **cyclic** — color at index 0 must be visually adjacent to color at index 15. If it is not, the animation will have a visible "seam" where the offset wraps.

**Water palette** (indices 0–15): deep blue → bright cyan → white crest → bright cyan → deep blue. Index 0 and 15 are both dark blue, so the wrap is invisible.

**Lava palette**: black → dark red → orange → yellow → near-white → yellow → orange → red → black. Wraps smoothly through the dark end.

**Rainbow palette**:
```gdscript
for i in range(16):
    _palette.append(Color.from_hsv(float(i) / 16.0, 0.9, 1.0))
```
`Color.from_hsv` distributes hues evenly around the color wheel. At `i = 15`, hue = 15/16 ≈ 0.9375 (near red), which is adjacent to `i = 0` (hue = 0.0, red). The hue wheel is naturally cyclic.

### Index Map and Visual Frequency

The diagonal wave formula `(col + row * 0.5) * 16.0 / COLS` maps the full 0–15 index range across 40 columns. Multiplying by a larger value increases the number of wave crests visible; multiplying by a smaller value stretches them out. The `row * 0.5` term introduces a vertical skew, giving diagonal rather than vertical bands.

The lava formula `sin(col * 0.4) * sin(row * 0.3) * 8.0 + 8.0` produces a Moiré-like blotchy pattern from the product of two sine waves. The constants 0.4 and 0.3 control spatial frequency; the `+ 8.0` shifts the range from [-8, 8] to [0, 16].

## How to Adapt This in Your Project

- **Shader version**: Store index values in a texture's red channel. In the fragment shader, sample the index, add a `time` uniform, and look up into a `Gradient` or a 1D `Texture2D` acting as a color LUT. This handles arbitrarily large maps with no CPU cost.
- **Animated tilemap**: Assign each tile type a starting palette index. Cycle the palette to animate all tiles of the same type simultaneously.
- **Multiple independent cycles**: Use two separate palette offsets at different speeds for a foreground vs background water effect.
- **Waveform control**: Replace the index map formula with a noise function (`FastNoiseLite.get_noise_2d()`) for more organic patterns that still cycle cleanly.
- **Pitfall**: If `_palette_offset` is an integer rather than float, the animation steps in discrete jumps instead of smoothly advancing. Always accumulate as a float and convert to int only at the modulo step.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `PackedByteArray` | Memory-efficient array of 0–255 integers for the index map |
| `fmod(a, b)` | Floating-point modulo, keeps `_palette_offset` in [0, 16) |
| `Color.from_hsv(h, s, v)` | Create a color from hue/saturation/value |
| `draw_rect(Rect2, Color)` | Draw one tile per cell |
| `queue_redraw()` | Schedule `_draw()` each frame |

## Controls

| Key | Action |
|-----|--------|
| W | Switch to Water pattern (blue diagonal waves) |
| L | Switch to Lava pattern (red/orange blobs) |
| R | Switch to Rainbow pattern (rotating hue bands) |
| + / = | Increase cycle speed |
| - | Decrease cycle speed (minimum 0.1) |

## Key Constants / Shader Parameters

```gdscript
const COLS := 40          # grid columns
const ROWS := 30          # grid rows
const CELL := 16          # screen pixels per cell

_cycle_speed: float = 2.0  # palette indices per second
# speed of 2.0 = full palette rotation in 8 seconds (16 entries / 2.0)

# Offset formula each frame:
_palette_offset = fmod(_palette_offset + _cycle_speed * delta, 16.0)

# Lookup formula per cell:
shifted_idx = int(raw_idx + _palette_offset) % 16
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Index map, palette construction, offset cycling, all drawing |
| `scenes/main.tscn` | Single Node2D scene |
| `tests/test.tscn` | Tests for index arithmetic, wrapping, and palette sizes |
