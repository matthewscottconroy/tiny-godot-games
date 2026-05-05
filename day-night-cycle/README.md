# Day Night Cycle

A 24-hour day/night cycle using `CanvasModulate` to globally tint 2D content. The sky, sun, moon, stars, and ground all respond to the time of day, while the HUD stays unaffected inside a `CanvasLayer`.

## Purpose

Day/night cycles create atmosphere and can drive gameplay (enemies at night, farming by day). The Godot 2D technique uses `CanvasModulate`: a single node that multiplies a color across all 2D rendering in its canvas. Midnight is near-black, noon is white (no change), sunset is warm orange. This demo shows the full keyframe-based approach: define colors at key times, linearly interpolate between them.

## Controls

- **0.5× / 1× / 4× speed buttons**: Control cycle speed
- Watch the sun arc across the sky, stars appear at night, and lighting shift

## How It Works

### `CanvasModulate`

```
CanvasModulate (child of Main Node2D)
```

Setting `CanvasModulate.color` multiplies every pixel in the 2D canvas by that color. White (`Color(1,1,1)`) = no change. Dark blue (`Color(0.12, 0.14, 0.30)`) = nighttime tint. Orange (`Color(0.90, 0.70, 0.50)`) = sunset warmth.

**CanvasLayer is immune:** the HUD is inside a `CanvasLayer`, which renders on its own independent canvas. `CanvasModulate` doesn't reach it — buttons and labels stay fully lit regardless of time of day.

### Keyframe interpolation

```gdscript
const KEYFRAMES: Array = [
    [0.00, sky_color, modulate_color],  # midnight
    [0.25, sky_color, modulate_color],  # dawn
    [0.50, sky_color, modulate_color],  # noon
    [0.75, sky_color, modulate_color],  # dusk
    [1.00, sky_color, modulate_color],  # midnight (loop)
]

func _lerp_keyframes(t: float, col_idx: int) -> Color:
    for i in KEYFRAMES.size() - 1:
        var t0 = KEYFRAMES[i][0]
        var t1 = KEYFRAMES[i + 1][0]
        if t >= t0 and t <= t1:
            var local := (t - t0) / (t1 - t0)
            return c0.lerp(c1, local)
```

Two color tracks are stored per keyframe: the sky background color (drawn in `_draw()`) and the `CanvasModulate` color. Both are interpolated independently, giving different behavior for the sky vs the world lighting.

### Sun and Moon arcs

```gdscript
var sun_angle := (_time - 0.25) * TAU
var sun_x     := 320 + cos(sun_angle) * 260
var sun_y     := 340 - sin(sun_angle) * 280
```
The sun traces a sine arc. At `_time = 0.25` (dawn), the angle is 0 — sun is at the right horizon. At `_time = 0.5` (noon), the angle is `TAU/4` — sun is at the top. The moon is placed at `sun_angle + PI` — always opposite.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CanvasModulate` | Multiplies a color over all 2D content on the same canvas |
| `CanvasLayer` | Renders on its own canvas, immune to `CanvasModulate` |
| `Color.lerp(other, t)` | Smooth interpolation between two colors |
| `Color.get_luminance()` | Perceptual brightness (0=black, 1=white) |
| `fmod(a, b)` | Floating-point modulo — wraps time from 1.0 back to 0.0 |
