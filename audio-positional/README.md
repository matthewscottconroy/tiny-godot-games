# Audio Positional

Demonstrates `AudioStreamPlayer2D` — positional audio that automatically attenuates based on distance between a sound source and a listener, using synthesized PCM audio.

## Purpose

Most games need audio that gets quieter with distance — footsteps, ambient sound sources, explosions. `AudioStreamPlayer2D` handles this automatically once you understand the `max_distance` and `attenuation` properties. This demo lets you move the listener to hear the falloff in action, and displays the math behind what Godot computes internally.

## Controls

- **Arrow keys / WASD**: Move the listener (ear icon) toward or away from the sound source
- The looping sine tone plays continuously; volume changes as you move

## How It Works

### Node Tree

```
Main (Node2D)                   ← main.gd
├── SoundSource (Node2D)        ← stays fixed at center
│   └── AudioStreamPlayer2D
└── Listener (Node2D)           ← player moves this
```

### `scripts/main.gd`

- **`_ready()`** — Synthesizes a looping 440 Hz sine wave as raw PCM (same technique as the `audio-demo` project). Sets `loop_mode = AudioStreamWAV.LOOP_FORWARD` so playback wraps seamlessly. Configures `AudioStreamPlayer2D.max_distance = 400` and `attenuation = 1.0` before calling `play()`.
- **`_process(delta)`** — Moves `Listener` with arrow input. Since Godot's `AudioStreamPlayer2D` reads the position of its *own node* (not a separate listener node), the demo approximates the attenuation formula manually and displays it as a label.
- **`_draw()`** — Renders the source as a radiating circle, the listener as an ear shape, and concentric distance rings at 25%, 50%, 75%, and 100% of `max_distance`.

### How Positional Audio Works

Godot's `AudioStreamPlayer2D` computes attenuation using the distance from itself to the scene's AudioListener2D (or the default camera position):

```
linear_vol = clamp(1 - distance / max_distance, 0, 1)
volume     = linear_vol ^ attenuation
```

Higher `attenuation` values (e.g. 2.0) cause the sound to drop off faster. `attenuation = 1.0` is linear; `attenuation = 2.0` squares the linear volume (much faster rolloff).

## PCM Synthesis Loop

```gdscript
stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
stream.loop_begin = 0
stream.loop_end   = sample_count
```

`LOOP_FORWARD` makes the stream loop from `loop_end` back to `loop_begin` seamlessly. Without looping, the sound stops after the buffer plays once.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AudioStreamPlayer2D` | Positional audio — volume by distance |
| `AudioStreamPlayer2D.max_distance` | Distance at which volume reaches zero |
| `AudioStreamPlayer2D.attenuation` | Falloff curve exponent |
| `AudioStreamWAV.loop_mode` | `LOOP_FORWARD` for seamless repeat |
| `AudioStreamWAV.loop_begin/end` | Loop region in samples |
