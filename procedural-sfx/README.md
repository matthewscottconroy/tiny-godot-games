# procedural-sfx

Demonstrates real-time procedural sound effect generation using `AudioStreamGeneratorPlayback.push_frame()`. Four distinct SFX are synthesized on demand from four mathematical formulas — no audio files required.

## How to Run

Open the project in Godot 4 and press F5 (or run `scenes/main.tscn`).

| Key | SFX | Formula |
|-----|-----|---------|
| 1 | Beep | 440 Hz sine with linear fade-out |
| 2 | Buzz | 120 Hz square wave with linear fade-out |
| 3 | Crash | White noise with sqrt-decay envelope |
| 4 | Chirp | 200→800 Hz ascending sine with quadratic fade-out |

## Key Concepts

### push_frame() and the Generator Buffer

`AudioStreamGeneratorPlayback.push_frame(Vector2)` writes one stereo sample into the audio buffer. It must be called frequently enough to keep the buffer full — this demo does it every `_process()` frame:

```gdscript
var pb := _player.get_stream_playback() as AudioStreamGeneratorPlayback
var n := pb.get_frames_available()
for i in n:
    pb.push_frame(Vector2(sample, sample) * 0.5)
```

When the SFX is finished (`_gen_frames >= _gen_total`) the loop pushes silence (`Vector2.ZERO`) so the buffer never starves.

### Phase Accumulation for Pitch

For tonal SFX (beep, buzz, chirp) the instantaneous frequency is converted to a per-sample phase increment:

```gdscript
_gen_phase += freq / MIX_RATE   # advance phase by one sample's worth
var s := sin(TAU * _gen_phase)
```

Because `_gen_phase` grows without wrapping (unlike the music demo which uses `fmod`) any accumulated floating-point error is negligible over the short duration of a typical SFX.

### Waveform Formulas

**Beep** — smooth sine, linearly fades to silence:
```gdscript
sin(TAU * _gen_phase) * (1.0 - t)
```

**Buzz** — square wave: only two amplitude values, creating a harsh, buzzy timbre:
```gdscript
sign(sin(TAU * _gen_phase)) * (1.0 - t)
```
`sign()` returns exactly `+1.0` or `-1.0` (or `0.0` at zero crossings), producing the flat tops and bottoms of a square wave. Lower frequency (120 Hz) gives the characteristic rumble.

**Crash** — white noise: every sample is an independent random value, shaped by a decaying envelope:
```gdscript
(randf() * 2.0 - 1.0) * pow(1.0 - t, 0.5)
```
`randf()` returns `[0, 1)`, scaled to `[-1, 1)`. The `pow(..., 0.5)` (square-root) envelope decays quickly at first then slowly — this matches the psychoacoustic profile of a real crash or cymbal hit.

**Chirp** — ascending pitch via `lerpf` on the instantaneous frequency:
```gdscript
var freq := lerpf(200.0, 800.0, t)
_gen_phase += freq / MIX_RATE
sin(TAU * _gen_phase) * (1.0 - pow(t, 2.0))
```
Because frequency changes every sample, the phase accumulates non-linearly, producing a true frequency sweep. The `pow(t, 2.0)` envelope stays near 1.0 for most of the chirp, then drops sharply at the end.

### Amplitude Envelopes

Every SFX uses an envelope — a time-varying multiplier that shapes the loudness contour:

| SFX | Envelope | Shape |
|-----|----------|-------|
| Beep | `1 - t` | Linear decay |
| Buzz | `1 - t` | Linear decay |
| Crash | `pow(1 - t, 0.5)` | Fast-then-slow decay |
| Chirp | `1 - t^2` | Slow-then-fast decay |

Envelopes prevent clicks (abrupt start/stop) and give each SFX its distinctive character.

## File Layout

```
procedural-sfx/
  project.godot
  icon.svg
  scenes/main.tscn       — Node2D with SFXPlayer + UI labels
  scripts/main.gd        — waveform synthesis, buffer management, visualization
  tests/test_logic.gd    — pure GDScript unit tests
  tests/test.tscn        — minimal scene to run tests
```
