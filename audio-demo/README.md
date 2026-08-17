# Audio Demo

Generates sound effects entirely in code using raw PCM synthesis, then routes them through Godot's audio bus system with volume control.

## Purpose

Most audio demos load `.wav` or `.ogg` files. This demo goes deeper: it synthesizes audio waveforms from scratch as byte arrays, constructs `AudioStreamWAV` resources at runtime, and demonstrates how Godot's audio bus architecture works. Understanding PCM audio and bus routing unlocks procedural sound design and fine-grained audio mixing.

## Controls

- **Low / Mid / High buttons**: Play sine tones at 180 Hz, 440 Hz, 880 Hz
- **Square button**: Play a square wave at 220 Hz
- **Sweep button**: Play a frequency sweep
- **Volume slider**: Controls the SFX bus gain in decibels

## How It Works

### Node Tree

```
Main (Control)          ← main.gd
├── SFXPlayer (AudioStreamPlayer)
├── ButtonRow (HBoxContainer)
│   ├── LowBtn, MidBtn, HighBtn, SquareBtn, SweepBtn
├── VolumeRow (HBoxContainer)
│   └── VolumeSlider (HSlider)
└── BusLabel (Label)
```

### `scripts/main.gd`

- **`_setup_buses()`** — Checks if a bus named `"SFX"` already exists (important: Godot persists bus configuration across runs). If not, adds a new bus, names it, and routes it to `"Master"`. This is the audio mixing graph.
- **`_make_tone(freq, duration, wave)`** — Synthesizes audio from scratch. Returns an `AudioStreamWAV` resource containing raw 16-bit PCM samples.
- **`_play(freq, duration, wave)`** — Assigns the synthesized stream to `SFXPlayer` and plays it.
- **`_on_volume_changed(value)`** — Maps the slider's dB value to the SFX bus gain via `AudioServer.set_bus_volume_db()`.

## PCM Synthesis Theory

### What PCM Is

**Pulse Code Modulation (PCM)** represents audio as a series of amplitude samples taken at regular intervals. Each sample is a number representing the air pressure at that instant. At 22,050 samples per second (`SAMPLE_RATE = 22050`), 0.4 seconds of audio = 8,820 samples.

### 16-bit Little-Endian Format

Each sample is stored as a signed 16-bit integer (range −32768 to +32767). In little-endian format, the low byte comes first:

```gdscript
data[i * 2]     = sample & 0xFF         # low byte
data[i * 2 + 1] = (sample >> 8) & 0xFF  # high byte
```

`AudioStreamWAV.FORMAT_16_BITS` tells Godot to interpret the byte array as 16-bit LE samples.

### Waveform Equations

For sample index `i` and sample rate `SAMPLE_RATE`:
```
t = i / SAMPLE_RATE   # time in seconds

sine:   sin(2π × freq × t)
square: +1.0 if fmod(t × freq, 1.0) < 0.5 else -1.0
sweep:  sin(2π × lerp(freq/2, freq×2, i/total_samples) × t)
```

- **Sine**: Pure single-frequency tone. No overtones.
- **Square**: Alternates between +1 and −1 at the given frequency. Contains all odd harmonics, giving a hollow buzzy sound.
- **Sweep**: The frequency argument to `sin()` changes over time (linear chirp), sweeping from half to double the target frequency.

### Amplitude Envelope

```gdscript
var envelope := 1.0 - pow(float(i) / samples, 0.5)
```

This applies a **decay envelope**: amplitude starts at 1.0 and falls to 0.0 by the end of the buffer. The square root curve (`pow(x, 0.5)`) makes the decay faster at the start and slower at the end, which sounds more natural than a linear ramp. Without an envelope, the abrupt cutoff at the buffer's end causes an audible click.

## Audio Bus Architecture

### Bus Graph

Godot routes audio through a graph of buses. Every `AudioStreamPlayer` sends to a named bus (default `"Master"`). You can add intermediate buses to apply effects or control group volume:

```
SFXPlayer → "SFX" bus → "Master" bus → audio output
```

The SFX bus acts as a mixer channel: adjusting its volume changes all sounds routed through it without touching individual players.

### Decibels

Human hearing is logarithmic. Decibels model this: every +6 dB doubles perceived loudness, −6 dB halves it. `0 dB = full volume`, `−80 dB ≈ silence`. The slider in this demo maps linearly from −40 dB to +6 dB, matching how a real audio mixer behaves.

```gdscript
AudioServer.set_bus_volume_db(bus_idx, db_value)
```

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AudioStreamWAV.new()` | Runtime audio stream resource |
| `AudioStreamWAV.data` | Raw PCM byte array |
| `AudioStreamWAV.FORMAT_16_BITS` | 16-bit signed little-endian samples |
| `AudioStreamWAV.mix_rate` | Samples per second |
| `AudioStreamPlayer.stream` | Assign a stream before calling `play()` |
| `AudioStreamPlayer.bus` | Route to a named bus |
| `AudioServer.add_bus()` | Create a new mixer bus |
| `AudioServer.set_bus_name(idx, name)` | Name the bus |
| `AudioServer.set_bus_send(idx, target)` | Route bus output to another bus |
| `AudioServer.set_bus_volume_db(idx, db)` | Set bus gain in decibels |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [audio-bus-effects](../audio-bus-effects) — Dynamic reverb, echo, and compression routed through an `AudioBus`.
- [settings-menu](../settings-menu) — A settings panel with volume slider, fullscreen toggle, and player color.
- [audio-positional](../audio-positional) — `AudioStreamPlayer2D` spatial attenuation with a synthesized tone.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

