# Day-Night Cycle

A 24-hour day/night cycle driven by `CanvasModulate` tinting — sun arc, moon arc, star field, and animated sky color all interpolate through 9 keyframes. The HUD stays fully lit inside a `CanvasLayer`.

## Purpose

Day/night cycles create atmosphere, drive gameplay loops (farming by day, enemies at night), and reward exploration across different times. In 2D Godot, the standard technique is `CanvasModulate`: a single node that multiplies a color across all 2D rendering in its canvas. Midnight = deep blue tint, noon = white (no change), sunset = warm orange. Because it's a canvas-wide multiply, every sprite, tilemap, and drawn object responds to the time of day without individual modification.

The keyframe interpolation pattern shown here — define colors at key times, linearly interpolate between adjacent keyframes — is directly applicable to any time-varying game parameter: weather transitions, emotional tone shifts in music, or environmental hazard timing. The same pattern drives many commercial games' lighting systems, though production games often add more keyframes and easing curves.

Two color tracks run in parallel: the sky background color (pure visual) and the `CanvasModulate` color (world lighting). Separating them allows the sky to show a richer sunrise palette while the world lighting follows a simpler warm-to-white-to-dark arc.

## How It Works

### Node Tree

```
Main (Node2D)              ← main.gd
├── CanvasModulate         ← tints all 2D content below it
└── HUD (CanvasLayer)      ← immune to CanvasModulate
    ├── TimeLabel
    ├── HintLabel
    └── [SlowBtn, NormalBtn, FastBtn]
```

### Time Progression

```gdscript
const DAY_LENGTH := 30.0   # seconds per full 24-hour cycle

func _process(delta: float) -> void:
    _time = fmod(_time + delta * _speed / DAY_LENGTH, 1.0)
    var sky_col := _lerp_keyframes(_time, 0)
    var mod_col := _lerp_keyframes(_time, 1)
    _canvas_mod.color = mod_col
    queue_redraw()
```

`_time` is a `[0, 1]` float where `0.0` = midnight, `0.5` = noon, `1.0` = next midnight. `fmod` wraps it cleanly back to 0.0 when it reaches 1.0. Speed is controlled by `_speed` (0.5×, 1×, or 4×).

### Keyframe Data

```gdscript
const KEYFRAMES: Array = [
    [0.00, Color(0.05, 0.05, 0.20), Color(0.12, 0.14, 0.30)],  # midnight
    [0.20, Color(0.20, 0.15, 0.30), Color(0.35, 0.28, 0.55)],  # pre-dawn
    [0.25, Color(0.70, 0.40, 0.20), Color(0.80, 0.65, 0.50)],  # dawn
    [0.35, Color(0.50, 0.70, 1.00), Color(1.00, 0.95, 0.85)],  # morning
    [0.50, Color(0.45, 0.68, 1.00), Color(1.00, 1.00, 1.00)],  # noon (white = no tint)
    [0.65, Color(0.45, 0.65, 0.95), Color(1.00, 0.98, 0.90)],  # afternoon
    [0.75, Color(0.80, 0.45, 0.10), Color(0.90, 0.70, 0.50)],  # dusk
    [0.85, Color(0.20, 0.10, 0.25), Color(0.40, 0.30, 0.55)],  # twilight
    [1.00, Color(0.05, 0.05, 0.20), Color(0.12, 0.14, 0.30)],  # midnight (loop)
]
```

Each entry is `[normalized_time, sky_color, modulate_color]`. The first and last entries are identical so interpolation loops seamlessly. Column index `1` = sky color, `2` = modulate color — `col_idx` selects which channel to interpolate.

### Keyframe Interpolation

```gdscript
func _lerp_keyframes(t: float, col_idx: int) -> Color:
    for i in KEYFRAMES.size() - 1:
        var t0: float = KEYFRAMES[i][0]
        var t1: float = KEYFRAMES[i + 1][0]
        if t >= t0 and t <= t1:
            var local := (t - t0) / (t1 - t0)   # remap to [0,1] within this segment
            var c0: Color = KEYFRAMES[i][col_idx + 1]
            var c1: Color = KEYFRAMES[i + 1][col_idx + 1]
            return c0.lerp(c1, local)
    return KEYFRAMES[0][col_idx + 1]
```

The linear scan finds the bracketing keyframe pair, computes the local `t` within that segment, and linearly interpolates the two colors. `Color.lerp()` interpolates all four RGBA channels. For smoother transitions, replace `local` with `smoothstep(0.0, 1.0, local)`.

### Sun and Moon Arcs

