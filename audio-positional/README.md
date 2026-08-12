# Audio Positional

Demonstrates `AudioStreamPlayer2D` — a sound source fixed in world space that automatically attenuates as a movable listener travels away from it, with a synthesized 440 Hz sine tone so no audio file assets are required.

## Purpose

Most games need audio that responds to distance: enemy footsteps grow quieter as you back away, an ambient machine hums nearby and fades at the edge of a room, an explosion sounds different depending on where the player is standing. `AudioStreamPlayer2D` handles this automatically: place it in the scene tree, set `max_distance` and `attenuation`, and Godot computes the volume and stereo panning relative to the scene's audio listener each frame.

This demo makes the invisible math visible. You move an "ear" icon around the screen and watch the distance and volume percentage update in real time, while hearing the actual effect through your speakers. Understanding how `max_distance` and `attenuation` interact lets you tune every sound source in your game rather than accepting defaults.

## How It Works

### Node Tree

```
Main (Node2D)                   ← main.gd
├── SoundSource (Node2D)        ← fixed at center of screen
│   └── AudioStreamPlayer2D    ← the positional audio player
├── Listener (Node2D)           ← moved by arrow key input
└── InfoLabel (Label)           ← live distance / volume readout
```

### PCM Synthesis

No `.wav` or `.ogg` file is needed. `_make_tone()` builds an `AudioStreamWAV` buffer in memory:

```gdscript
func _make_tone(freq: float, duration: float) -> AudioStreamWAV:
    var samples := int(SAMPLE_RATE * duration)
    var data    := PackedByteArray()
    data.resize(samples * 2)       # 2 bytes per 16-bit sample
    for i in samples:
        var t   := float(i) / SAMPLE_RATE
        var raw := int(sin(TAU * freq * t) * 28000)
        raw = clampi(raw, -32768, 32767)
        data[i * 2]     = raw & 0xFF
        data[i * 2 + 1] = (raw >> 8) & 0xFF
    var wav      := AudioStreamWAV.new()
    wav.data      = data
    wav.format    = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate  = SAMPLE_RATE
    return wav
```

`FORMAT_16_BITS` uses little-endian signed 16-bit PCM. `mix_rate = 22050` sets the playback sample rate. The buffer is 2 seconds long and set to loop:

```gdscript
player.stream.loop_mode  = AudioStreamWAV.LOOP_FORWARD
player.stream.loop_begin = 0
player.stream.loop_end   = SAMPLE_RATE * 2   # 44100 samples
```

`LOOP_FORWARD` wraps from `loop_end` back to `loop_begin` seamlessly, creating a continuous tone.

### Attenuation Math

Godot's `AudioStreamPlayer2D` uses the following formula internally (the demo replicates it to display the value):

```gdscript
var dist := listener.position.distance_to(source.position)
var vol  := clampf(1.0 - dist / player.max_distance, 0.0, 1.0)
vol = pow(vol, player.attenuation)
```

`max_distance = 400` px means the sound is completely silent at 400 px and beyond. `attenuation = 1.0` is linear; `attenuation = 2.0` squares the linear volume (faster drop-off near the edge). A value below 1.0 would make the sound stay loud longer before a sharp cutoff — useful for very loud events like explosions.

### Listener vs. AudioListener2D

`AudioStreamPlayer2D` uses the nearest `AudioListener2D` node (or the viewport camera position if none exists) as its listener. This demo moves a visual `Listener` node manually and mirrors the position math manually for the readout — in a real game, attach `AudioListener2D` to the player character and it updates automatically.

## Stereo Panning

In addition to volume, `AudioStreamPlayer2D` pans the sound left or right based on the horizontal offset between source and listener. This is handled entirely by Godot; no additional code is needed. To disable panning on a specific source (for ambient beds that should be full stereo regardless of position), set `AudioStreamPlayer2D.panning_strength = 0`.

## How to Adapt This in Your Project

- **Footstep sounds**: Attach `AudioStreamPlayer2D` to the enemy or NPC node. Play a footstep clip on each step animation event. Volume and panning update automatically as the player moves.
- **Area-based ambient audio**: Place a `AudioStreamPlayer2D` at the center of a room and set `max_distance` to the room radius. The ambient sound fades as the player approaches the door.
- **Multiple simultaneous sources**: Each `AudioStreamPlayer2D` is independent. The audio bus mixes them. For performance with many sources, use an object pool of players and a maximum-concurrent-sounds limit.
- **Bus routing**: Set `AudioStreamPlayer2D.bus = "SFX"` to route through a bus with compressor, reverb, or other effects. Separate buses for music, SFX, and ambient let players control them independently in a settings menu.
- **3D audio**: Use `AudioStreamPlayer3D` with the same `max_distance` and `attenuation` properties for 3D scenes.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AudioStreamPlayer2D` | Positional audio player — volume and panning by distance |
| `AudioStreamPlayer2D.max_distance` | Distance in pixels at which volume reaches zero |
| `AudioStreamPlayer2D.attenuation` | Falloff curve exponent (1.0 = linear) |
| `AudioStreamPlayer2D.panning_strength` | Scale for stereo panning effect |
| `AudioStreamWAV` | In-memory PCM audio stream |
| `AudioStreamWAV.FORMAT_16_BITS` | 16-bit signed little-endian PCM format |
| `AudioStreamWAV.loop_mode` | `LOOP_FORWARD` for seamless repeat |
| `AudioStreamWAV.mix_rate` | Sample rate (22050 or 44100 Hz) |
| `PackedByteArray` | Byte buffer for raw PCM data |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys | Move the listener (ear icon) |
| (automatic) | Volume changes as distance to source changes |

## Key Constants

```gdscript
const SAMPLE_RATE    := 22050     # samples per second
const LISTENER_SPEED := 200.0     # px/s listener movement

# AudioStreamPlayer2D properties set at runtime:
# max_distance = 400 px
# attenuation  = 1.0 (linear falloff)
# Tone: 440 Hz sine wave, 2-second looping buffer
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | PCM synthesis, listener movement, attenuation readout, rendering |
| `scenes/main.tscn` | Scene with SoundSource, AudioStreamPlayer2D, Listener, InfoLabel |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

