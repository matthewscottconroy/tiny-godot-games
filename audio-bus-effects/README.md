# Audio Bus Effects

<!-- tags: audio, ui -->

Dynamic reverb, echo, and compression routed through AudioBus. Press Space to play a tone; use arrow keys to switch buses. Demonstrates the bus architecture none of the other audio demos touch.

## Purpose

Godot's AudioBus system works like a hardware mixing board: every sound source routes to a bus, and each bus can have a chain of DSP effects applied before the signal reaches your speakers. This architecture lets you apply reverb to all dungeon sounds at once by routing them through a "Dungeon" bus, or duck all game audio under dialogue by applying compression to the Master bus.

Real games use bus effects constantly: environmental reverb (cave, hall, outdoors), low-pass filters when underwater or muffled, compression to keep cutscenes from being louder than gameplay, and sidechain ducking to lower music volume when dialogue plays. Understanding buses is what separates game audio that feels immersive from audio that just plays back.

This demo creates four buses entirely at runtime — no project AudioBus configuration needed — and lets you hear the same 440 Hz synthesized tone processed through each effect chain.

## How It Works

### Creating Buses at Runtime

```gdscript
func _setup_buses() -> void:
    if AudioServer.get_bus_index("Reverb") == -1:
        AudioServer.add_bus()
        var idx := AudioServer.bus_count - 1
        AudioServer.set_bus_name(idx, "Reverb")
        AudioServer.set_bus_send(idx, "Master")
        var rev := AudioEffectReverb.new()
        rev.room_size = 0.85
        rev.wet       = 0.65
        rev.dry       = 0.6
        AudioServer.add_bus_effect(idx, rev)
```

`get_bus_index("Reverb") == -1` guards against double-creation if the scene reloads. `set_bus_send(idx, "Master")` routes the bus output to Master (then to speakers). Effects are appended in order — signal flows through them left to right.

### Echo Tap Structure

```gdscript
var delay := AudioEffectDelay.new()
delay.tap1_active    = true
delay.tap1_delay_ms  = 300.0
delay.tap1_level_db  = -6.0
delay.tap2_active    = true
delay.tap2_delay_ms  = 600.0
delay.tap2_level_db  = -12.0
```

Tap 1 at 300 ms and tap 2 at 600 ms create a slapback echo. Each tap is 6 dB quieter than the previous, which matches how real echoes decay. A second tap at exactly 2× the delay reinforces the rhythmic feel.

### Compressor Settings

```gdscript
var comp := AudioEffectCompressor.new()
comp.threshold  = -24.0   # dB — signal above this gets reduced
comp.ratio      = 6.0     # 6:1 — for every 6 dB over threshold, allow 1 dB through
comp.attack_us  = 20.0    # microseconds before compression kicks in
comp.release_ms = 250.0   # milliseconds to stop compressing after signal drops
```

A 6:1 ratio is a firm compressor — louder transients are reduced significantly. The 20 µs attack lets percussive peaks through before clamping down; the 250 ms release prevents audible pumping on sustained notes.

### Switching Buses

```gdscript
_player.bus = BUSES[_current_bus]   # BUSES = ["Dry", "Reverb", "Echo", "Compressed"]
```

`AudioStreamPlayer.bus` takes the bus name as a string. Reassigning it mid-session routes all subsequent playback through the new chain. The change takes effect on the next `play()` call.

### Synthesizing the Tone in Code

```gdscript
func _make_tone(freq: float, duration: float) -> AudioStreamWAV:
    var samples := int(SAMPLE_RATE * duration)
    for i in samples:
        var t   := float(i) / SAMPLE_RATE
        var raw := sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.0 * t) * 0.2
        var env := 1.0 - pow(float(i) / samples, 0.5)
        var s   := clampi(int(raw * 22000.0 * env), -32768, 32767)
```

The tone is a 440 Hz fundamental plus its first harmonic at half amplitude — a slightly richer sound than a pure sine. The envelope `1 - sqrt(t/duration)` decays quickly at first then tapers, giving a pluck-like shape. No audio files needed.

## Audio Bus Architecture

```
AudioStreamPlayer  →  named bus  →  effect chain  →  Master bus  →  speakers
```

The `Master` bus always exists and cannot be removed. Every bus you create must ultimately send to `Master` (directly or via another bus). You can chain buses: a "Reverb" bus could send to a "Master_Game" bus, which sends to `Master`, letting you mute all game audio independently of UI sounds.

## Buses

| Bus | Effect | Key Settings |
|-----|--------|-------------|
| Dry | None | Direct signal |
| Reverb | AudioEffectReverb | room_size 0.85, wet 0.65 |
| Echo | AudioEffectDelay (×2 taps) | 300 ms / -6 dB, 600 ms / -12 dB |
| Compressed | AudioEffectCompressor | threshold -24 dB, ratio 6:1 |

## How to Adapt This in Your Project

- **Environmental zones**: Create "Cave", "Hall", and "Outdoor" buses with different reverb settings. When the player enters a zone, route ambient sounds and footsteps to that bus.
- **Music ducking**: Add a compressor to the music bus with a sidechain input set to the dialogue bus — music automatically ducks under voice lines.
- **Low-pass filter on muffled sounds**: `AudioEffectLowPassFilter` on a "Muffled" bus; route underwater or through-wall sounds there instead of the direct bus.
- **Runtime effect parameter tweaks**: Get a reference with `AudioServer.get_bus_effect(idx, effect_idx)`, cast it, and adjust properties (e.g., `(rev as AudioEffectReverb).wet = 0.9`) in real time.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AudioServer.add_bus()` | Create a new audio bus at runtime |
| `AudioServer.get_bus_index(name)` | Find a bus by name (-1 if not found) |
| `AudioServer.set_bus_name(idx, name)` | Name a bus |
| `AudioServer.set_bus_send(idx, name)` | Route bus output to another bus |
| `AudioServer.add_bus_effect(idx, effect)` | Append effect to bus chain |
| `AudioServer.get_bus_effect(idx, effect_idx)` | Retrieve effect for runtime tweaks |
| `AudioEffectReverb` | Room simulation via dense reflections |
| `AudioEffectDelay` | Echo/delay with up to two independent taps |
| `AudioEffectCompressor` | Dynamic range compression |
| `AudioStreamPlayer.bus` | Route player output to named bus |
| `AudioStreamWAV` | PCM audio stream (constructable in code) |

## Controls

| Input | Action |
|-------|--------|
| Space | Play tone on current bus |
| Left / Right arrows | Switch bus |
| Enter | Also switches bus forward |

## Key Constants

```gdscript
const SAMPLE_RATE := 44100           # Hz — standard CD quality
const BUSES := ["Dry", "Reverb", "Echo", "Compressed"]
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Bus setup, tone synthesis, input handling, label updates |
| `scenes/main.tscn` | Scene tree with AudioStreamPlayer, CanvasLayer, and labels |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [audio-demo](../audio-demo) — Generate SFX in code via raw PCM synthesis, routed through audio buses.
- [audio-positional](../audio-positional) — `AudioStreamPlayer2D` spatial attenuation with a synthesized tone.
- [settings-menu](../settings-menu) — A settings panel with volume slider, fullscreen toggle, and player color.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

