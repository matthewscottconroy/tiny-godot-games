# Music Sequencer

A 16-step × 8-note step sequencer with real-time sine-wave audio synthesis via `AudioStreamGenerator`. Click cells to toggle notes, Space to play/pause, +/- to change BPM.

## Purpose

Procedural and interactive audio is one of the most underused tools in game development. Static music tracks loop predictably; a sequencer can generate patterns that respond to gameplay state — adding notes when tension rises, stripping layers during exploration, randomizing melodies between encounters. Games like *Patterned*, *Thumper*, and the *Theatrhythm* series are built entirely around the sequencer concept.

Beyond music generation, understanding `AudioStreamGenerator` is essential for any audio effect that can't be pre-baked: real-time synthesis, procedural sound effects, audio reactive visuals, network-synchronized music. This demo builds the smallest complete sequencer that demonstrates all the moving parts: BPM timing, step advancement, audio buffer filling, and chord mixing.

## How It Works

### BPM-to-Step Timing

Step duration in seconds is one 16th note at the current BPM:

```gdscript
func _get_step_duration() -> float:
    return 60.0 / _bpm * 0.25
```

At 120 BPM: `60 / 120 * 0.25 = 0.125` seconds per step. The step timer accumulates `delta` each frame. When it exceeds `step_duration`, `_advance_step()` is called and the overshoot is preserved with `fmod`:

```gdscript
_step_timer += delta
if _step_timer >= step_duration:
    _advance_step()

func _advance_step() -> void:
    _step = (_step + 1) % STEPS
    _step_timer = fmod(_step_timer, step_duration)   # carry overshoot forward
```

Carrying the overshoot prevents timing drift from accumulating over many steps.

### Grid and Active Frequencies

The grid is `_grid[note][step]` — a 2D boolean array, `NOTES` rows by `STEPS` columns. On each step advance, all active notes for the current step are collected:

```gdscript
_active_freqs = []
for note in range(NOTES):
    if _grid[note][_step]:
        _active_freqs.append(FREQUENCIES[note])
```

`FREQUENCIES` maps row indices to concert pitch: `[261.63, 293.66, 329.63, 369.99, 392.00, 440.00, 493.88, 523.25]` (C4 through C5).

### `AudioStreamGenerator` Buffer Filling

Every frame, the audio playback thread has consumed some samples and needs more. `get_frames_available()` returns how many `Vector2` stereo frames the buffer can accept:

```gdscript
var available := _playback.get_frames_available()
for _f in range(available):
    var sample := 0.0
    if _note_frames_left > 0:
        var amp := 0.25 / max(1, _active_freqs.size())
        for freq in _active_freqs:
            sample += sin(TAU * freq * _phase / SAMPLE_RATE) * amp
        # Linear decay envelope
        var t := 1.0 - (float(int(NOTE_LEN * SAMPLE_RATE) - _note_frames_left) / (NOTE_LEN * SAMPLE_RATE))
        sample *= t
        _phase += 1.0
        _note_frames_left -= 1
    _playback.push_frame(Vector2(sample, sample))
```

Key details: amplitude is divided by note count so chords don't clip. `_phase` counts samples continuously for clean sine waves. The decay envelope `t` goes from 1.0 to 0.0 over `NOTE_LEN` seconds, giving each note a natural tail-off instead of a harsh cutoff.

### Grid Rendering

The grid is drawn note 0 at the bottom (lowest pitch) to note 7 at the top (highest pitch), matching standard piano-roll convention. Row index is inverted when converting mouse clicks to note index:

```gdscript
var note := (NOTES - 1) - row
```

The playhead is a vertical line at the current step's column:

```gdscript
var ph_x := GRID_X + _step * CELL_W + CELL_W * 0.5
draw_line(Vector2(ph_x, GRID_Y - 2), Vector2(ph_x, GRID_Y + NOTES * CELL_H + 2),
        Color(1.0, 1.0, 0.6, 0.7), 2.0)
```

## The Step Sequencer Pattern

### Why `fmod` for Timer Drift Prevention

A naive implementation resets `_step_timer = 0.0` after each step. At 120 BPM, each step is 125ms. If a frame takes 126ms, the timer reaches 126ms before being reset to 0. The next step would then fire at 125ms of accumulated time: 126 + 125 = 251ms after the previous step instead of 250ms. Over 64 steps, this accumulates to a 64ms drift. `fmod` carries the 1ms overshoot into the next step's timer, keeping timing accurate.

### AudioStreamGenerator vs AudioStreamPlayer

`AudioStreamPlayer` plays pre-baked audio files. `AudioStreamGenerator` accepts a raw PCM buffer that you fill frame-by-frame from GDScript. This gives complete control over waveform, pitch, and envelope, at the cost of requiring buffer management code. The buffer length (`0.1` seconds here) trades off latency against underrun risk — shorter = lower latency, but underruns produce audible pops.

### Extending the Sequencer

- **More waveforms**: replace `sin(...)` with `sign(sin(...))` for square wave, or add harmonic partials for richer tones.
- **Per-note velocity**: store a float 0–1 per cell instead of a bool and multiply the amplitude.
- **Swing**: offset odd-numbered steps by a fraction of `step_duration`.
- **Pattern save/load**: serialize `_grid` as a `PackedByteArray` to a config file.

## How to Adapt This in Your Project

1. Wrap the sequencer in an Autoload so game scenes can trigger patterns without owning the `AudioStreamPlayer`.
2. Expose `set_cell(note, step, active)` as a public API so gameplay events can write to the grid.
3. Crossfade between patterns by lerping amplitudes of two simultaneous grids.
4. Replace the fixed frequency array with a scale generator that takes a root note and mode as inputs.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AudioStreamGenerator` | PCM stream accepting push-frame calls from GDScript |
| `AudioStreamGeneratorPlayback.get_frames_available()` | How many stereo frames the buffer can accept |
| `AudioStreamGeneratorPlayback.push_frame(Vector2)` | Write one stereo sample frame |
| `AudioStreamPlayer.get_stream_playback()` | Access the active playback object |
| `fmod(a, b)` | Floating-point remainder (used for timer drift correction) |
| `sin(TAU * freq * phase / sample_rate)` | Sine wave synthesis formula |

## Controls

| Input | Action |
|-------|--------|
| Left-click on cell | Toggle note on/off |
| Space | Play / Pause |
| + or = | Increase BPM by 10 |
| - | Decrease BPM by 10 |
| C | Clear all cells |

## Key Constants

```gdscript
const STEPS       := 16       # number of steps per loop
const NOTES       := 8        # number of note rows (C4–C5)
const NOTE_LEN    := 0.12     # note burst duration in seconds
const SAMPLE_RATE := 44100.0  # PCM sample rate (must match AudioStreamGenerator.mix_rate)
# Initial BPM:
var _bpm: float = 120.0       # adjustable at runtime (60–240)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Sequencer clock, grid state, audio buffer fill, input, drawing |
| `scenes/main.tscn` | Node2D with one AudioStreamPlayer child |
| `tests/test_logic.gd` | Unit tests for BPM timing, step advancement, grid toggle |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [dynamic-music](../dynamic-music) — Real-time synthesis and crossfading between two music layers.
- [procedural-sfx](../procedural-sfx) — Real-time SFX synthesis via `AudioStreamGeneratorPlayback.push_frame()`.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

