# procedural-sfx

Demonstrates real-time procedural sound effect generation using `AudioStreamGeneratorPlayback.push_frame()`. Four distinct SFX are synthesized on demand from four mathematical formulas — no audio files required.

## Purpose

Generating sound effects in code removes the asset pipeline for prototypes and makes every parameter tweakable at runtime. Four waveform recipes cover most retro game feedback: a sine beep, a square buzz, a noise crash, and a frequency sweep. This demo writes raw samples into an `AudioStreamGenerator` so the relationship between the maths and the sound is direct.

## Controls

| Key | SFX | Formula |
|-----|-----|---------|
| 1 | Beep | 440 Hz sine with linear fade-out |
| 2 | Buzz | 120 Hz square wave with linear fade-out |
| 3 | Crash | White noise with sqrt-decay envelope |
| 4 | Chirp | 200 to 800 Hz sweep with quadratic fade-out |

## How It Works

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

## Files

```
procedural-sfx/
  project.godot
  icon.svg
  scenes/main.tscn       — Node2D with SFXPlayer + UI labels
  scripts/main.gd        — waveform synthesis, buffer management, visualization
  tests/test_logic.gd    — pure GDScript unit tests
  tests/test.tscn        — minimal scene to run tests
```

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AudioStreamGenerator` | Generate samples at runtime, no audio assets |
| `AudioStreamGeneratorPlayback.push_frame()` | Write one sample into the buffer |
| `get_frames_available()` | Keep the buffer fed without overrunning it |
| `randf()` | White noise for the crash effect |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