```gdscript
var sun_angle := (_time - 0.25) * TAU   # offset so dawn (t=0.25) = angle 0
var sun_x     := 320 + cos(sun_angle) * 260
var sun_y     := 340 - sin(sun_angle) * 280
if sin(sun_angle) > 0:   # only draw when above the horizon (positive Y-flip)
    draw_circle(Vector2(sun_x, sun_y), 24, ...)

var moon_angle := sun_angle + PI          # always opposite the sun
```

The sun traces a full circle with `cos`/`sin`. The screen coordinate math: center at `x=320`, arc radius `260px` horizontally and `280px` vertically (elliptical arc to match a non-square sky area). `sin(sun_angle) > 0` is the above-horizon test. The moon uses `sun_angle + PI` — always diametrically opposite, so when the sun sets in the west, the moon rises in the east.

### Stars

```gdscript
var star_alpha := clampf(1.0 - _canvas_mod.color.get_luminance() * 2.5, 0.0, 1.0)
if star_alpha > 0.02:
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    for i in 60:
        draw_circle(Vector2(rng.randf_range(0, 640), rng.randf_range(0, 320)),
                    rng.randf_range(0.8, 2.0), Color(1, 1, 1, star_alpha))
```

Stars use `get_luminance()` (perceptual brightness) to compute visibility: at noon the modulate color is white (luminance ≈ 1.0), so `1 - 1.0 * 2.5 = -1.5` → clamped to `0.0` (invisible). At midnight (luminance ≈ 0.2), stars are `1 - 0.2 * 2.5 = 0.5` → 50% opaque. The fixed seed `12345` ensures stars never move between frames — the `RandomNumberGenerator` is recreated each draw call, but the same seed produces the same positions every time.

### Ground Darkening

```gdscript
var night_ratio  := 1.0 - _canvas_mod.color.get_luminance()
var ground_col   := Color(0.15, 0.35, 0.10).darkened(night_ratio * 0.7)
draw_rect(Rect2(0, 340, 640, 140), ground_col)
```

The ground color is darkened proportionally to how dark the modulate color is. This is complementary to `CanvasModulate` — the ground explicitly deepens at night beyond what the canvas multiply alone would achieve, giving more visible contrast.

### CanvasLayer Immunity

The HUD is inside a `CanvasLayer`, which renders on its own independent canvas with its own `CanvasModulate` scope. The main scene's `CanvasModulate` node cannot reach the `CanvasLayer` — buttons and labels stay at full brightness regardless of time of day. This is always the correct structure for game UIs in day/night cycle games.

## How to Adapt This in Your Project

- **Add keyframes**: insert more entries in `KEYFRAMES` for finer-grained transitions (e.g. a golden-hour keyframe between dawn and morning). The interpolation loop handles any number of keyframes automatically.
- **Easing**: replace linear interpolation with `c0.lerp(c1, ease(local, -2.0))` to make transitions accelerate in and decelerate out of key times like golden hour.
- **Light sources**: create `PointLight2D` nodes that enable at night (lanterns, torches) by responding to `_time` in their own scripts — or drive their `energy` from the same `_lerp_keyframes` system.
- **Enemy spawning**: check `_time > 0.75 or _time < 0.25` to determine nighttime and spawn different enemies or change AI behavior.
- **Sound**: drive ambient audio volume from the same keyframe system — crickets fade in with the moon, birds fade in at dawn.
- **Persistence**: save `_time` to a file when the game quits to resume at the same time of day.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CanvasModulate` | Multiplies a color over all 2D content on the same canvas |
| `CanvasModulate.color` | The tint color; `Color(1,1,1)` = no effect |
| `CanvasLayer` | Renders on its own canvas, immune to `CanvasModulate` |
| `Color.lerp(other, t)` | Linear interpolation between two colors |
| `Color.get_luminance()` | Perceptual brightness `[0,1]`; 0=black, 1=white |
| `Color.darkened(amount)` | Returns a darkened copy; `amount=0.7` = 70% darker |
| `fmod(a, b)` | Float modulo — wraps `_time` from 1.0 back to 0.0 |
| `clampf(v, lo, hi)` | Clamp float to range |
| `RandomNumberGenerator.seed` | Fixed seed for reproducible random positions |

## Controls

| Input | Action |
|-------|--------|
| **Slow button (0.5×)** | Half-speed cycle |
| **Normal button (1×)** | Default 30-second cycle |
| **Fast button (4×)** | 4× speed (one full day in ~7.5 seconds) |

## Key Constants

```gdscript
const DAY_LENGTH := 30.0   # seconds for a full 24-hour cycle at 1× speed

# _time values at key moments:
# 0.00 = midnight, 0.25 = dawn, 0.50 = noon, 0.75 = dusk, 1.00 = midnight
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | All time logic, keyframe interpolation, sun/moon/stars drawing |
| `scenes/main.tscn` | Node tree with CanvasModulate, CanvasLayer HUD, speed buttons |
